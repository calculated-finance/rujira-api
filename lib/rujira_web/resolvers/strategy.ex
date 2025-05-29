defmodule RujiraWeb.Resolvers.Strategy do
  def list(_, args, _) do
    with {:ok, bow} <- Rujira.Bow.list_pools(),
         {:ok, thorchain} <- Thorchain.pools() do
      Enum.concat(bow, thorchain)
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
end
