defmodule Thorchain do
  @moduledoc """
  Main module for interacting with the Thorchain blockchain.

  This module provides functionality for querying and interacting with various aspects
  of the Thorchain network, including vaults, nodes, and liquidity providers.
  """

  alias Cosmos.Bank.V1beta1.QueryDenomOwnersRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Prices
  alias Thorchain.Common.Coin
  alias Thorchain.Common.Tx
  alias Thorchain.Oracle
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.BlockTxResult
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryBlockRequest
  alias Thorchain.Types.QueryBlockResponse
  alias Thorchain.Types.QueryBlockTx
  alias Thorchain.Types.QueryInboundAddressesRequest
  alias Thorchain.Types.QueryInboundAddressesResponse
  alias Thorchain.Types.QueryLiquidityProviderRequest
  alias Thorchain.Types.QueryMimirValuesRequest
  alias Thorchain.Types.QueryMimirValuesResponse
  alias Thorchain.Types.QueryNetworkRequest
  alias Thorchain.Types.QueryOutboundFeesRequest
  alias Thorchain.Types.QueryOutboundFeesResponse
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.QueryPoolsResponse
  alias Thorchain.Types.QueryTxRequest
  alias Thorchain.Types.QueryTxResponse

  import Cosmos.Bank.V1beta1.Query.Stub

  use GenServer
  use Memoize

  def start_link(_) do
    children = [__MODULE__.Listener, __MODULE__.Tor]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def network do
    Thornode.query(&Q.network/2, %QueryNetworkRequest{})
  end

  def pool_from_id(id) do
    case Assets.to_layer1(Assets.from_string(id)) do
      nil -> pool(id)
      %{id: id} -> pool(id)
    end
  end

  defmemo pools(height \\ nil) do
    req = %QueryPoolsRequest{
      height:
        if height do
          Integer.to_string(height)
        else
          ""
        end
    }

    with {:ok, %QueryPoolsResponse{pools: pools}} <-
           Thornode.query(&Q.pools/2, req) do
      {:ok, Enum.map(pools, &cast_pool/1)}
    end
  end

  defmemo pool(asset) do
    # Save hitting the grpc when we already have all the pools for this block
    with {:ok, pools} <- pools(),
         pool when not is_nil(pool) <- Enum.find(pools, &(&1.id == asset)) do
      {:ok, pool}
    else
      nil -> {:ok, nil}
      other -> other
    end
  end

  defmemo halted_pools do
    with {:ok, %QueryMimirValuesResponse{mimirs: mimirs}} <-
           Thornode.query(&Q.mimir_values/2, %QueryMimirValuesRequest{}) do
      halted_pools =
        Enum.reduce(mimirs, [], fn %{key: key, value: value}, acc ->
          if String.starts_with?(key, "PAUSELPDEPOSIT-") && value == 1 do
            pool =
              key
              |> String.replace_prefix("PAUSELPDEPOSIT-", "")
              |> String.replace("-", ".", global: false)

            acc ++ [pool]
          else
            acc
          end
        end)

      {:ok, halted_pools}
    end
  end

  defmemo inbound_addresses do
    with {:ok, %QueryInboundAddressesResponse{inbound_addresses: inbound_addresses}} <-
           Thornode.query(&Q.inbound_addresses/2, %QueryInboundAddressesRequest{}) do
      {:ok, Enum.map(inbound_addresses, &cast_inbound_address/1)}
    end
  end

  defmemo outbound_fees do
    with {:ok, %QueryOutboundFeesResponse{outbound_fees: outbound_fees}} <-
           Thornode.query(&Q.outbound_fees/2, %QueryOutboundFeesRequest{}) do
      {:ok, Enum.map(outbound_fees, &cast_outbound_fee/1)}
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
           Thornode.query(&Q.liquidity_provider/2, req) do
      {:ok, cast_liquidity_provider(res)}
    end
  end

  def cast_liquidity_provider(provider) do
    asset = Assets.from_string(provider.asset)

    provider
    |> Map.put(:id, "#{provider.asset}/#{provider.rune_address}")
    |> Map.put(:asset, asset)
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
    |> Map.put(
      :value_usd,
      Prices.value_usd(asset.symbol, provider.asset_redeem_value) +
        Prices.value_usd("RUNE", provider.rune_redeem_value)
    )
    |> Map.update(:asset_redeem_value, "0", &String.to_integer/1)
    |> Map.update(:rune_redeem_value, "0", &String.to_integer/1)
    |> Map.update(:asset_deposit_value, "0", &String.to_integer/1)
    |> Map.update(:rune_deposit_value, "0", &String.to_integer/1)
    |> Map.update(:luvi_deposit_value, "0", &String.to_integer/1)
    |> Map.update(:luvi_redeem_value, "0", &String.to_integer/1)
    |> Map.update(:luvi_growth_pct, "0", &String.to_float/1)
  end

  def cast_pool(pool) do
    pool
    |> Map.put(:id, pool.asset)
    |> Map.put(:asset, Assets.from_string(pool.asset))
    |> Map.put(:lp_units, Map.get(pool, :LP_units))
    |> Map.update(:lp_units, "0", &String.to_integer/1)
    |> Map.update(:pending_inbound_asset, "0", &String.to_integer/1)
    |> Map.update(:pending_inbound_rune, "0", &String.to_integer/1)
    |> Map.update(:balance_asset, "0", &String.to_integer/1)
    |> Map.update(:balance_rune, "0", &String.to_integer/1)
    |> Map.update(
      :asset_tor_price,
      nil,
      &Decimal.div(Decimal.new(&1), Decimal.new(100_000_000))
    )
    |> Map.update(:pool_units, "0", &String.to_integer/1)
    |> Map.update(:derived_depth_bps, "0", &String.to_integer/1)
    |> Map.update(:savers_fill_bps, "0", &String.to_integer/1)
    |> Map.update(:savers_depth, "0", &String.to_integer/1)
    |> Map.update(:synth_supply_remaining, "0", &String.to_integer/1)
    |> Map.update(:synth_supply, "0", &String.to_integer/1)
    |> Map.update(:synth_units, "0", &String.to_integer/1)
    |> Map.update(:savers_units, "0", &String.to_integer/1)
    |> Map.update(:savers_capacity_remaining, "0", &String.to_integer/1)
    |> Map.update(:loan_collateral, "0", &String.to_integer/1)
    |> Map.update(:loan_collateral_remaining, "0", &String.to_integer/1)
    |> Map.update(:loan_cr, "0", &String.to_integer/1)
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
           Thornode.query(&Q.tx/2, %QueryTxRequest{tx_id: hash}),
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

  defmemo block(height) do
    with {:ok, %QueryBlockResponse{} = block} <-
           Thornode.query(&Q.block/2, %QueryBlockRequest{height: to_string(height)}) do
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
    # convert attributes to map to allow a more flexible access to attributes
    map_attr =
      Enum.reduce(attributes, %{}, fn %{key: key, value: value}, acc ->
        Map.put(acc, key, value)
      end)

    %{type: type, attributes: map_attr}
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
      Enum.any?(attributes, &(elem(&1, 1) == hash))
    end)
  end

  def oracle_from_id(id) do
    with {:ok, %Decimal{} = price} <- oracle_price(id),
         {:ok, %Asset{} = asset} <- Assets.from_id(id) do
      {:ok, %Oracle{id: id, asset: asset, price: price}}
    end
  end

  defmemo oracle_price("THOR.RUNE") do
    with {:ok, %{rune_price_in_tor: price}} <- network(),
         {:ok, price} <- Decimal.cast(price) do
      {:ok, Decimal.div(price, Decimal.new(100_000_000))}
    end
  end

  defmemo oracle_price(asset) do
    case pool_from_id(asset) do
      {:ok, %{asset_tor_price: price}} ->
        {:ok, price}

      _ ->
        {:ok, nil}
    end
  end

  # Holders query
  defmemo get_holders(denom, limit \\ 100), expires_in: 30 * 60 * 60 * 1000 do
    with {:ok, holders} <- get_holders_page(denom) do
      {:ok, holders |> Enum.sort_by(&Integer.parse(&1.balance.amount), :desc) |> Enum.take(limit)}
    end
  end

  defp get_holders_page(denom, key \\ nil)

  defp get_holders_page(denom, nil) do
    with {:ok, %{denom_owners: denom_owners, pagination: %{next_key: next_key}}} <-
           Thornode.query(
             &denom_owners/2,
             %QueryDenomOwnersRequest{denom: denom}
           ),
         {:ok, next} <- get_holders_page(denom, next_key) do
      {:ok, Enum.concat(denom_owners, next)}
    end
  end

  defp get_holders_page(_, "") do
    {:ok, []}
  end

  defp get_holders_page(denom, key) do
    with {:ok, %{denom_owners: denom_owners, pagination: %{next_key: next_key}}} <-
           Thornode.query(
             &denom_owners/2,
             %QueryDenomOwnersRequest{denom: denom, pagination: %PageRequest{key: key}}
           ),
         {:ok, next} <- get_holders_page(denom, next_key) do
      {:ok, Enum.concat(denom_owners, next)}
    end
  end
end
