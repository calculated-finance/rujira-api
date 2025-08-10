defmodule RujiraWeb.Schema.StakingTypes do
  @moduledoc """
  Defines GraphQL types for Staking data in the Rujira API.

  This module contains the type definitions and field resolvers for Staking
  GraphQL objects, including staking pools, positions, and reward calculations.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias Rujira.Contracts
  alias RujiraWeb.Resolvers.Analytics
  alias RujiraWeb.Resolvers.Staking

  object :staking do
    @desc "Staking Pool for single-sided RUJI staking"
    field :single, :staking_pool do
      resolve(&Staking.single/3)
    end

    @desc "Staking Pool for dual RUJI-RUNE LP staking"
    field :dual, :staking_pool do
      resolve(&Staking.dual/3)
    end

    field :pools, non_null(list_of(non_null(:staking_pool))) do
      resolve(&Staking.pools/3)
    end

    @desc "Revenue converter that collects revenue from all apps and delivers it to the staking pools"
    field :revenue, :revenue_converter do
      resolve(&Staking.revenue/3)
    end

    @desc "The token balances on revenue converter contracts that feed the staking contracts"
    field :pending_balances, non_null(list_of(non_null(:balance))),
      resolve: &Staking.pending_balances/3
  end

  @desc "A staking_pool represents the configuration about a rujira-staking contract"
  node object(:staking_pool) do
    field :address, non_null(:address)

    field :contract, :contract_info do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :bond_asset, non_null(:asset) do
      resolve(fn %{bond_denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :revenue_asset, non_null(:asset) do
      resolve(fn %{revenue_denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :receipt_asset, non_null(:asset) do
      resolve(fn %{receipt_denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    @desc "The contract, payload and limit used to convert the collected revenue to the bonded token"
    field :revenue_converter, non_null(:revenue_converter_type) do
      resolve(fn %{revenue_converter: [address, execute_msg, limit]}, _, _ ->
        {:ok, %{address: address, execute_msg: Base.decode64!(execute_msg), limit: limit}}
      end)
    end

    field :status, :staking_status do
      resolve(&Staking.status/3)
    end

    field :summary, non_null(:staking_summary) do
      resolve(&Staking.summary/3)
    end

    field :deployment_status, non_null(:deployment_target_status)

    @desc "The analytics bins for this staking pool"
    connection field :analytics_bins, node_type: :analytics_staking_bins do
      arg(:from, non_null(:timestamp))
      arg(:to, non_null(:timestamp))
      arg(:resolution, non_null(:resolution))
      arg(:period, non_null(:integer))
      resolve(&Analytics.staking_bins_from_pool/3)
    end
  end

  object :revenue_converter do
    field :balances, non_null(list_of(non_null(:balance)))
    field :target_assets, non_null(list_of(non_null(:asset)))
    field :target_addresses, non_null(list_of(non_null(:address)))
  end

  @desc "A staking_status represents current status about the rujira-staking contract"
  node object(:staking_status) do
    @desc "The amount of [bond_denom] bonded in Accounts"
    field :account_bond, non_null(:bigint)
    @desc "The total amount of [revenue_denom] available for Account staking to claim"
    field :account_revenue, non_null(:bigint)
    @desc "The total shares issued for the liquid bonded tokens"
    field :liquid_bond_shares, non_null(:bigint)
    @desc "The total size of the Share Pool of liquid bonded tokens"
    field :liquid_bond_size, non_null(:bigint)
    @desc "The amount of [revenue_denom] pending distribution"
    field :pending_revenue, non_null(:bigint)

    field :value_usd, non_null(:bigint) do
      resolve(&Staking.value_usd/3)
    end
  end

  object :staking_accounts do
    field :single, :staking_account
    field :dual, :staking_account
  end

  @desc "A staking_account represents data about account address related to the staking pool"
  node object(:staking_account) do
    field :pool, non_null(:staking_pool)
    field :account, non_null(:address)

    @desc "The balance of bonded token that has been deposited by the account"
    field :bonded, non_null(:balance) do
      resolve(fn %{bonded: bonded, pool: %{bond_denom: bond_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(bond_denom) do
          {:ok, %{amount: bonded, asset: asset}}
        end
      end)
    end

    @desc "The balance of liquid staked token that is held by the account"
    field :liquid, non_null(:balance) do
      resolve(fn %{liquid_shares: liquid_shares, pool: %{receipt_denom: receipt_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(receipt_denom) do
          {:ok, %{amount: liquid_shares, asset: asset}}
        end
      end)
    end

    @desc "The balance of liquid staked token that is held by the account"
    field :liquid_shares, non_null(:balance) do
      resolve(fn %{liquid_shares: liquid_shares, pool: %{receipt_denom: receipt_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(receipt_denom) do
          {:ok, %{amount: liquid_shares, asset: asset}}
        end
      end)
    end

    @desc "The value of liquid staked token that is held by the account, denominated in the bond token"
    field :liquid_size, non_null(:balance) do
      resolve(fn %{liquid_size: liquid_size, pool: %{bond_denom: bond_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(bond_denom) do
          {:ok, %{amount: liquid_size, asset: asset}}
        end
      end)
    end

    @desc "The balance of pending revenue earned and still not claimed by this account"
    field :pending_revenue, non_null(:balance) do
      resolve(fn %{pending_revenue: pending_revenue, pool: %{revenue_denom: revenue_denom}},
                 _,
                 _ ->
        with {:ok, asset} <- Assets.from_denom(revenue_denom) do
          {:ok, %{amount: pending_revenue, asset: asset}}
        end
      end)
    end

    @desc "The total USD value of liquid tokens, bonded tokens, and pending rewards"
    field :value_usd, non_null(:bigint) do
      resolve(&Staking.value_usd/3)
    end
  end

  @desc "A summary represents apr and revenue earned calculated on a defined resolution"
  node object(:staking_summary) do
    @desc "Annualized APR based on 30 day revenue over current value staked"
    field :apr, non_null(:bigint)
    @desc "Trailing 30 days of collected revenue"
    field :revenue, non_null(list_of(non_null(:staking_revenue_point)))
    @desc "The total amount of [revenue_denom] sent to contract in the last 24 hours"
    field :revenue1, non_null(:bigint)
    @desc "The total amount of [revenue_denom] sent to contract in the last 7 days"
    field :revenue7, non_null(:bigint)
    @desc "The total amount of [revenue_denom] sent to contract in the last 30 days"
    field :revenue30, non_null(:bigint)
  end

  object :staking_revenue_point do
    field :amount, non_null(:bigint)
    field :timestamp, non_null(:timestamp)
  end

  object :revenue_converter_type do
    field :address, non_null(:address)

    field :contract, non_null(:contract_info) do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :execute_msg, non_null(:string)
    field :limit, non_null(:bigint)
  end

  object :staking_subscriptions do
    @desc """
    Triggered any time a staking contract allocates rewards via contract executions.
    Use a `node` subscription to detect changes to liquid account balances
    affected by Transfer events.
    """
    field :staking_account_updated, :staking_account do
      arg(:owner, non_null(:address))

      config(fn _, _ ->
        {:ok, topic: "*"}
      end)

      resolve(&Staking.account_subscription/3)
    end
  end
end
