defmodule RujiraWeb.Schema.ThorchainTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers
  alias RujiraWeb.Resolvers.Node

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

    field :rune, :denom do
      resolve(fn _, _, _ ->
        {:ok, %{id: Node.encode_id(:denom, "rune"), denom: "rune"}}
      end)
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
    field :router, :contract
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
    field :asset, non_null(:asset), resolve: &RujiraWeb.Resolvers.Token.asset/3
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
    field :dust_threshold, :bigint
  end
end
