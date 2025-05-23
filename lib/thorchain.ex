defmodule Thorchain do
  # alias Thorchain.Types.QueryNodesResponse
  # alias Thorchain.Types.QueryNodesRequest
  alias Thorchain.Types.QueryLiquidityProviderRequest
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Thorchain.Common.Coin
  alias Thorchain.Common.Tx
  alias Thorchain.Swaps
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.BlockTxResult
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryAsgardVaultsRequest
  alias Thorchain.Types.QueryAsgardVaultsResponse
  alias Thorchain.Types.QueryBlockRequest
  alias Thorchain.Types.QueryBlockResponse
  alias Thorchain.Types.QueryBlockTx
  alias Thorchain.Types.QueryNetworkRequest
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.QueryPoolsResponse
  alias Thorchain.Types.QueryTxRequest
  alias Thorchain.Types.QueryTxResponse
  alias Thorchain.Types.QueryPoolRequest
  alias Thorchain.Oracle

  use GenServer
  use Memoize

  def start_link(_) do
    children = [__MODULE__.Listener, __MODULE__.Node, __MODULE__.Swaps]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def network() do
    req = %QueryNetworkRequest{}

    with {:ok, res} <- Thorchain.Node.stub(&Q.network/2, req) do
      {:ok, res}
    end
  end

  def pool_from_id(id) do
    req = %QueryPoolRequest{asset: id}

    with {:ok, res} <-
           Thorchain.Node.stub(&Q.pool/2, req) do
      {:ok, cast_pool(res)}
    end
  end

  def pools() do
    req = %QueryPoolsRequest{}

    with {:ok, %QueryPoolsResponse{pools: pools}} <-
           Thorchain.Node.stub(&Q.pools/2, req) do
      {:ok, Enum.map(pools, &cast_pool/1)}
    end
  end

  def liquidity_provider_from_id(id) do
    case String.split(id, "/") do
      [asset, address] -> liquidity_provider(asset, address)
      _ -> {:error, :invalid_id}
    end
  end

  defmemo liquidity_provider(asset, address) do
    req = %QueryLiquidityProviderRequest{asset: asset, address: address}

    with {:ok, res} <-
           Thorchain.Node.stub(&Q.liquidity_provider/2, req) do
      {:ok, cast_liquidity_provider(res)}
    end
  end

  def cast_liquidity_provider(provider) do
    provider
    |> Map.put(:id, "#{provider.asset}/#{provider.rune_address}")
    |> Map.put(:asset, Assets.from_string(provider.asset))
    |> Map.update(:asset_address, nil, fn
      "" -> nil
      x -> x
    end)
    |> Map.update(:rune_address, nil, fn
      "" -> nil
      x -> x
    end)
    |> Map.update(:last_withdraw_height, nil, fn
      0 -> nil
      x -> x
    end)
    |> Map.update(:units, "0", &String.to_integer/1)
    |> Map.update(:pending_rune, "0", &String.to_integer/1)
    |> Map.update(:pending_asset, "0", &String.to_integer/1)
  end

  def cast_pool(pool) do
    pool
    |> Map.put(:id, pool.asset)
    |> Map.put(:asset, Assets.from_string(pool.asset))
    |> Map.put(:lp_units, Map.get(pool, :LP_units))
    |> Map.update(:derived_depth_bps, "0", &String.to_integer/1)
    |> Map.update(:savers_fill_bps, "0", &String.to_integer/1)
  end

  def total_bonds() do
    # req = %QueryNodesRequest{}
    api = Application.get_env(:rujira, Thorchain.Node)[:api]

    client =
      Tesla.client([
        {Tesla.Middleware.BaseUrl, api},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]}
      ])

    with {:ok, %{rune_price_in_tor: price}} <- network(),
         # {:ok, %QueryNodesResponse{nodes: nodes}} <- Thorchain.Node.stub(&Q.nodes/2, req) do
         {:ok, response} <- Tesla.get(client, "/thorchain/nodes") do
      total_bonds =
        response.body
        |> Enum.reduce(0, fn node, acc ->
          bond = String.to_integer(Map.get(node, "total_bond", "0"))
          acc + bond
        end)

      {:ok, Rujira.Prices.normalize(total_bonds * String.to_integer(price), 16)}
    end
  end

  def tvl() do
    with {:ok, pools} <- pools() do
      tvl =
        pools
        |> Enum.reduce(0, fn pool, acc ->
          balance_asset = String.to_integer(Map.get(pool, :balance_asset))
          asset_tor_price = String.to_integer(Map.get(pool, :asset_tor_price))
          tvl = balance_asset * asset_tor_price * 2
          acc + tvl
        end)

      {:ok, Rujira.Prices.normalize(tvl, 16)}
    end
  end

  def chains() do
    req = %QueryAsgardVaultsRequest{}

    with {:ok, %QueryAsgardVaultsResponse{asgard_vaults: vaults}} <-
           Thorchain.Node.stub(&Q.asgard_vaults/2, req) do
      [vault | _] = vaults
      {:ok, vault.chains}
    end
  end

  def swaps_data() do
    with total_swap_volume <- Swaps.total_volume(),
         daily_swap_volume <- Swaps.total_volume(:daily),
         total_swaps <- Swaps.count_swaps(),
         affiliate_transactions <- Swaps.count_affiliate_swaps(),
         affiliate_volume <- Swaps.total_affiliate_volume() do
      {:ok,
       %{
         total_swap_volume: total_swap_volume,
         daily_swap_volume: daily_swap_volume,
         total_swaps: total_swaps,
         affiliate_volume: affiliate_volume,
         affiliate_transactions: affiliate_transactions
       }}
    end
  end

  @spec get_affiliate(binary()) :: :error | {:error, :no_affiliate} | {:ok, {any(), Decimal.t()}}
  def get_affiliate(memo) do
    parts = String.split(memo, ":")

    if length(parts) >= 6 do
      affiliate_id = Enum.at(parts, 4) |> String.split("/") |> Enum.at(0)
      affiliate_bp = Enum.at(parts, 5) |> String.split("/") |> Enum.at(0)

      with {:ok, bps} <- Decimal.cast(affiliate_bp) do
        {:ok, {affiliate_id, Decimal.div(bps, Decimal.new(10_000))}}
      end
    else
      {:error, :no_affiliate}
    end
  end

  def get_dest_address(memo) do
    parts = String.split(memo, ":")

    if Enum.at(parts, 0) in ["SWAP", "="] do
      dest = Enum.at(parts, 2)
      {:ok, dest}
    else
      {:error, :invalid_memo}
    end
  end

  def tx_in(hash) do
    with {:ok,
          %QueryTxResponse{
            observed_tx: %{tx: tx} = observed_tx,
            finalised_height: finalised_height
          } = res} <-
           Thorchain.Node.stub(&Q.tx/2, %QueryTxRequest{tx_id: hash}),
         {:ok, block} <- block(finalised_height) do
      {:ok,
       res
       |> Map.put(:id, hash)
       |> Map.put(:observed_tx, %{observed_tx | tx: cast_tx(tx)})
       |> Map.put(:finalized_height, finalised_height)
       |> Map.put(
         :finalized_events,
         Enum.flat_map(
           block.txs,
           &finalized_events(&1, hash)
         )
       )}
    else
      {:error, _} ->
        {:ok, %{id: hash, observed_tx: nil, finalized_events: nil, finalized_height: nil}}
    end
  end

  def block(height) do
    with {:ok, %QueryBlockResponse{} = block} <-
           Thorchain.Node.stub(&Q.block/2, %QueryBlockRequest{height: to_string(height)}) do
      {:ok,
       %{
         block
         | header: cast_block_header(block.header),
           begin_block_events: Enum.map(block.begin_block_events, &cast_block_event/1),
           end_block_events: Enum.map(block.end_block_events, &cast_block_event/1),
           txs: Enum.map(block.txs, &cast_block_tx/1)
       }}
    end
  end

  defp cast_block_header(%BlockResponseHeader{chain_id: chain_id, height: height, time: time}) do
    {:ok, time, 0} = DateTime.from_iso8601(time)
    %{chain_id: chain_id, height: height, time: time}
  end

  defp cast_block_event(%BlockEvent{
         event_kv_pair: [
           %{key: "type", value: type}
           | attributes
         ]
       }) do
    %{type: type, attributes: attributes}
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

  defp cast_block_tx(%QueryBlockTx{
         hash: hash,
         tx: tx,
         result: result
       }) do
    %{
      hash: hash,
      tx_data: tx,
      result: cast_block_tx_result(result)
    }
  end

  defp cast_block_tx_result(%BlockTxResult{
         code: code,
         data: data,
         log: log,
         info: info,
         gas_wanted: gas_wanted,
         gas_used: gas_used,
         events: events,
         codespace: codespace
       }) do
    %{
      code: code,
      data: data,
      log: log,
      info: info,
      gas_wanted: String.to_integer(gas_wanted),
      gas_used: String.to_integer(gas_used),
      events: Enum.map(events, &cast_block_event/1),
      codespace: codespace
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

  defp finalized_events(%{result: %{events: events}}, hash) do
    Enum.filter(events, fn %{attributes: attributes} ->
      Enum.any?(attributes, &(&1.value == hash))
    end)
  end

  def oracle_from_id(id) do
    with {:ok, price} <- oracle_price(id),
         {:ok, asset} <- Assets.from_id(id) do
      {:ok, %Oracle{id: id, asset: asset, price: price}}
    end
  end

  defmemo oracle_price("THOR.RUNE") do
    with {:ok, %{rune_price_in_tor: price}} <- Thorchain.network(),
         {:ok, price} <- Decimal.cast(price) do
      {:ok, Decimal.div(price, Decimal.new(10_000_000))}
    end
  end

  defmemo oracle_price(asset) do
    with {:ok, %{asset_tor_price: price}} <- Thorchain.pool_from_id(asset) |> IO.inspect(),
         {:ok, price} <- Decimal.cast(price) |> IO.inspect() do
      {:ok, Decimal.div(price, Decimal.new(10_000_000))}
    else
      _ ->
        {:ok, nil}
    end
  end
end
