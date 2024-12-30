defmodule RujiraWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  import_types(RujiraWeb.Schema.AccountTypes)
  import_types(RujiraWeb.Schema.BalanceTypes)
  import_types(RujiraWeb.Schema.ChainTypes)
  import_types(RujiraWeb.Schema.ThorchainTypes)
  import_types(RujiraWeb.Schema.TokenTypes)
  import_types(RujiraWeb.Schema.Scalars.Address)
  import_types(RujiraWeb.Schema.Scalars.Asset)
  import_types(RujiraWeb.Schema.Scalars.BigInt)
  import_types(RujiraWeb.Schema.Scalars.Contract)
  import_types(RujiraWeb.Schema.Scalars.Timestamp)
  import_types(RujiraWeb.Schema.RujiraTypes)
  import_types(RujiraWeb.Schema.MergeTypes)
  import_types(RujiraWeb.Schema.FinTypes)
  import_types(RujiraWeb.Schema.StakingTypes)

  query do
    field :node, :node do
      arg(:id, non_null(:id))
      resolve(&RujiraWeb.Resolvers.Node.id/2)
    end

    @desc """
    Fetch multiple nodes by their global unique identifiers.
    Useful for batch fetching objects in Relay.
    """
    field :nodes, non_null(list_of(non_null(:node))) do
      @desc """
      A list of global unique identifiers of the objects to fetch.
      Each ID must be Relay-compatible.
      """
      arg(:ids, non_null(list_of(non_null(:id))))

      resolve(&RujiraWeb.Resolvers.Node.list/3)
    end

    @desc "THORChain related queries"
    field :thorchain, :thorchain do
      resolve(fn _, _, _ -> {:ok, %{thorchain: %{}}} end)
    end

    @desc "Rujira related queries"
    field :rujira, :rujira do
      resolve(fn _, _, _ -> {:ok, %{rujira: %{}}} end)
    end
  end

  interface :node do
    @desc """
      The globally unique identifier for this object.
      This ID is Relay-compatible and can be used to refetch the object.
      Examples
      - account:sthor1qm7vtdca95aj7nvtrarqm3uah33nhffpnhhg3j for a native account
      - account:btc:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh for a layer 1 Bitcoin account
      - token:asset:BTC.BTC
      - token:denom:rune
    """
    field :id, non_null(:id)
    resolve_type(&RujiraWeb.Resolvers.Node.type/2)
  end
end
