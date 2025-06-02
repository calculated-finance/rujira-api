defmodule RujiraWeb.Resolvers.Thorchain do
  alias Rujira.Assets
  alias Absinthe.Resolution.Helpers
  alias Thorchain.Types.QueryInboundAddressesResponse
  alias Thorchain.Types.QueryInboundAddressesRequest
  alias Thorchain.Types.QueryQuoteSwapResponse
  alias Thorchain.Types.QueryQuoteSwapRequest
  alias Thorchain.Types.Query.Stub, as: Q
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
           Thorchain.Node.stub(&Q.quote_swap/2, req),
         {:ok, expiry} <- DateTime.from_unix(res.expiry) do
      {:ok,
       %{res | expiry: expiry}
       |> Map.put(:request, req)
       |> Map.put(:asset_in, %{asset: Assets.from_string(from_asset), amount: amount})
       |> Map.put(:expected_asset_out, %{
         asset: Assets.from_string(to_asset),
         amount: res.expected_amount_out
       })
       |> Map.update!(:fees, &%{&1 | asset: Assets.from_string(&1.asset)})}
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

  def inbound_addresses() do
    with {:ok, %QueryInboundAddressesResponse{inbound_addresses: inbound_addresses}} <-
           Thorchain.Node.stub(&Q.inbound_addresses/2, %QueryInboundAddressesRequest{}) do
      {:ok, Enum.map(inbound_addresses, &cast_response/1)}
    end
  end

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
      pools
      |> Task.async_stream(fn pool ->
        Thorchain.liquidity_provider(pool.asset.id, address)
      end)
      |> Rujira.Enum.reduce_while_ok([], &elem(&1, 1))
    end
  end

  defp cast_response(x) do
    x
    |> Map.update(:chain, nil, &String.to_existing_atom(String.downcase(&1)))
    |> Map.update(:gas_rate_units, nil, fn
      "" -> nil
      x -> x
    end)
    |> Map.update(:pub_key, nil, fn
      "" -> nil
      x -> x
    end)
    |> Map.update(:router, nil, fn
      "" -> nil
      x -> x
    end)
    |> Map.put(:id, x.chain)
  end

  def summary(_, _, _) do
    with {:ok, total_bonds} <- Thorchain.total_bonds(),
         {:ok, tvl} <- Thorchain.tvl(),
         {:ok, chains} <- Thorchain.chains(),
         {:ok, swaps_data} <- Thorchain.swaps_data() do
      {:ok,
       %{
         unique_swappers: 1000,
         total_validator_bond: total_bonds,
         tvl: tvl + total_bonds,
         pools_liquidity: tvl,
         total_pool_earnings: 200_000,
         total_transactions: 15000,
         total_swaps: swaps_data.total_swaps,
         daily_swap_volume: swaps_data.daily_swap_volume,
         total_swap_volume: swaps_data.total_swap_volume,
         affiliate_volume: swaps_data.affiliate_volume,
         affiliate_transactions: swaps_data.affiliate_transactions,
         running_since: 2018,
         blockchain_integrated: length(chains) - 1
       }}
    end
  end

  def tx_in(_, %{hash: hash}, _) do
    Helpers.async(fn ->
      Thorchain.tx_in(hash)
    end)
  end

  def tcy(%{address: address, asset: %{id: asset}}, _, _) do
    with {:ok, claimable} <- Thorchain.Tcy.claim(asset, address) do
      {:ok, %{claimable: claimable}}
    else
      _ -> {:ok, nil}
    end
  end

  def oracle(id) do
    Helpers.async(fn ->
      Thorchain.oracle_from_id(id)
    end)
  end
end
