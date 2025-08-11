defmodule RujiraWeb.Schema.PerpsTypes do
  @moduledoc """
  Defines GraphQL types for Perps Protocol-related data in the Rujira API.

  This module contains the type definitions and field resolvers for Perps Protocol
  GraphQL objects, including pools, positions, and related data structures.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias Rujira.Contracts
  alias RujiraWeb.Resolvers.Perps

  node object(:perps_pool) do
    field :address, non_null(:address)

    field :contract, :contract_info do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :name, non_null(:string)

    field :base_asset, non_null(:asset) do
      resolve(fn %{base_denom: base_denom}, _, _ ->
        {:ok, Assets.from_shortcode(base_denom)}
      end)
    end

    field :quote_asset, non_null(:asset) do
      resolve(fn %{quote_denom: quote_denom}, _, _ ->
        Assets.from_denom(quote_denom)
      end)
    end

    field :liquidity, non_null(:perps_liquidity) do
      resolve(fn %{quote_denom: quote_denom, liquidity: liquidity}, _, _ ->
        Perps.liquidity(quote_denom, liquidity)
      end)
    end

    field :stats, non_null(:perps_stats)
  end

  object :perps_liquidity do
    field :total, non_null(:balance)
    field :unlocked, non_null(:balance)
    field :locked, non_null(:balance)
  end

  object :perps_stats do
    field :sharpe_ratio, non_null(:bigint)
    field :lp_apr, non_null(:bigint)
    field :xlp_apr, non_null(:bigint)
    field :risk, non_null(:perps_risk_level)
  end

  enum :perps_risk_level do
    value(:low)
    value(:medium)
    value(:high)
  end

  node object(:perps_account) do
    field :account, non_null(:address)
    field :pool, non_null(:perps_pool)

    field :lp_shares, non_null(:bigint)

    field :lp_size, non_null(:balance) do
      resolve(fn %{lp_value: value, pool: %{quote_denom: quote_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(quote_denom) do
          {:ok, %{amount: value, asset: asset}}
        end
      end)
    end

    field :xlp_shares, non_null(:bigint)

    field :xlp_size, non_null(:balance) do
      resolve(fn %{xlp_value: value, pool: %{quote_denom: quote_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(quote_denom) do
          {:ok, %{amount: value, asset: asset}}
        end
      end)
    end

    field :available_yield_lp, non_null(:balance) do
      resolve(fn %{available_yield_lp: value, pool: %{quote_denom: quote_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(quote_denom) do
          {:ok, %{amount: value, asset: asset}}
        end
      end)
    end

    field :available_yield_xlp, non_null(:balance) do
      resolve(fn %{available_yield_xlp: value, pool: %{quote_denom: quote_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(quote_denom) do
          {:ok, %{amount: value, asset: asset}}
        end
      end)
    end

    field :liquidity_cooldown, :perps_liquidity_cooldown

    field :value_usd, non_null(:bigint) do
      resolve(fn account, _, _ ->
        Perps.value_usd(account)
      end)
    end
  end

  object :perps_liquidity_cooldown do
    field :start_at, non_null(:timestamp)
    field :end_at, non_null(:timestamp)
  end

  object :perps_subscriptions do
    @desc """
    Triggered when a perps account is updated.
    One subscription per order.
    """
    field :perps_account_updated, :node_edge do
      arg(:contract, non_null(:address))
      arg(:owner, non_null(:address))

      config(fn %{contract: contract}, _ ->
        {:ok, topic: contract}
      end)

      resolve(&Perps.account_edge/3)
    end
  end
end
