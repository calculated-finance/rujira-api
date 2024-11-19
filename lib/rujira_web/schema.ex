defmodule RujiraWeb.Schema do
  use Absinthe.Schema
  import_types(RujiraWeb.Schema.AccountTypes)

  alias RujiraWeb.Resolvers

  query do
    field :accounts, list_of(:root_account) do
      arg(:addresses, list_of(:string))
      resolve(&Resolvers.Account.root_resolver/3)
    end
  end
end
