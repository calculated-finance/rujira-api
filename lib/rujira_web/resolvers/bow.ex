defmodule RujiraWeb.Resolvers.Bow do
  alias Absinthe.Resolution.Helpers

  def resolver(_, _, _) do
    Helpers.async(&Rujira.Bow.list_pools/0)
  end

  def accounts(%{address: address}, _, _) do
    with {:ok, pools} <- Rujira.Bow.list_pools() do
      Rujira.Enum.reduce_while_ok(pools, [], fn x ->
        case Rujira.Bow.load_account(x, address) do
          {:ok, %{shares: 0}} -> :skip
          other -> other
        end
      end)
    end
  end

  def summary(pool, _, _) do
    Rujira.Bow.Xyk.Summary.load(pool)
  end

  def trades(%{address: address}, args, _) do
    with {:ok, query} <- Rujira.Bow.list_trades_query(address) do
      Absinthe.Relay.Connection.from_query(query, &Rujira.Repo.all/1, args)
    end
  end
end
