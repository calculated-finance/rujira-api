defmodule RujiraWeb.Resolvers.Ventures do
  alias Rujira.Ventures
  alias Absinthe.Resolution.Helpers

  def resolver(_, _, _) do
    with {:ok, keiko} <- Ventures.keiko() do
      {:ok, %{config: keiko}}
    end
  end
end
