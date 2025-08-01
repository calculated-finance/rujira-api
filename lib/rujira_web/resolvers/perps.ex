defmodule RujiraWeb.Resolvers.Perps do
  @moduledoc """
  Handles GraphQL resolution for Perps Protocol-related queries.
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Rujira.Perps
  alias Rujira.Prices

  def resolver(_, _, _) do
    Helpers.async(&Perps.list_pools/0)
  end

  def liquidity(quote_denom, %{total: total, unlocked: unlocked, locked: locked}) do
    with {:ok, asset} <- Assets.from_denom(quote_denom) do
      {:ok,
       %{
         total: %{amount: total, asset: asset},
         unlocked: %{amount: unlocked, asset: asset},
         locked: %{amount: locked, asset: asset}
       }}
    end
  end

  def value_usd(%{
        lp_shares: lp_shares,
        xlp_shares: xlp_shares,
        available_yield_lp: available_yield_lp,
        available_yield_xlp: available_yield_xlp,
        pool: %{quote_denom: quote_denom}
      }) do
    with {:ok, asset} <- Assets.from_denom(quote_denom) do
      {:ok,
       Prices.value_usd(
         asset.symbol,
         lp_shares + xlp_shares + available_yield_lp + available_yield_xlp
       )}
    end
  end

  def account_edge(_, %{owner: owner, contract: contract}, _) do
    with {:ok, account} <- Perps.account_from_id("#{owner}/#{contract}") do
      {:ok, %{cursor: account.id, node: account}}
    end
  end
end
