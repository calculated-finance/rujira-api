defmodule RujiraWeb.Resolvers.Account do
  def account_resolver(parent, _, _) do
    {:ok, %{address: "thor1htrqlgcqc8lexctrx7c2kppq4vnphkatgaj932"}}
  end

  def root_accounts_resolver(chain, %{addresses: addresses}, _) do
    {:ok, Enum.map(addresses, &%{address: &1})}
  end
end
