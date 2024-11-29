defmodule RujiraWeb.Schema do
  use Absinthe.Schema
  import_types(RujiraWeb.Schema.ChainTypes)
  import_types(RujiraWeb.Schema.ThorchainTypes)
  import_types(RujiraWeb.Schema.Scalars.Address)
  import_types(RujiraWeb.Schema.Scalars.Asset)
  import_types(RujiraWeb.Schema.Scalars.BigInt)
  import_types(RujiraWeb.Schema.Scalars.Contract)
  import_types(RujiraWeb.Schema.Scalars.Timestamp)

  query do
    # TODO: Move to a Collection of Accounts, ID'd via chain:address
    @desc "Start with a list of chains"
    field :chains, non_null(:chains) do
      resolve(&RujiraWeb.Resolvers.Chains.resolver/3)
    end

    @desc "THORChain related queries"
    field :thorchain, :thorchain do
      resolve(fn _, _, _ -> {:ok, %{thorchain: %{}}} end)
    end
  end
end
