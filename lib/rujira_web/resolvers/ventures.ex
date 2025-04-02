defmodule RujiraWeb.Resolvers.Ventures do
  alias Rujira.Ventures
  alias Absinthe.Relay

  def resolver(_, _, _) do
    with {:ok, keiko} <- Ventures.keiko() do
      {:ok, %{config: keiko}}
    end
  end

  def sales(_, _, _) do
    with {:ok, sales} <- Ventures.sales() |> IO.inspect() do
      Relay.Connection.from_list(sales, %{first: 100})
    end
  end
end
