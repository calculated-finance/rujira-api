defmodule RujiraWeb.Schema.PilotTypes do
  @moduledoc """
  Defines GraphQL types for Pilot Protocol data in the Rujira API.

  This module contains the type definitions and field resolvers for Pilot Protocol
  GraphQL objects, including pools, positions, and related data structures.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias RujiraWeb.Resolvers.Pilot

  object :pilot_sale do
    field :address, :address

    field :bid_asset, :asset do
      resolve(fn %{bid_denom: denom}, _, _ -> Assets.from_denom(denom) end)
    end

    field :bid_pools, :pilot_bid_pools
    field :bid_threshold, :bigint
    field :closes, :timestamp

    field :deposit, :balance do
      resolve(fn
        %{deposit: nil}, _, _ ->
          {:ok, nil}

        %{deposit: %{denom: denom, amount: amount}}, _, _ ->
          with {:ok, asset} <- Assets.from_denom(denom) do
            {:ok, %{asset: asset, amount: amount}}
          end
      end)
    end

    field :fee_amount, :bigint
    field :max_premium, :integer
    field :opens, :timestamp
    field :price, :bigint
    field :raise_amount, :bigint
    field :waiting_period, :integer

    connection field :history, node_type: :pilot_bid_action do
      resolve(&Pilot.bid_history/3)
    end

    # Calculated fields
    field :completion_percentage, :bigint
    field :duration, :bigint
    field :avg_price, :bigint

    field :total_bids, :bigint do
      resolve(&Pilot.total_bids/3)
    end
  end

  node object(:pilot_bid_pools) do
    field :pools, list_of(non_null(:pilot_pool))
  end

  object :pilot_pool do
    field :slot, :integer
    field :premium, :integer
    field :rate, :bigint
    field :epoch, :integer
    field :total, :bigint
  end

  node object(:pilot_bid) do
    field :owner, :address
    field :sale, :address
    field :offer, :string, description: "Original offer amount, as it was at `updated_at` time"

    field :premium, :integer
    field :slot, :integer
    field :rate, :bigint
    field :remaining, :bigint
    field :filled, :bigint
    field :updated_at, :timestamp
  end

  connection(node_type: :pilot_bid)

  node object(:pilot_account) do
    field :account, :address
    field :sale, :address

    field :summary, :pilot_account_summary do
      resolve(&Pilot.bids_summary/3)
    end

    connection field :bids, node_type: :pilot_bid do
      resolve(&Pilot.bids/3)
    end

    connection field :history, node_type: :pilot_bid_action do
      resolve(&Pilot.account_bid_history/3)
    end
  end

  object :pilot_account_summary do
    field :avg_discount, :bigint
    field :total_tokens, :bigint
    field :value, :bigint
    field :avg_price, :bigint
    field :total_bids, :bigint
  end

  node object(:pilot_bid_action) do
    field :contract, :address
    field :txhash, :string
    field :owner, :address
    field :premium, :integer
    field :amount, :integer
    field :height, :integer
    field :tx_idx, :integer
    field :idx, :integer
    field :type, :string
    field :timestamp, :timestamp
  end

  connection(node_type: :pilot_bid_action)
end
