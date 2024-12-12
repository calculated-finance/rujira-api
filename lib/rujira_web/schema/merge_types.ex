defmodule RujiraWeb.Schema.MergeTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "A merge_pool represents the configuration about a rujira-merge contract"
  node object(:merge_pool) do
    field :address, non_null(:string)

    field :merge_denom, non_null(:denom) do
      resolve(fn %{merge_denom: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :merge_supply, non_null(:bigint)

    field :ruji_denom, non_null(:denom) do
      resolve(fn %{ruji_denom: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :ruji_allocation, non_null(:bigint)
    field :decay_starts_at, non_null(:timestamp)
    field :decay_ends_at, non_null(:timestamp)
    @desc "Current Rate with 12 Decimals place"
    field :current_rate, non_null(:bigint)
    @desc "Start Rate with 12 Decimals place"
    field :start_rate, non_null(:bigint)
    @desc "Effective Rate with 12 Decimals place. Claim Rate considering bonus tokens"
    field :effective_rate, non_null(:bigint)
    field :status, :merge_status
  end

  @desc "A merge_status represents current status about the rujira-merge contract"
  object :merge_status do
    field :merged, non_null(:bigint)
    field :shares, non_null(:bigint)
    field :size, non_null(:bigint)
  end

  @desc "A merge_accounts represents aggregate data about account address related to the merge pools"
  object :merge_stats do
    field :accounts, list_of(non_null(:merge_account))
    field :total_merged, non_null(:bigint)
    field :total_shares, non_null(:bigint)
    field :total_size, non_null(:bigint)
    @desc "Effective Rate with 12 Decimals place. Claim Rate considering bonus tokens"
    field :effective_rate, non_null(:bigint)
  end

  @desc "A merge_account represents data about account address related to the merge pool"
  object :merge_account do
    field :pool_address, non_null(:string)
    field :merged, non_null(:bigint)
    field :shares, non_null(:bigint)
    field :size, non_null(:bigint)
    @desc "Effective Rate with 12 Decimals place. Claim Rate considering bonus tokens"
    field :effective_rate, non_null(:bigint)
  end
end
