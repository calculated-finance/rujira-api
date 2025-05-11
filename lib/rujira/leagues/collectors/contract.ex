defmodule Rujira.Leagues.Collectors.Contract do
  use GenServer
  require Logger

  alias Rujira.Prices
  alias Rujira.Leagues
  alias Rujira.Contracts
  alias Rujira.Contracts.Contract

  @fee_addresses Application.compile_env(:rujira, __MODULE__,
                   fee_addresses: ["sthor1qm7vtdca95aj7nvtrarqm3uah33nhffpnhhg3j"]
                 )
                 |> Keyword.get(:fee_addresses)
  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, state}
  end

  @impl true
  def handle_info(%{header: %{height: height, time: time}, txs: txs}, state) do
    for %{hash: txhash, result: %{events: events}} <- txs do
      events
      |> scan_events()
      |> Enum.with_index()
      |> Enum.map(fn {event, idx} ->
        Map.merge(event, %{
          height: height,
          idx: idx,
          txhash: txhash,
          timestamp: time
        })
      end)
      |> Leagues.insert_tx_events()
      |> Leagues.update_leagues()
    end

    {:noreply, state}
  end

  defp scan_events(events) do
    Enum.reduce(events, %{sender: nil, contract: nil, acc: []}, fn %{type: type, attributes: attrs}, ctx ->
      attr_map = Map.new(attrs, fn %{key: k, value: v} -> {k, v} end)

      case type do
        "message" ->
          case attr_map do
            %{"action" => "/cosmwasm.wasm.v1.MsgExecuteContract", "sender" => sender} ->
              %{ctx | sender: sender}

            _ -> ctx
          end

        "execute" ->
          case attr_map do
            %{"_contract_address" => contract} -> %{ctx | contract: contract}
            _ -> ctx
          end

        "transfer" ->
          league_event(attr_map, ctx)

        _ -> ctx
      end
    end).acc
  end

  defp league_event(%{"recipient" => recipient, "amount" => amount}, %{sender: sender, contract: contract, acc: acc})
       when not is_nil(sender) and not is_nil(contract) and recipient in @fee_addresses do
    with {:ok, %Contract{module: module}} <- Contracts.by_id(contract),
         {:ok, %{price: price}} <- Prices.get(asset(amount)),
         {:ok, category} <- module_category(module),
         {amt, _} <- Integer.parse(numeric(amount)) do
      revenue =
        amt
        |> Decimal.mult(price)
        |> Decimal.round()
        |> Decimal.to_integer()

      %{sender: nil, contract: nil, acc: [%{address: sender, revenue: revenue, category: category} | acc]}
    else
      _ -> %{sender: sender, contract: contract, acc: acc}
    end
  end

  defp league_event(_, ctx), do: ctx

  defp asset(amount), do: String.replace(amount, ~r/^\d+/, "")
  defp numeric(amount), do: String.replace(amount, ~r/\D+$/, "")

  defp module_category(Rujira.Fin.Pair), do: {:ok, :trade}
  defp module_category(_), do: {:error, :unsupported_module}
end
