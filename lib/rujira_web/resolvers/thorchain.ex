defmodule RujiraWeb.Resolvers.Thorchain do
  @moduledoc """
  Handles GraphQL resolution for Thorchain-related queries and operations.
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryQuoteSwapRequest
  alias Thorchain.Types.QueryQuoteSwapResponse

  use Memoize

  def quote(_prev, %{from_asset: from_asset, to_asset: to_asset, amount: amount} = x, _res) do
    streaming_interval = Map.get(x, :streaming_interval, nil)
    streaming_quantity = Map.get(x, :streaming_quantity, nil)
    destination = Map.get(x, :destination, nil)
    liquidity_tolerance_bps = Map.get(x, :liquidity_tolerance_bps, nil)
    refund_address = Map.get(x, :refund_address, nil)
    affiliate = Map.get(x, :affiliate, nil)
    affiliate_bps = Map.get(x, :affiliate_bps, [])
    height = Map.get(x, :height, nil)

    req = %QueryQuoteSwapRequest{
      from_asset: from_asset,
      to_asset: to_asset,
      amount: RujiraWeb.Grpc.to_string(amount),
      streaming_interval: RujiraWeb.Grpc.to_string(streaming_interval),
      streaming_quantity: RujiraWeb.Grpc.to_string(streaming_quantity),
      destination: destination,
      liquidity_tolerance_bps: RujiraWeb.Grpc.to_string(liquidity_tolerance_bps),
      refund_address: refund_address,
      affiliate: affiliate,
      affiliate_bps: Enum.map(affiliate_bps, &RujiraWeb.Grpc.to_string/1),
      height: height
    }

    with {:ok, %QueryQuoteSwapResponse{} = res} <-
           Thornode.query(&Q.quote_swap/2, req),
         {:ok, expiry} <- DateTime.from_unix(res.expiry) do
      {:ok,
       %{res | expiry: expiry}
       |> Map.put(:request, req)
       |> Map.put(:asset_in, %{asset: Assets.from_string(from_asset), amount: amount})
       |> Map.put(:expected_asset_out, %{
         asset: Assets.from_string(to_asset),
         amount: res.expected_amount_out
       })
       |> Map.update!(
         :fees,
         &%{
           &1
           | asset: Assets.from_string(&1.asset),
             outbound: String.to_integer(&1.outbound),
             liquidity: String.to_integer(&1.liquidity),
             total: String.to_integer(&1.total)
         }
       )
       |> Map.update(:dust_threshold, nil, fn
         "" -> nil
         x -> String.to_integer(x)
       end)
       |> Map.update!(:recommended_min_amount_in, &String.to_integer/1)
       |> Map.update!(:recommended_gas_rate, fn
         # TODO: Update schema to make this nullable
         "" -> 0
         x -> String.to_integer(x)
       end)
       |> Map.update!(:expected_amount_out, &String.to_integer/1)}
    end
  end

  def pools(_, _, _) do
    Helpers.async(fn ->
      Thorchain.pools()
    end)
  end

  def pool(_, %{asset: asset}, _) do
    Thorchain.pool_from_id(asset)
  end

  def inbound_addresses(_, _, _) do
    Helpers.async(fn ->
      Thorchain.inbound_addresses()
    end)
  end

  def outbound_fees(_, _, _) do
    Helpers.async(fn ->
      Thorchain.outbound_fees()
    end)
  end

  def inbound_address(id) do
    with {:ok, adds} <- Thorchain.inbound_addresses() do
      case Enum.find(adds, &(&1.id == id)) do
        nil -> {:error, :not_found}
        add -> {:ok, add}
      end
    end
  end

  def liquidity_accounts(%{address: address}, _, _) do
    with {:ok, pools} <- Thorchain.pools() do
      Rujira.Enum.reduce_async_while_ok(
        pools,
        &Thorchain.liquidity_provider(&1.asset.id, address)
      )
    end
  end

  def tx_in(_, %{hash: hash}, _) do
    Helpers.async(fn ->
      Thorchain.tx_in(hash)
    end)
  end

  def tcy(%{address: address, asset: %{id: asset}}, _, _) do
    case Thorchain.Tcy.claim(asset, address) do
      {:ok, claimable} -> {:ok, %{claimable: claimable}}
      _ -> {:ok, nil}
    end
  end

  def tcy(_, _, _), do: {:ok, nil}

  def oracle(nil), do: {:ok, nil}

  def oracle(id) do
    Helpers.async(fn ->
      Thorchain.oracle_from_id(id)
    end)
  end

  def tor_candles(%{id: asset}, %{after: from, resolution: resolution, before: to}, _) do
    Helpers.async(fn ->
      {:ok,
       Thorchain.Tor.range_candles(asset, from, to, resolution)
       |> Enum.reverse()
       |> insert_candle_nodes()}
    end)
  end

  defp insert_candle_nodes(
         candles,
         agg \\ %{
           page_info: %{
             start_cursor: <<>>,
             end_cursor: <<>>,
             has_previous_page: false,
             has_next_page: false
           },
           edges: []
         }
       )

  defp insert_candle_nodes([c], %{page_info: page_info} = agg) do
    insert_candle_nodes([], %{
      agg
      | edges: [%{cursor: c.bin, node: c} | agg.edges],
        page_info: %{page_info | start_cursor: c.bin}
    })
  end

  defp insert_candle_nodes([c | rest], %{page_info: page_info} = agg) do
    insert_candle_nodes(rest, %{
      agg
      | edges: [%{cursor: c.bin, node: c} | agg.edges],
        page_info: %{page_info | start_cursor: c.bin, end_cursor: c.bin}
    })
  end

  defp insert_candle_nodes([], agg), do: agg
end
