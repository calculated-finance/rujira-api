defmodule RujiraWeb.Schema.PilotTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:pilot_pool) do
    field :slot, non_null(:integer)
    field :premium, non_null(:integer)
    field :rate, non_null(:bigint)
    field :epoch, non_null(:integer)
    field :total, non_null(:bigint)
  end

  enum :pilot_status do
    value(:active)
    value(:retracted)
    value(:executed)
  end

  object :pilot_config do
    field :bid_asset, non_null(:asset)
    field :offer_asset, non_null(:asset)
    field :executor, non_null(:address)
    field :max_premium, non_null(:integer)
    field :price, non_null(:bigint)
    field :opens, non_null(:timestamp)
    field :closes, non_null(:timestamp)
    field :fee_maker, non_null(:bigint)
    field :fee_taker, non_null(:bigint)
    field :fee_address, non_null(:address)
    field :funds, non_null(:balance)
    field :status, non_null(:pilot_status)
  end

  node object(:pilot_bid) do
    field :owner, non_null(:address)
    field :updated_at, non_null(:timestamp)

    field :offer, non_null(:string),
      description: "Original offer amount, as it was at `updated_at` time"

    field :premium, non_null(:integer)
    field :slot, non_null(:integer)
    field :rate, non_null(:bigint)
    field :amount, non_null(:bigint)
    field :filled, non_null(:bigint)
  end

  connection(node_type: :pilot_bid)

  object :pilot_account do
    connection field :bids, node_type: :pilot_bid do
      resolve(&RujiraWeb.Resolvers.Pilot.bids/3)
    end

    # connection field :history, node_type: :pilot_account_action do
    #   resolve(&RujiraWeb.Resolvers.Fin.history/3)
    # end
  end
end
