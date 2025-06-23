defmodule RujiraWeb.Schema do
  @moduledoc """
  Defines the root GraphQL schema and types for the Rujira API.
  """

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
    @desc "Fetch a single node using its global Relay-compatible ID."
    field :node, :node do
      arg(:id, non_null(:id))
      resolve(&RujiraWeb.Resolvers.Node.id/2)
    end

    @desc "Fetch multiple nodes by their global Relay-compatible IDs. Useful for batch fetching."
    field :nodes, non_null(list_of(non_null(:node))) do
      @desc "A list of Relay global IDs representing nodes to be fetched."
      arg(:ids, non_null(list_of(non_null(:id))))
      resolve(&RujiraWeb.Resolvers.Node.list/3)
    end

    @desc "Lists all supported Relay node types with their ID structure."
    field :supported_node_types, non_null(list_of(non_null(:node_type_descriptor))) do
      resolve(&RujiraWeb.Resolvers.Node.supported_node_types/3)
    end

    @desc "[DEPRECATED] Legacy THORChain-related queries. Use `thorchain_v2` instead."
    field :thorchain, :thorchain do
      resolve(fn _, _, _ -> {:ok, %{thorchain: %{}}} end)
    end

    @desc "THORChain-related queries using the latest v2 schema."
    field :thorchain_v2, :thorchain_v2 do
      resolve(fn _, _, _ -> {:ok, %{thorchain_v2: %{}}} end)
    end

    @desc "Rujira-specific queries."
    field :rujira, :rujira do
      resolve(fn _, _, _ -> {:ok, %{rujira: %{}}} end)
    end

    @desc "Developer-focused queries related to CosmWasm and smart contract tooling."
    field :developer, :developer do
      resolve(fn _, _, _ -> {:ok, %{developer: %{}}} end)
    end

    import_fields(:rujira)
    import_fields(:developer)
  end

  @desc "Represents any Relay-compliant node object with a globally unique ID."
  interface :node do
    @desc "The Relay global identifier of this object."
    field :id, non_null(:id)

    resolve_type(&RujiraWeb.Resolvers.Node.type/2)
  end

  subscription do
    @desc "Subscribe to updates for a specific node by its global ID."
    field :node, :node do
      arg(:id, non_null(:id))

      config(fn %{id: id}, _ ->
        {:ok, topic: id, context_id: id}
      end)

      resolve(&RujiraWeb.Resolvers.Node.id/2)
    end

    @desc """
    Subscribe to new edges (i.e., added nodes) in a connection.

    This is useful for real-time streaming of new paginated items (e.g., new trades or transactions).
    """
    field :edge, :node_edge do
      @desc "The topic prefix to subscribe to (e.g., base64(`FinTrade:{address}/{resolution}`))."
      arg(:prefix, non_null(:string))

      config(fn %{prefix: prefix}, _ ->
        {:ok, topic: prefix, context_id: prefix}
      end)

      resolve(fn id, args, _ ->
        with {:ok, node} <- RujiraWeb.Resolvers.Node.id(id, args) do
          {:ok, %{cursor: Relay.Connection.offset_to_cursor(node.id), node: node}}
        end
      end)
    end

    import_fields(:fin_subscriptions)
  end

  @desc "A Relay-style edge object containing a node and its pagination cursor."
  object :node_edge do
    field :cursor, :string
    field :node, :node
  end

  @desc """
  Describes a supported Relay node type and its internal ID format.

  This object is used to document how to construct global Relay IDs. Each Relay ID
  is a base64-encoded string in the format: `type:format`.

  For example, the ID `Layer1Account:eth:0x123...` should be encoded to base64 and passed
  to the `node` or `nodes` queries for resolution.

  Use this information to construct valid global IDs when querying the schema.
  """
  object :node_type_descriptor do
    @desc "The `type` value used in a Relay global ID, e.g. `Layer1Account` in `Layer1Account:chain:address`"
    field :type, non_null(:string)

    @desc "The internal `id` format used before encoding to base64"
    field :format, non_null(:string)
  end
end
