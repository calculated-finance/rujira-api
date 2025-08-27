defmodule RujiraWeb.Resolvers.Calc do
  @moduledoc """
  Handles GraphQL resolution for Calc-related queries.
  """
  alias Rujira.Calc

  def accounts(%{address: address}, _, _) do
    with {:ok, account} <- Calc.load_account(address) do
      IO.inspect(account, label: "account")
      {:ok, account}
    end
  end

  def value_usd(_) do
    {:ok, 0}
  end
end
