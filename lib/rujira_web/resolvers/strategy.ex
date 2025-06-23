defmodule RujiraWeb.Resolvers.Strategy do
  @moduledoc """
  Handles GraphQL queries for DeFi strategies including Bow pools, Thorchain LPs, and Index vaults.
  """
  alias Absinthe.Relay.Connection
  alias Rujira.Assets
  alias Rujira.Bow
  alias Rujira.Index
  alias Thorchain.Types.QueryPoolResponse

  def list(_, args, _) do
    typenames = Map.get(args, :typenames)
    query = Map.get(args, :query)

    with {:ok, bow} <- Bow.list_pools(),
         {:ok, thorchain} <- Thorchain.pools(),
         {:ok, index} <- Index.load_vaults() do
      Enum.filter(bow, &bow_query(query, &1))
      |> Enum.concat(Enum.filter(thorchain, &thorchain_query(query, &1)))
      |> Enum.concat(Enum.filter(index, &index_query(query, &1)))
      |> Enum.filter(&filter_type(&1, typenames))
      |> Connection.from_list(args)
    end
  end

  def accounts(%{address: address}, _, _) do
    with {:ok, pools} <- Bow.list_pools(),
         {:ok, bow} <-
           Rujira.Enum.reduce_while_ok(pools, [], fn x ->
             case Bow.load_account(x, address) do
               {:ok, %{shares: 0}} -> :skip
               other -> other
             end
           end),
         {:ok, pools} <- Thorchain.pools(),
         {:ok, thorchain} <-
           Rujira.Enum.reduce_async_while_ok(
             pools,
             &Thorchain.liquidity_provider(&1.asset.id, address)
           ),
         {:ok, index} <- Index.accounts(address) do
      accounts =
        bow
        |> Enum.concat(thorchain)
        |> Enum.concat(index)

      {:ok, accounts}
    end
  end

  defp bow_query(query, %{config: %{x: x, y: y}}) do
    with {:ok, x} <- Assets.from_denom(x),
         {:ok, y} <- Assets.from_denom(y) do
      Assets.query_match(query, x, y)
    else
      _ -> false
    end
  end

  defp thorchain_query(_, %{asset: %{symbol: "TCY"}}), do: false

  defp thorchain_query(query, %{asset: %{chain: "THOR"} = asset}) do
    Assets.query_match(query, asset, Assets.from_string("THOR.RUNE"))
  end

  defp thorchain_query(_, _), do: false

  defp index_query(query, %{status: %{allocations: allocations}}) do
    Enum.any?(allocations, fn %{denom: denom} ->
      case Assets.from_denom(denom) do
        {:ok, asset} -> Assets.query_match(query, asset, asset)
        _ -> false
      end
    end)
  end

  def filter_type(_, nil), do: true
  def filter_type(%Bow.Xyk{}, list), do: Enum.member?(list, "BowPoolXyk")

  def filter_type(%QueryPoolResponse{}, list),
    do: Enum.member?(list, "ThorchainPool")

  def filter_type(%Index.Vault{}, list),
    do: Enum.member?(list, "IndexVault")
end
