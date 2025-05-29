defmodule RujiraWeb.Schema.MergeTypes do
  alias Rujira.Contracts
  alias Rujira.Assets
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  @merge_denom Assets.from_string("THOR.RUJI")

  @desc "A merge_pool represents the configuration about a rujira-merge contract"
  node object(:merge_pool) do
    field :address, non_null(:string)

    field :contract, non_null(:contract_info) do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :merge_asset, non_null(:asset) do
      resolve(fn %{merge_denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :merge_supply, non_null(:bigint)

    field :ruji_asset, non_null(:asset) do
      resolve(fn %{ruji_denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :ruji_allocation, non_null(:bigint)
    field :decay_starts_at, non_null(:timestamp)
    field :decay_ends_at, non_null(:timestamp)
    @desc "Current Rate with 12 Decimals place"
    field :current_rate, non_null(:bigint)
    @desc "Start Rate with 12 Decimals place"
    field :start_rate, non_null(:bigint)

    field :status, :merge_status do
      resolve(&RujiraWeb.Resolvers.Merge.status/3)
    end
  end

  @desc "A merge_status represents current status about the rujira-merge contract"
  object :merge_status do
    @desc "The total amount of merge token deposited"
    field :merged, non_null(:bigint)
    @desc "The total amount of shares issued for the merge pool"
    field :shares, non_null(:bigint)
    @desc "The total amount of ruji token allocated to the merge pool"
    field :size, non_null(:bigint)
    @desc "Current Rate with 12 Decimals place"
    field :current_rate, non_null(:bigint)
    @desc "The amount of ruji allocated per share of the pool"
    field :share_value, non_null(:bigint)
    @desc "Percentage increase in share_value since the start of the merge"
    field :share_value_change, non_null(:bigint)
    @desc "Annualized growth in merging RUJI assuming re-distribution of all un-allocated RUJI"
    field :apr, non_null(:bigint)
  end

  @desc "A merge_accounts represents aggregate data about account address related to the merge pools"
  object :merge_stats do
    field :accounts, list_of(non_null(:merge_account))

    @desc "The total amount of merge token that all `shares` are worth"
    field :total_size, non_null(:balance) do
      resolve(fn %{total_size: total_size}, _, _ ->
        {:ok, %{amount: total_size, asset: @merge_denom}}
      end)
    end
  end

  @desc "A merge_account represents data about account address related to the merge pool"
  node object(:merge_account) do
    field :pool, non_null(:merge_pool)
    @desc "The amount of merge token that has been deposited by the account"
    field :merged, non_null(:balance) do
      resolve(fn %{merged: merged, pool: %{merge_denom: merge_denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(merge_denom) do
          {:ok, %{amount: merged, asset: asset}}
        end
      end)
    end

    @desc "The amount of shares owned by this account"
    field :shares, non_null(:bigint)
    @desc "The amount of ruji token that `shares` are worth"
    field :size, non_null(:balance) do
      resolve(fn %{size: size}, _, _ ->
        {:ok, %{amount: size, asset: @merge_denom}}
      end)
    end

    @desc "The current conversion rate for merge token to ruji token, given current pool ownership"
    field :rate, non_null(:bigint)
  end
end
