defmodule RujiraWeb.Resolvers.Thorchain do
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.QueryBlockRequest
  alias Thorchain.Types.QueryBlockResponse
  alias Rujira.Assets.Asset
  alias Thorchain.Common.Coin
  alias Thorchain.Common.Tx
  alias Thorchain.Types.QueryTxResponse
  alias Thorchain.Types.QueryTxRequest
  alias Thorchain.Types.QueryObservedTx
  alias Rujira.Assets
  alias Absinthe.Resolution.Helpers
  alias Thorchain.Types.QueryInboundAddressesResponse
  alias Thorchain.Types.QueryInboundAddressesRequest
  alias Thorchain.Types.QueryPoolsResponse
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.QueryPoolResponse
  alias Thorchain.Types.QueryPoolRequest
  alias Thorchain.Types.QueryQuoteSwapResponse
  alias Thorchain.Types.QueryQuoteSwapRequest
  alias Thorchain.Types.Query.Stub, as: Q

  def quote(_prev, %{from_asset: from_asset, to_asset: to_asset, amount: amount} = x, _res) do
    streaming_interval = Map.get(x, :streaming_interval, nil)
    streaming_quantity = Map.get(x, :streaming_quantity, nil)
    destination = Map.get(x, :destination, nil)
    tolerance_bps = Map.get(x, :tolerance_bps, nil)
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
      tolerance_bps: RujiraWeb.Grpc.to_string(tolerance_bps),
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
       |> Map.put(:asset_in, %{asset: from_asset, amount: amount})
       |> Map.put(:expected_asset_out, %{
         asset: Assets.from_string(to_asset),
         amount: res.expected_amount_out
       })}
    end
  end

  def pools(_, _, _) do
    Helpers.async(fn ->
      req = %QueryPoolsRequest{}

      with {:ok, %QueryPoolsResponse{pools: pools}} <-
             Thorchain.Node.stub(&Q.pools/2, req) do
        {:ok, Enum.map(pools, &cast_pool/1)}
      end
    end)
  end

  def pool(_, %{asset: asset}, _) do
    Helpers.async(fn ->
      req = %QueryPoolRequest{asset: asset}

      with {:ok, %QueryPoolResponse{} = pool} <-
             Thorchain.Node.stub(&Q.pool/2, req) do
        {:ok, cast_pool(pool)}
      end
    end)
  end

  defp cast_pool(pool) do
    pool
    |> Map.put(:asset, Assets.from_string(pool.asset))
    |> Map.put(:lp_units, Map.get(pool, :LP_units))
    |> Map.update(:derived_depth_bps, "0", &String.to_integer/1)
    |> Map.update(:savers_fill_bps, "0", &String.to_integer/1)
  end

  def inbound_addresses(_, _, _) do
    Helpers.async(fn ->
      with {:ok, %QueryInboundAddressesResponse{inbound_addresses: inbound_addresses}} <-
             Thorchain.Node.stub(&Q.inbound_addresses/2, %QueryInboundAddressesRequest{}) do
        {:ok, Enum.map(inbound_addresses, &cast_response/1)}
      end
    end)
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
      with {:ok, %QueryTxResponse{observed_tx: observed_tx} = res} <-
             Thorchain.Node.stub(&Q.tx/2, %QueryTxRequest{tx_id: hash}) do
        {:ok, %{res | observed_tx: cast_tx(observed_tx.tx)}}
      end
    end)
  end

  def block(height) do
    Helpers.async(fn ->
      with {:ok, %QueryBlockResponse{} = block} <-
             Thorchain.Node.stub(&Q.block/2, %QueryBlockRequest{height: to_string(height)}) do
        {:ok,
         %{
           block
           | header: cast_block_header(block.header),
             begin_block_events: Enum.map(block.begin_block_events, &cast_block_event/1),
             end_block_events: Enum.map(block.end_block_events, &cast_block_event/1)
         }}
      end
    end)
  end

  defp cast_block_header(%BlockResponseHeader{chain_id: chain_id, height: height, time: time}) do
    {:ok, time, 0} = DateTime.from_iso8601(time)
    %{chain_id: chain_id, height: height, time: time}
  end

  defp cast_block_event(%BlockEvent{event_kv_pair: event_kv_pair}) do
    %{attributes: event_kv_pair}
  end

  defp cast_tx(%Tx{
         id: id,
         chain: chain,
         from_address: from_address,
         to_address: to_address,
         coins: coins,
         gas: gas,
         memo: memo
       }) do
    %{
      id: id,
      chain: String.to_existing_atom(String.downcase(chain)),
      from_address: from_address,
      to_address: to_address,
      coins: Enum.map(coins, &cast_coin/1),
      gas: Enum.map(gas, &cast_coin/1),
      memo: memo
    }
  end

  defp cast_coin(%Coin{asset: asset, amount: amount}) do
    %{
      asset: %Asset{
        id: "#{asset.chain}.#{asset.symbol}",
        type: :layer_1,
        chain: asset.chain,
        symbol: asset.symbol,
        ticker: asset.ticker
      },
      amount: amount
    }
  end
end
