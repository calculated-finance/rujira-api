defmodule RujiraWeb.Resolvers.Strategy do
  def list(_, args, _) do
    with {:ok, bow} <- Rujira.Bow.list_pools(),
         {:ok, thorchain} <- Thorchain.pools() do
      Enum.concat(bow, thorchain)
      |> Absinthe.Relay.Connection.from_list(args)
    end
  end
end
