defmodule RujiraWeb.Resolvers.Bow do
  alias Absinthe.Resolution.Helpers

  def resolver(_, _, _) do
    Helpers.async(&Rujira.Bow.list_pools/0)
  end
end
