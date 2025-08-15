defmodule RujiraWeb.Resolvers.Thorchain do
  @moduledoc """
  Handles GraphQL resolution for Thorchain-related queries and operations.
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryInboundAddressesRequest
  alias Thorchain.Types.QueryInboundAddressesResponse
  alias Thorchain.Types.QueryOutboundFeesRequest
  alias Thorchain.Types.QueryOutboundFeesResponse
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
       |> Map.update!(:fees, &%{&1 | asset: Assets.from_string(&1.asset)})
       |> Map.update(:dust_threshold, nil, &String.to_integer/1)
       |> Map.update!(:recommended_min_amount_in, &String.to_integer/1)
       |> Map.update!(:recommended_gas_rate, &String.to_integer/1)
       |> Map.update!(:expected_amount_out, &String.to_integer/1)
       |> Map.update!(:max_streaming_quantity, &String.to_integer/1)}
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
      inbound_addresses()
    end)
  end

  def inbound_addresses do
    with {:ok, %QueryInboundAddressesResponse{inbound_addresses: inbound_addresses}} <-
           Thornode.query(&Q.inbound_addresses/2, %QueryInboundAddressesRequest{}) do
      {:ok, Enum.map(inbound_addresses, &cast_inbound_address/1)}
    end
  end

  defp cast_inbound_address(x) do
    x
    |> Map.update(:chain, nil, &String.to_existing_atom(String.downcase(&1)))
    |> Map.update(:gas_rate_units, nil, &maybe_string/1)
    |> Map.update(:pub_key, nil, &maybe_string/1)
    |> Map.update(:router, nil, &maybe_string/1)
    |> Map.update(:outbound_tx_size, "0", &String.to_integer/1)
    |> Map.update(:outbound_fee, "0", &String.to_integer/1)
    |> Map.update(:dust_threshold, "0", &String.to_integer/1)
    |> Map.update(:gas_rate, "0", &String.to_integer/1)
    |> Map.put(:id, x.chain)
  end

  def outbound_fees(_, _, _) do
    with {:ok, %QueryOutboundFeesResponse{outbound_fees: outbound_fees}} <-
           Thornode.query(&Q.outbound_fees/2, %QueryOutboundFeesRequest{}) do
      {:ok, Enum.map(outbound_fees, &cast_outbound_fee/1)}
    end
  end

  defp cast_outbound_fee(x) do
    x
    |> Map.update(:outbound_fee, "0", &String.to_integer/1)
    |> Map.update(:fee_withheld_rune, nil, &maybe_to_integer/1)
    |> Map.update(:fee_spent_rune, nil, &maybe_to_integer/1)
    |> Map.update(:surplus_rune, nil, &maybe_to_integer/1)
    |> Map.update(:dynamic_multiplier_basis_points, nil, &maybe_to_integer/1)
  end

  defp maybe_to_integer(""), do: nil
  defp maybe_to_integer(str), do: String.to_integer(str)
  defp maybe_string(""), do: nil
  defp maybe_string(str), do: str

  def inbound_address(id) do
    with {:ok, adds} <- inbound_addresses() do
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
