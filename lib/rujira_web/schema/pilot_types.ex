defmodule RujiraWeb.Schema.PilotTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  object :pool do
    field :premium, non_null(:integer)
    field :rate, non_null(:decimal)
    field :pool, non_null(:bid_pool)
  end

  object :bid_pool do
    field :total, non_null(:string)
    field :sum, non_null(:string)
    field :product, non_null(:string)
    field :epoch, non_null(:integer)
  end

  object :denoms do
    field :values, list_of(:string)
  end

  enum :pilot_status do
    value(:active)
    value(:retracted)
    value(:executed)
  end

  object :config do
    field :denoms, non_null(:denoms)
    field :executor, non_null(:address)
    field :max_premium, non_null(:integer)
    field :price, non_null(:decimal)
    field :opens, non_null(:timestamp)
    field :closes, non_null(:timestamp)
    field :fee_maker, non_null(:decimal)
    field :fee_taker, non_null(:decimal)
    field :fee_address, non_null(:address)
    field :funds, non_null(:coin)
    field :status, non_null(:pilot_status)
  end

  object :order do
    field :owner, non_null(:address)
    field :updated_at, non_null(:timestamp)

    field :offer, non_null(:string),
      description: "Original offer amount, as it was at `updated_at` time"

    field :bid, non_null(:bid)
  end

  object :bid do
    field :amount, non_null(:string)
    field :filled, non_null(:string)
    field :product_snapshot, non_null(:string)
    field :sum_snapshot, non_null(:string)
    field :epoch_snapshot, non_null(:integer)
  end

  object :native_balance do
    field :coins, list_of(:coin)
  end

  object :cosmos_attribute do
    field :key, non_null(:string)
    field :value, non_null(:string)
  end

  object :cosmos_event do
    field :type, non_null(:string)
    field :attributes, list_of(:cosmos_attribute)
  end

  object :order_manager do
    field :denoms, non_null(:denoms)
    field :fee, non_null(:decimal)
    field :owner, non_null(:address)
    field :timestamp, non_null(:timestamp)
    field :oracle, non_null(:decimal)
    field :max_premium, non_null(:integer)
    field :receive, non_null(:native_balance)
    field :send, non_null(:native_balance)
    field :fees, non_null(:native_balance)
    field :events, list_of(:cosmos_event)
  end

  object :config_response do
    field :denoms, non_null(:denoms)
    field :executor, non_null(:string)
    field :fee_taker, non_null(:decimal)
    field :fee_maker, non_null(:decimal)
    field :fee_address, non_null(:string)
  end

  object :order_response do
    field :owner, non_null(:string)
    field :premium, non_null(:integer)
    field :rate, non_null(:decimal)
    field :updated_at, non_null(:timestamp)
    field :offer, non_null(:string)
    field :remaining, non_null(:string)
    field :filled, non_null(:string)
  end

  object :orders_response do
    field :orders, list_of(:order_response)
  end

  object :pools_response do
    field :pools, list_of(:pool_response)
  end

  object :pool_response do
    field :premium, non_null(:integer)
    field :epoch, non_null(:integer)
    field :price, non_null(:decimal)
    field :total, non_null(:string)
  end

  object :simulation_response do
    field :returned, non_null(:string)
    field :fee, non_null(:string)
  end

  input_object :update_config_input do
    field :fee_taker, :decimal
    field :fee_maker, :decimal
    field :fee_address, :string
  end

  object :update_config do
    field :fee_taker, :decimal
    field :fee_maker, :decimal
    field :fee_address, :string
  end

  object :retract do
  end

  union :sudo_msg do
    types([:update_config, :retract])

    resolve_type(fn
      %{fee_taker: _, fee_maker: _, fee_address: _}, _ -> :update_config
      %{}, _ -> :retract
    end)
  end
end
