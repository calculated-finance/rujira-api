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
      Logger.info("#{__MODULE__} change #{address}")
      count = Memoize.invalidate(Fin, :query_book, [address, :_])
      Logger.info("#{__MODULE__} invalidate #{address} count #{count}")
      Rujira.Events.publish_node(:fin_book, address)
      Logger.info("#{__MODULE__} publish #{address}")
    end

    for address <- bow_addresses do
      with {:ok, %{address: pair}} <- Bow.fin_pair(address) do
        Logger.debug("#{__MODULE__} bow change #{address}")
        Memoize.invalidate(Fin, :query_book, [pair, :_])
        Rujira.Events.publish_node(:fin_book, pair)
        Logger.debug("#{__MODULE__} bow change complete #{address}")
      end
    end

    for {name, contract, owner, side, price} <- addresses do
      id = Enum.join([name, contract, owner, side, price], "/")
      Logger.debug("#{__MODULE__} order change #{id} ")

      Memoize.invalidate(Fin, :query_orders, [contract, owner, :_, :_])
      Memoize.invalidate(Fin, :query_order, [contract, owner, side, price])

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

      Logger.debug("#{__MODULE__} change complete #{id}")
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
