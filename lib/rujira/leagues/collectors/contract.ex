defmodule Rujira.Leagues.Collectors.Contract do
  defmodule Ctx do
    defstruct [:sender, :contract]
  end

  use GenServer
  require Logger
  use Memoize

  alias Rujira.Assets
  alias Rujira.Deployments.Target
  alias Rujira.Revenue
  alias Rujira.Deployments
  alias Rujira.Prices
  alias Rujira.Leagues

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
      |> collect_events()
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

  # We want to find the first MsgExecuteContract (as a user action) to collect the sender,
  # Then extend the context with the _contract_address from the wasm execute event
  # Then finally allocate all subsequent revenue transfer events to this user + contract,
  # When further execute events are found, the contract attribution is updated

  defp collect_events(events, collection \\ [], ctx \\ %Ctx{})
  defp collect_events([], collection, _), do: collection

  # We'll get a fresh message event if there's more than one msg in the tx
  defp collect_events(
         [
           %{
             type: "message",
             attributes: [
               %{key: "action", value: "/cosmwasm.wasm.v1.MsgExecuteContract"},
               %{key: "sender", value: sender} | _
             ]
           }
           | rest
         ],
         collection,
         ctx
       ) do
    collect_events(rest, collection, %{ctx | sender: sender})
  end

  defp collect_events(
         [
           %{
             type: "execute",
             attributes: [%{key: "_contract_address", value: contract} | _]
           }
           | rest
         ],
         collection,
         ctx
       ) do
    collect_events(rest, collection, %{ctx | contract: contract})
  end

  defp collect_events(
         [
           %{
             type: "transfer",
             attributes: [
               %{key: "amount", value: amount},
               %{key: "recipient", value: recipient},
               %{key: "sender", value: _}
               | _
             ]
           }
           | rest
         ],
         collection,
         ctx
       ) do
    if Enum.member?(fee_addresses(), recipient) do
      collection =
        amount
        |> to_league_events(ctx)
        |> Enum.concat(collection)

      collect_events(rest, collection, ctx)
    else
      collect_events(rest, collection, ctx)
    end
  end

  defp collect_events([_ | rest], collection, ctx), do: collect_events(rest, collection, ctx)

  # Someone's just sent funds without a contract execution
  defp to_league_events(_, %{contract: nil}), do: []

  defp to_league_events(amount, %{contract: contract, sender: sender}) do
    with {:ok, coins} <- Assets.parse_coins(amount) do
      Enum.map(coins, &to_league_event(&1, sender, contract))
    else
      _ -> []
    end
  end

  defp to_league_event({denom, amount}, sender, contract) do
    with {:ok, asset} <- Assets.from_denom(denom),
         %Target{module: module} <-
           Enum.find(Deployments.list_all_targets(), &(&1.address == contract)),
         {:ok, category} <- module_category(module),
         {:ok, %{price: price}} <- Prices.get(asset.ticker) do
      %{
        address: sender,
        revenue:
          amount
          |> Decimal.new()
          |> Decimal.mult(price)
          |> Decimal.mult(Decimal.new(69))
          |> Decimal.round()
          |> Decimal.to_integer(),
        category: category
      }
    end
  end

  defmemop fee_addresses() do
    [
      Deployments.get_target(Revenue.Converter, "single").address,
      Deployments.get_target(Revenue.Converter, "split").address
    ]
  end

  defp module_category(Rujira.Fin.Pair), do: {:ok, :trade}
  defp module_category(Rujira.Bow), do: {:ok, :trade}
  defp module_category(_), do: {:error, :unsupported_module}
end
