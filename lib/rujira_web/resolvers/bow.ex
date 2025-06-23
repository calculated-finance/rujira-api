defmodule RujiraWeb.Resolvers.Bow do
  @moduledoc """
  Handles GraphQL resolution for Bow Protocol-related queries.
  """
  alias Absinthe.Relay.Connection
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Rujira.Bow
  alias Rujira.Bow.Xyk.Summary
  alias Rujira.Prices
  alias Rujira.Repo

  def resolver(_, _, _) do
    Helpers.async(&Bow.list_pools/0)
  end

  def accounts(%{address: address}, _, _) do
    with {:ok, pools} <- Bow.list_pools() do
      Rujira.Enum.reduce_while_ok(pools, [], fn x ->
        case Bow.load_account(x, address) do
          {:ok, %{shares: 0}} -> :skip
          other -> other
        end
      end)
    end
  end

  def summary(pool, _, _) do
    Summary.load(pool)
  end

  def trades(%{address: address}, args, _) do
    with {:ok, query} <- Bow.list_trades_query(address) do
      Connection.from_query(query, &Repo.all/1, args)
    end
  end

  def quotes(%{address: address}, _, _) do
    with {:ok, pair} <- Bow.fin_pair(address),
         {:ok, quotes} <- Bow.load_quotes(address) do
      {:ok, Map.put(quotes, :contract, pair.address)}
    end
  end

  def value_usd(values) do
    Enum.reduce(values, 0, fn %{amount: amount, denom: denom}, acc ->
      case Assets.from_denom(denom) do
        {:ok, asset} -> acc + Prices.value_usd(asset.symbol, amount)
        _ -> acc
      end
    end)
  end
end
