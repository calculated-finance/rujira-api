defmodule RujiraWeb.Resolvers.Strategy do
  alias Rujira.Assets

  def list(_, args, _) do
    typenames = Map.get(args, :typenames)
    query = Map.get(args, :query)

    with {:ok, bow} <- Rujira.Bow.list_pools(),
         {:ok, thorchain} <- Thorchain.pools() do
      Enum.concat(
        Enum.filter(bow, &bow_query(query, &1)),
        Enum.filter(thorchain, &thorchain_query(query, &1))
      )
      |> Enum.filter(&filter_type(&1, typenames))
      |> Absinthe.Relay.Connection.from_list(args)
    end
  end

  def accounts(%{address: address}, _, _) do
    with {:ok, pools} <- Rujira.Bow.list_pools(),
         {:ok, bow} <-
           Rujira.Enum.reduce_while_ok(pools, [], fn x ->
             case Rujira.Bow.load_account(x, address) do
               {:ok, %{shares: 0}} -> :skip
               other -> other
             end
           end),
         {:ok, pools} <- Thorchain.pools(),
         {:ok, thorchain} <-
           pools
           |> Task.async_stream(fn pool ->
             Thorchain.liquidity_provider(pool.asset.id, address)
           end)
           |> Rujira.Enum.reduce_while_ok([], fn
             {:ok, {:ok, %{units: 0}}} -> :skip
             {:ok, v} -> v
             other -> other
           end) do
      {:ok, Enum.concat(bow, thorchain)}
    end
  end

  defp bow_query(query, %{config: %{x: x, y: y}}) do
    with {:ok, x} <- Assets.from_denom(x),
         {:ok, y} <- Assets.from_denom(y) do
      Assets.query_match(query, x, y)
    else
      _ -> false
    end
  end

  defp thorchain_query(query, %{asset: %{chain: "THOR"} = asset}) do
    Assets.query_match(query, asset, Assets.from_string("THOR.RUNE"))
  end

  defp thorchain_query(_, _), do: false

  def filter_type(_, nil), do: true
  def filter_type(%Rujira.Bow.Xyk{}, list), do: Enum.member?(list, "BowPoolXyk")

  def filter_type(%Thorchain.Types.QueryPoolResponse{}, list),
    do: Enum.member?(list, "ThorchainPool")
end
