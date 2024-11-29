defmodule RujiraWeb.Schema.ThorchainTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers

  object :thorchain do
    field :quote, non_null(:quote) do
      arg(:from_asset, non_null(:asset))
      arg(:to_asset, non_null(:asset))
      arg(:amount, non_null(:bigint))
      arg(:streaming_interval, :integer)
      arg(:streaming_quantity, :bigint)
      arg(:destination, :address)
      arg(:tolerance_bps, :integer)
      arg(:refund_address, :address)
      arg(:affiliate, list_of(:string))
      arg(:affiliate_bps, list_of(:string))
      arg(:height, :string)
      resolve(&Resolvers.Thorchain.quote/3)
    end
  end

  object :quote do
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

    field :expected_asset_out, non_null(:balance) do
      resolve(&RujiraWeb.Resolvers.Balance.quote/3)
    end

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
end
