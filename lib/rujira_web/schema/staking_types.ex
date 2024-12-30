defmodule RujiraWeb.Schema.StakingTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "A staking_pool represents the configuration about a rujira-staking contract"
  node object(:staking_pool) do
    field :address, non_null(:string)

    field :bond_denom, non_null(:denom) do
      resolve(fn %{bond_denom: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :revenue_denom, non_null(:denom) do
      resolve(fn %{revenue_denom: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :revenue_converter, non_null(:revenue_converter_type) do
      resolve(fn %{revenue_converter: {address, execute_msg, limit}}, _, _ ->
        {:ok, %{address: address, execute_msg: Base.encode64(execute_msg), limit: limit}}
      end)
    end

    field :status, :staking_status

    field :summary, non_null(list_of(non_null(:summary))) do
      arg(:resolution, non_null(:integer))
      resolve(&RujiraWeb.Resolvers.Staking.summary/3)
    end
  end

  @desc "A staking_status represents current status about the rujira-staking contract"
  object :staking_status do
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
  end

  @desc "A staking_account represents data about account address related to the staking pool"
  object :staking_account do
    field :pool, non_null(:staking_pool)
    field :account, non_null(:address)

    @desc "The balance of bonded token that has been deposited by the account"
    field :bonded, non_null(:balance) do
      resolve(fn %{bonded: bonded, pool: %{bond_denom: bond_denom}}, _, _ ->
        {:ok, %{amount: bonded, denom: bond_denom}}
      end)
    end

    @desc "The balance of pending revenue earned and still not claimed by this account"
    field :pending_revenue, non_null(:balance) do
      resolve(fn %{pending_revenue: pending_revenue, pool: %{revenue_denom: revenue_denom}},
                 _,
                 _ ->
        {:ok, %{amount: pending_revenue, denom: revenue_denom}}
      end)
    end
  end

  @desc "A summary represents apr and revenue earned calculated on a defined resolution"
  object :summary do
    @desc "list of 10 apr points equally distributed based on the defined resolution. 12 decimals."
    field :apr, non_null(list_of(non_null(:bigint)))
    @desc "The total amount of [revenue_denom] earned by the stakers in a defined resolution"
    field :revenue_earned, non_null(:bigint)
  end

  object :revenue_converter_type do
    field :address, non_null(:address)
    field :execute_msg, non_null(:string)
    field :limit, non_null(:bigint)
  end

end
