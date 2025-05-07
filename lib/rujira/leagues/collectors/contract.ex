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
    {:ok, time, 0} = DateTime.from_iso8601(time)

    for %{"hash" => txhash, "result" => %{"events" => events}} <- txs do
      events
      |> scan_events()
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.map(fn {event, idx} ->
        Map.merge(event, %{height: height, idx: idx, txhash: txhash, timestamp: time})
      end)
      |> Leagues.insert_tx_events()
      |> Leagues.update_leagues()
    end

    {:noreply, state}
  end

  defp scan_events(events), do: scan_events(events, nil, nil, [])

  defp scan_events(
         [
           %{
             "action" => "/cosmwasm.wasm.v1.MsgExecuteContract",
             "module" => "wasm",
             "sender" => sender
           }
           | rest
         ],
         prev_sender,
         prev_contract,
         acc
       )
       when is_nil(prev_sender) and is_nil(prev_contract),
       do: scan_events(rest, sender, nil, acc)

  defp scan_events(
         [%{"_contract_address" => contract} | rest],
         sender,
         prev_contract,
         acc
       )
       when not is_nil(sender) and is_nil(prev_contract),
       do: scan_events(rest, sender, contract, acc)

  defp scan_events(
         [%{"type" => "transfer", "recipient" => recipient, "amount" => amount} | rest],
         sender,
         contract,
         acc
       )
       when not is_nil(sender) and not is_nil(contract) and recipient in @fee_addresses do
    with {:ok, %Contract{module: module}} <- Contracts.by_id(contract) do
      scan_events(rest, nil, nil, league_event(sender, amount, module, acc))
    else
      _ -> scan_events(rest, sender, contract, acc)
    end
  end

  defp scan_events([_ | rest], sender, contract, acc),
    do: scan_events(rest, sender, contract, acc)

  defp scan_events([], _sender, _contract, acc), do: acc

  defp league_event(sender, amount_str, module, acc) do
    with [amt, asset] <- String.split(amount_str, ~r/(?<=\d)(?=[A-Za-z])/),
         {amount, _} <- Integer.parse(amt),
         {:ok, %{price: price}} <- Prices.get(asset),
         {:ok, category} <- module_category(module) do
      revenue = Prices.normalize(amount * price, 20)
      [%{address: sender, revenue: revenue, category: category} | acc]
    end
  end

  def module_category(Rujira.Fin.Pair), do: {:ok, :trade}
  def module_category(_), do: {:error, :unsupported_module}
end
