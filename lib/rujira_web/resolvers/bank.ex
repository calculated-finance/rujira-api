defmodule RujiraWeb.Resolvers.Bank do
  alias Rujira.Assets

  def resolver(_, _, _), do: {:ok, %{supply: nil}}

  def total_supply(_, _, _) do
    with {:ok, supply} <- Rujira.Bank.total_supply() do
      {:ok, Map.values(supply)}
    end
  end
end
