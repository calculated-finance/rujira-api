defmodule RujiraWeb.Schema do
  alias Absinthe.Relay
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  import_types(RujiraWeb.Schema.AccountTypes)
  import_types(RujiraWeb.Schema.AnalyticsTypes)
  import_types(RujiraWeb.Schema.BalanceTypes)
  import_types(RujiraWeb.Schema.BankTypes)
  import_types(RujiraWeb.Schema.BowTypes)
  import_types(RujiraWeb.Schema.ChainTypes)
  import_types(RujiraWeb.Schema.DeveloperTypes)
  import_types(RujiraWeb.Schema.FinTypes)
  import_types(RujiraWeb.Schema.IndexTypes)
  import_types(RujiraWeb.Schema.LeaguesTypes)
  import_types(RujiraWeb.Schema.MergeTypes)
  import_types(RujiraWeb.Schema.PilotTypes)
  import_types(RujiraWeb.Schema.RujiraTypes)
  import_types(RujiraWeb.Schema.Scalars.Address)
  import_types(RujiraWeb.Schema.Scalars.Asset)
  import_types(RujiraWeb.Schema.Scalars.BigInt)
  import_types(RujiraWeb.Schema.Scalars.Resolution)
  import_types(RujiraWeb.Schema.Scalars.Timestamp)
  import_types(RujiraWeb.Schema.StakingTypes)
  import_types(RujiraWeb.Schema.StrategyTypes)
  import_types(RujiraWeb.Schema.Thorchain.AnalyticsTypes)
  import_types(RujiraWeb.Schema.ThorchainTypes)
  import_types(RujiraWeb.Schema.ThorchainTypesOld)
  import_types(RujiraWeb.Schema.TokenTypes)
  import_types(RujiraWeb.Schema.VenturesTypes)

  def middleware(middleware, _field, _) do
    [RujiraWeb.Middleware.InstrumentResolver | middleware]
  end

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

    field :thorchain_v2, :thorchain_v2 do
      resolve(fn _, _, _ -> {:ok, %{thorchain_v2: %{}}} end)
    end

    @desc "Rujira related queries"
    field :rujira, :rujira do
      resolve(fn _, _, _ -> {:ok, %{rujira: %{}}} end)
    end

    import_fields(:rujira)
    import_fields(:developer)

    @desc "Developer-related CosmWasm queries"
    field :developer, :developer do
      resolve(fn _, _, _ -> {:ok, %{developer: %{}}} end)
    end
  end

  interface :node do
    @desc """
      The globally unique identifier for this object.
      This ID is Relay-compatible and can be used to refetch the object.
    """
    field :id, non_null(:id)
    resolve_type(&RujiraWeb.Resolvers.Node.type/2)
  end

  subscription do
    @desc """
    Subscribes to updates for the given Node ID
    """
    field :node, :node do
      arg(:id, non_null(:id))

      config(fn %{id: id}, _ ->
        {
          :ok,
          # Use the node ID as the context to allow absinthe to de-deduplicate updates for a given node
          # https://hexdocs.pm/absinthe/subscriptions.html#de-duplicating-updates
          topic: id, context_id: id
        }
      end)

      resolve(&RujiraWeb.Resolvers.Node.id/2)
    end

    @desc """
    Subscribes to new Edges on a connection,
    """

    field :edge, :node_edge do
      @desc """
      The Prefix of the Edge Node, eg

      base64(FinTrade:{address}/{resolution})
      """
      arg(:prefix, non_null(:string))

      config(fn %{prefix: prefix}, _ ->
        {:ok, topic: prefix, context_id: prefix}
      end)

      resolve(fn id, x, _ ->
        with {:ok, node} <- RujiraWeb.Resolvers.Node.id(id, x) do
          {:ok, %{cursor: Relay.Connection.offset_to_cursor(node.id), node: node}}
        end
      end)
    end

    import_fields(:fin_subscriptions)
  end

  object :node_edge do
    field :cursor, :string
    field :node, :node
  end
end
