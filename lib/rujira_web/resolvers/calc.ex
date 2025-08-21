defmodule RujiraWeb.Resolvers.Calc do
  @moduledoc """
  Handles GraphQL resolution for Calc-related queries.
  """
  alias Rujira.Calc

  def accounts(%{address: address}, _, _) do
    Calc.load_account(address)
  end

  def value_usd(_) do
    {:ok, 0}
  end
end
