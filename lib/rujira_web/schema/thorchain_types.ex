defmodule RujiraWeb.Schema.ThorchainTypes do
  use Absinthe.Schema.Notation
  alias Rujira.Assets
  alias RujiraWeb.Resolvers
  use Absinthe.Relay.Schema.Notation, :modern

  object :thorchain do
    field :inbound_addresses, non_null(list_of(non_null(:inbound_address))) do
      resolve(&Resolvers.Thorchain.inbound_addresses/3)
    end

    field :quote, :quote do
      arg(:from_asset, non_null(:asset_string))
      arg(:to_asset, non_null(:asset_string))
      arg(:amount, non_null(:bigint))
      arg(:streaming_interval, :integer)
      arg(:streaming_quantity, :bigint)
      arg(:destination, :address)
      arg(:tolerance_bps, :integer)
      arg(:refund_address, :address)
      arg(:affiliate, list_of(:string))
      arg(:affiliate_bps, list_of(:integer))
      arg(:height, :string)
      resolve(&Resolvers.Thorchain.quote/3)
    end

    field :pool, :pool do
      arg(:asset, non_null(:asset_string))
      resolve(&Resolvers.Thorchain.pool/3)
    end

    field :pools, non_null(list_of(non_null(:pool))) do
      resolve(&Resolvers.Thorchain.pools/3)
    end

    field :rune, :asset do
      resolve(fn _, _, _ ->
        {:ok, Assets.from_string("THOR.RUNE")}
      end)
    end

    field :summary, :thorchain_summary do
      resolve(&Resolvers.Thorchain.summary/3)
    end

    field :tx_in, :tx_in do
      arg(:hash, non_null(:string))
      resolve(&Resolvers.Thorchain.tx_in/3)
    end
  end

  object :quote do
    field :asset_in, non_null(:layer_1_balance)
    field :inbound_address, non_null(:address)
    field :inbound_confirmation_blocks, non_null(:integer)
    field :inbound_confirmation_seconds, non_null(:integer)
    field :outbound_delay_blocks, non_null(:integer)
    field :outbound_delay_seconds, non_null(:integer)
    field :fees, non_null(:fees)
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

  object :fees do
    field :asset, non_null(:asset)
    field :affiliate, non_null(:string)
    field :outbound, non_null(:bigint)
    field :liquidity, non_null(:bigint)
    field :total, non_null(:bigint)
    field :slippage_bps, non_null(:integer)
    field :total_bps, non_null(:integer)
  end

  object :pool do
    field :asset, non_null(:asset)
    field :short_code, non_null(:string)
    field :status, non_null(:pool_status)
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
  end

  enum :pool_status do
    value(:unknown, as: "UnknownPoolStatus")
    value(:available, as: "Available")
    value(:staged, as: "Staged")
    value(:suspended, as: "Suspended")
  end

  object :inbound_address do
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

  object :thorchain_summary do
    field :unique_swappers, :bigint
    field :total_validator_bond, :bigint

    field :tvl, :bigint
    field :pools_liquidity, :bigint
    field :total_pool_earnings, :bigint

    field :total_transactions, :bigint
    field :total_swaps, :bigint
    field :daily_swap_volume, :bigint
    field :total_swap_volume, :bigint
    field :affiliate_volume, :bigint
    field :affiliate_transactions, :bigint
    field :running_since, :bigint
    field :blockchain_integrated, :bigint
  end

  object :tx_id do
    field :block_height, :bigint
    field :tx_index, :bigint
  end

  node object(:tx_in) do
    field :observed_tx, non_null(:observed_tx)
    field :finalized_events, non_null(list_of(non_null(:block_event)))
  end

  object :observed_tx do
    field :tx, :layer1_tx
    field :status, :string
  end

  object :layer1_tx do
    field :id, :string
    field :chain, :chain
    field :from_address, :address
    field :to_address, :address
    field :coins, non_null(list_of(non_null(:balance)))
    field :gas, non_null(list_of(non_null(:balance)))
    field :memo, :string
  end

  object :block do
    field :id, non_null(:block_id)
    field :header, non_null(:block_header)
    field :begin_block_events, non_null(list_of(non_null(:block_event)))
    field :end_block_events, non_null(list_of(non_null(:block_event)))
    field :txs, non_null(list_of(non_null(:block_tx)))
  end

  object :block_id do
    field :hash, non_null(:string)
  end

  object :block_header do
    field :chain_id, non_null(:string)
    field :height, non_null(:bigint)
    field :time, non_null(:timestamp)
  end

  object :block_event do
    field :type, non_null(:string)
    field :attributes, non_null(list_of(non_null(:block_event_attribute)))
  end

  object :block_event_attribute do
    field :key, non_null(:string)
    field :value, non_null(:string)
  end

  object :block_tx do
    field :hash, non_null(:string)
    field :tx_data, non_null(:string)
    field :result, non_null(:tx_result)
  end

  object :tx_result do
    field :code, non_null(:integer)
    field :data, :string
    field :log, :string
    field :info, :string
    field :gas_wanted, non_null(:integer)
    field :gas_used, non_null(:integer)
    field :events, non_null(list_of(non_null(:block_event)))
    field :codespace, :string
  end
end
