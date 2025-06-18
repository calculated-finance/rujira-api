defmodule RujiraWeb.Schema.IndexTypes do
  alias Rujira.Contracts
  alias Rujira.Assets
  alias RujiraWeb.Resolvers
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "A index_vault represents the configuration about a rujira-index contract"
  node object(:index_vault) do
    field :address, non_null(:string)

    field :contract, non_null(:contract_info) do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :type, non_null(:string) do
      resolve(fn %{module: module}, _, _ ->
        Resolvers.Index.type(module)
      end)
    end

    @desc "Index entry adapter address, present only if index is of type fixed"
    field :entry_adapter, :address

    field :config, non_null(:index_config)

    field :status, non_null(:index_status)

    field :fees, non_null(:index_fees)

    field :share_asset, non_null(:asset) do
      resolve(fn %{share_denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    connection field :nav_bins, node_type: :index_nav_bin do
      arg(:from, non_null(:timestamp))
      arg(:to, non_null(:timestamp))
      arg(:resolution, non_null(:resolution))
      resolve(&Resolvers.Index.nav_bins/3)
    end
  end

  connection(node_type: :index_nav_bin)

  @desc "An index_config represents the configuration about a rujira-index contract"
  object :index_config do
    field :fee_collector, non_null(:address)

    field :quote_asset, non_null(:asset) do
      resolve(fn %{quote_denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end
  end

  @desc "An index_status represents current status about the rujira-index contract"
  object :index_status do
    @desc "The total amount of shares issued for the index vault"
    field :total_shares, non_null(:bigint)
    @desc "The NAV of the index vault in usd"
    field :nav, non_null(:bigint)
    @desc "The allocations of the index vault"
    field :allocations, non_null(list_of(non_null(:index_allocation)))
    @desc "The total value of the index vault"
    field :total_value, non_null(:bigint)
    @desc "The change in NAV over the last 24 hours"
    field :nav_change, :bigint
    @desc "The NAV in quote asset"
    field :nav_quote, :bigint
  end

  @desc "An index_allocation represents the allocation of the index vault"
  object :index_allocation do
    field :asset, non_null(:asset) do
      resolve(fn %{denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    @desc "The target weight of the allocation can either be a % or a fixed amount based on index type"
    field :target_weight, non_null(:bigint)

    @desc "The current weight of the fixed allocation calculated as target_weight * price / total value"
    field :current_weight, non_null(:bigint)
    field :balance, non_null(:bigint)
    field :value, non_null(:bigint)
    field :price, non_null(:bigint)
  end

  object :index_fees do
    field :last_accrual_time, non_null(:timestamp)
    field :high_water_mark, non_null(:bigint)
    field :rates, non_null(:index_fees_rates)
  end

  object :index_fees_rates do
    field :management, non_null(:bigint)
    field :performance, non_null(:bigint)
    field :transaction, non_null(:bigint)
  end

  node object(:index_nav_bin) do
    field :bin, non_null(:timestamp)
    field :contract, non_null(:address)
    field :resolution, non_null(:resolution)
    field :open, non_null(:bigint)
    field :tvl, non_null(:bigint)
  end

  @desc "An index_account represents data about account address related to the index vault"
  node object(:index_account) do
    field :account, non_null(:address)
    field :index, non_null(:index_vault)
    @desc "The amount of shares owned by this account"
    field :shares, non_null(:bigint)
    @desc "The current value of the account"
    field :shares_value, non_null(:bigint)
  end
end
