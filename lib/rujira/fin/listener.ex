defmodule Rujira.Fin.Listener do
  @moduledoc """
  Listens for and processes Fin Protocol-related blockchain events.

  Handles block transactions to detect Fin Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """
  alias Rujira.Bow
  alias Rujira.Fin
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs, end_block_events: end_block_events}, state) do
    scan_txs(txs)

    end_block_events
    |> Enum.map(&scan_end_block_event/1)
    |> Enum.filter(&is_binary/1)
    |> Rujira.Enum.uniq()
    |> broadcast_swaps()

    {:noreply, state}
  end

  defp scan_txs(txs) do
    events =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)

    action_name = String.trim_leading("#{__MODULE__}#scan_txs", "Elixir.")

    span =
      "fin_listener"
      |> Appsignal.Tracer.create_span()

    Appsignal.Span.set_name(span, action_name)

    addresses =
      events
      |> Enum.map(&scan_fin_event/1)
      |> Enum.reject(&is_nil/1)
      |> Rujira.Enum.uniq()
      # Trades are withdrawn before retraction. Ensure we're not re-publishing an order that doens't exist
      |> Enum.reverse()

    bow_addresses =
      events |> Enum.map(&scan_bow_event/1) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()

    for address <- addresses |> Enum.map(&elem(&1, 1)) |> Rujira.Enum.uniq() do
      Appsignal.instrument("fin.invalidate_publish", fn ->
        Logger.info("#{__MODULE__} change #{address}")

        Appsignal.instrument("fin.memoize.invalidate", fn ->
          Memoize.invalidate(Fin, :query_book, [address, :_])
        end)

        Appsignal.instrument("fin.publish", fn ->
          Rujira.Events.publish_node(:fin_book, address)
        end)

        Logger.info("#{__MODULE__} change complete #{address}")
      end)
    end

    for address <- bow_addresses do
      with {:ok, %{address: pair}} <- Bow.fin_pair(address) do
        Appsignal.instrument("bow.invalidate_publish", fn ->
          Logger.info("#{__MODULE__} bow change #{address}")

          Appsignal.instrument("bow.memoize.invalidate", fn ->
            Memoize.invalidate(Fin, :query_book, [pair, :_])
          end)

          Appsignal.instrument("bow.publish", fn ->
            Rujira.Events.publish_node(:fin_book, pair)
          end)

          Logger.info("#{__MODULE__} bow change complete #{address}")
        end)
      end
    end

    for {name, contract, owner, side, price} <- addresses do
      id = Enum.join([name, contract, owner, side, price], "/")

      Appsignal.instrument("order.invalidate_publish", fn ->
        Logger.info("#{__MODULE__} order change #{id}")

        Appsignal.instrument("memo.invalidate.orders", fn ->
          Memoize.invalidate(Fin, :query_orders, [contract, owner, :_, :_])
        end)

        Appsignal.instrument("memo.invalidate.order", fn ->
          Memoize.invalidate(Fin, :query_order, [contract, owner, side, price])
        end)

        Appsignal.instrument("order.publish", fn ->
          publish_order(name, contract, owner, side, price)
        end)

        Logger.info("#{__MODULE__} change complete #{id}")
      end)
    end

    Appsignal.Tracer.current_span()
    |> Appsignal.Tracer.close_span(end_time: :os.system_time())
  end

  defp publish_order(name, contract, owner, side, price) do
    case name do
      "trade" ->
        Rujira.Events.publish(%{side: side, price: price},
          fin_order_filled: "#{contract}/#{side}/#{price}"
        )

      _ ->
        Rujira.Events.publish(
          %{side: side, price: price, contract: contract},
          fin_order_updated: owner
        )
    end
  end

  def scan_fin_event(%{
        attributes:
          %{
            "_contract_address" => contract_address,
            "side" => side,
            "price" => price
          } = attributes,
        type: "wasm-rujira-fin/" <> name
      }) do
    # Where we can't know the owner (eg on trade events), we have to invalidate all
    owner = Map.get(attributes, "owner", :_)
    {name, contract_address, owner, side, price}
  end

  def scan_fin_event(_), do: nil

  def scan_end_block_event(%{attributes: %{"pool" => pool}, type: "swap"}), do: pool
  def scan_end_block_event(_), do: nil

  def scan_bow_event(%{
        attributes: %{"_contract_address" => contract_address},
        type: "wasm-rujira-bow/" <> _
      }) do
    contract_address
  end

  def scan_bow_event(_), do: nil

  defp broadcast_swaps(pools) when is_list(pools), do: Enum.each(pools, &broadcast_swap/1)

  defp broadcast_swap(pool) do
    Memoize.invalidate(Thorchain, :oracle_price, ["THOR.RUNE"])
    Memoize.invalidate(Thorchain, :oracle_price, [pool])
    Rujira.Events.publish_node(:thorchain_oracle, "THOR.RUNE")
    Rujira.Events.publish_node(:thorchain_oracle, pool)

    with {:ok, pools} <- Rujira.Fin.list_pairs() do
      pools
      |> Enum.filter(&(&1.oracle_base == pool or &1.oracle_quote == pool))
      |> Enum.each(fn %{address: address} ->
        Rujira.Events.publish_node(:fin_book, address)
      end)
    end
  end
end
