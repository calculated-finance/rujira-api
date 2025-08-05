defmodule RujiraWeb.Schema.ThorchainTypes do
  @moduledoc """
  Defines GraphQL types for Thorchain data in the Rujira API.

  This module contains the type definitions and field resolvers for Thorchain
  GraphQL objects, including network data, pools, and liquidity providers.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias RujiraWeb.Resolvers

  object :thorchain_v2 do
    field :inbound_addresses, non_null(list_of(non_null(:thorchain_inbound_address))) do
      resolve(&Resolvers.Thorchain.inbound_addresses/3)
    end

    field :outbound_fees, non_null(list_of(non_null(:thorchain_outbound_fee))) do
      resolve(&Resolvers.Thorchain.outbound_fees/3)
    end

    field :quote, :thorchain_quote do
      arg(:from_asset, non_null(:asset_string))
      arg(:to_asset, non_null(:asset_string))
      arg(:amount, non_null(:bigint))
      arg(:streaming_interval, :integer)
      arg(:streaming_quantity, :bigint)
      arg(:destination, :address)
      @desc "Gives you a tolerance from the flat exchange rate of two assets"
      arg(:tolerance_bps, :integer)

      @desc "Applies a tolerance to the expected amount out after liquidity fees, outbound fees, and affiliate fees are deducted"
      arg(:liquidity_tolerance_bps, :integer)
      arg(:refund_address, :address)
      arg(:affiliate, list_of(:string))
      arg(:affiliate_bps, list_of(:integer))
      arg(:height, :string)
      resolve(&Resolvers.Thorchain.quote/3)
    end

    field :pool, :thorchain_pool do
      arg(:asset, non_null(:asset_string))
      resolve(&Resolvers.Thorchain.pool/3)
    end

    field :pools, non_null(list_of(non_null(:thorchain_pool))) do
      resolve(&Resolvers.Thorchain.pools/3)
    end

    field :rune, :asset do
      resolve(fn _, _, _ ->
        {:ok, Assets.from_string("THOR.RUNE")}
      end)
    end

    field :tx_in, :thorchain_tx_in do
      arg(:hash, non_null(:string))
      resolve(&Resolvers.Thorchain.tx_in/3)
    end
  end

  object :thorchain_quote do
    field :asset_in, non_null(:layer_1_balance)
    field :inbound_address, non_null(:address)
    field :inbound_confirmation_blocks, non_null(:integer)
    field :inbound_confirmation_seconds, non_null(:integer)
    field :outbound_delay_blocks, non_null(:integer)
    field :outbound_delay_seconds, non_null(:integer)
    field :fees, non_null(:thorchain_quote_fees)
    field :router, :address
    field :expiry, non_null(:timestamp)
    field :warning, non_null(:string)
    field :notes, non_null(:string)
    field :dust_threshold, :bigint
    field :recommended_min_amount_in, non_null(:bigint)
    field :recommended_gas_rate, non_null(:bigint)
    field :gas_rate_units, non_null(:string)
    field :memo, non_null(:string)
    field :expected_amount_out, non_null(:bigint)
    field :expected_asset_out, non_null(:layer_1_balance)
    field :max_streaming_quantity, non_null(:bigint)
    field :streaming_swap_blocks, non_null(:integer)
    field :streaming_swap_seconds, non_null(:integer)
    field :total_swap_seconds, non_null(:integer)
  end

  object :thorchain_quote_fees do
    field :asset, non_null(:asset)
    field :affiliate, non_null(:string)
    field :outbound, non_null(:bigint)
    field :liquidity, non_null(:bigint)
    field :total, non_null(:bigint)
    field :slippage_bps, non_null(:integer)
    field :total_bps, non_null(:integer)
  end

  node object(:thorchain_pool) do
    field :asset, non_null(:asset)
    field :short_code, non_null(:string)
    field :status, non_null(:thorchain_pool_status)
    field :decimals, non_null(:integer)
    field :pending_inbound_asset, non_null(:bigint)
    field :pending_inbound_rune, non_null(:bigint)
    field :balance_asset, non_null(:bigint)
    field :balance_rune, non_null(:bigint)
    field :asset_tor_price, non_null(:bigint)
    field :pool_units, non_null(:bigint)
    field :lp_units, non_null(:bigint)
    field :synth_units, non_null(:bigint)
    field :synth_supply, non_null(:bigint)
    field :savers_depth, non_null(:bigint)
    field :savers_units, non_null(:bigint)
    field :savers_fill_bps, non_null(:integer)
    field :savers_capacity_remaining, non_null(:bigint)
    field :synth_mint_paused, non_null(:boolean)
    field :synth_supply_remaining, non_null(:bigint)
    field :loan_collateral, non_null(:bigint)
    field :loan_collateral_remaining, non_null(:bigint)
    field :loan_cr, non_null(:bigint)
    field :derived_depth_bps, non_null(:integer)

    connection field :candles, node_type: :thorchain_tor_candle, non_null: true do
      arg(:resolution, non_null(:string))
      resolve(&Resolvers.Thorchain.tor_candles/3)
    end
  end

  node object(:thorchain_tor_price) do
    connection field :candles, node_type: :thorchain_tor_candle, non_null: true do
      arg(:resolution, non_null(:string))
      resolve(&Resolvers.Thorchain.tor_candles/3)
    end
  end

  connection(node_type: :thorchain_tor_candle)

  @desc "Represents a candlestick chart data point for a specific time period, including high, low, open, close, and timestamp."
  node object(:thorchain_tor_candle) do
    field :resolution, non_null(:string)
    field :high, non_null(:bigint)
    field :low, non_null(:bigint)
    field :open, non_null(:bigint)
    field :close, non_null(:bigint)
    field :bin, non_null(:timestamp)
  end

  node object(:thorchain_liquidity_provider) do
    field :asset, non_null(:asset)
    field :rune_address, :address
    field :asset_address, :address
    field :last_add_height, non_null(:integer)
    field :last_withdraw_height, :integer
    field :units, non_null(:bigint)
    field :pending_rune, non_null(:bigint)
    field :pending_asset, non_null(:bigint)
    field :pending_tx_id, :string
    field :rune_deposit_value, non_null(:bigint)
    field :asset_deposit_value, non_null(:bigint)
    field :rune_redeem_value, non_null(:bigint)
    field :asset_redeem_value, non_null(:bigint)
    field :value_usd, non_null(:bigint)
    # field :luvi_deposit_value, 14, type: :string, json_name: "luviDepositValue"
    # field :luvi_redeem_value, 15, type: :string, json_name: "luviRedeemValue"
    # field :luvi_growth_pct, 16, type: :string, json_name: "luviGrowthPct"
  end

  enum :thorchain_pool_status do
    value(:unknown, as: "UnknownPoolStatus")
    value(:available, as: "Available")
    value(:staged, as: "Staged")
    value(:suspended, as: "Suspended")
  end

  node object(:thorchain_inbound_address) do
    field :chain, non_null(:chain)
    field :pub_key, :string
    field :address, non_null(:address)
    field :router, :address
    field :halted, non_null(:boolean)
    field :global_trading_paused, non_null(:boolean)
    field :chain_trading_paused, non_null(:boolean)
    field :chain_lp_actions_paused, non_null(:boolean)
    field :gas_rate, :bigint
    field :gas_rate_units, :string
    field :outbound_tx_size, :bigint
    field :outbound_fee, non_null(:bigint)
    field :dust_threshold, non_null(:bigint)
  end

  object :thorchain_tx_id do
    field :block_height, :bigint
    field :tx_index, :bigint
  end

  node object(:thorchain_tx_in) do
    field :observed_tx, :thorchain_observed_tx
    field :finalized_height, :integer
    field :finalized_events, list_of(non_null(:thorchain_block_event))
  end

  object :thorchain_observed_tx do
    field :tx, :thorchain_layer1_tx
    field :status, :string
  end

  object :thorchain_layer1_tx do
    field :id, :string
    field :chain, :chain
    field :from_address, :address
    field :to_address, :address
    field :coins, non_null(list_of(non_null(:balance)))
    field :gas, non_null(list_of(non_null(:balance)))
    field :memo, :string
  end

  object :thorchain_block do
    field :id, non_null(:thorchain_block_id)
    field :header, non_null(:thorchain_block_header)
    field :begin_block_events, non_null(list_of(non_null(:thorchain_block_event)))
    field :end_block_events, non_null(list_of(non_null(:thorchain_block_event)))
    field :txs, non_null(list_of(non_null(:thorchain_block_tx)))
  end

  object :thorchain_block_id do
    field :hash, non_null(:string)
  end

  object :thorchain_block_header do
    field :chain_id, non_null(:string)
    field :height, non_null(:bigint)
    field :time, non_null(:timestamp)
  end

  object :thorchain_block_event do
    field :type, non_null(:string)
    field :attributes, non_null(list_of(non_null(:thorchain_block_event_attribute)))
  end

  object :thorchain_block_event_attribute do
    field :key, non_null(:string)
    field :value, non_null(:string)
  end

  object :thorchain_block_tx do
    field :hash, non_null(:string)
    field :tx_data, non_null(:string)
    field :result, non_null(:thorchain_tx_result)
  end

  object :thorchain_tx_result do
    field :code, non_null(:integer)
    field :data, :string
    field :log, :string
    field :info, :string
    field :gas_wanted, non_null(:integer)
    field :gas_used, non_null(:integer)
    field :events, non_null(list_of(non_null(:thorchain_block_event)))
    field :codespace, :string
  end

  object :thorchain_tcy do
    field :claimable, non_null(:bigint)
  end

  node object(:thorchain_oracle) do
    field :asset, non_null(:asset)
    field :price, non_null(:bigint)
  end

  object :thorchain_outbound_fee do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end

    field :outbound_fee, non_null(:integer)
    field :fee_withheld_rune, :integer
    field :fee_spent_rune, :integer
    field :surplus_rune, :integer
    field :dynamic_multiplier_basis_points, :integer
  end
end
