defmodule RujiraWeb.Resolvers.Strategy do
  @moduledoc """
  Handles GraphQL queries for DeFi strategies including Bow pools, Thorchain LPs, and Index vaults.
  """
  alias Absinthe.Relay.Connection
  alias Rujira.Assets
  alias Rujira.Bow
  alias Rujira.Index
  alias Rujira.Perps
  alias Rujira.Prices
  alias Rujira.Staking
  alias Thorchain.Types.QueryPoolResponse

  def list(_, args, _) do
    typenames = Map.get(args, :typenames)
    query = Map.get(args, :query)
    sort_by = Map.get(args, :sort_by)
    sort_dir = Map.get(args, :sort_dir)

    with {:ok, bow} <- Bow.list_pools(),
         {:ok, thorchain} <- Thorchain.pools(),
         {:ok, index} <- Index.load_vaults(),
         {:ok, staking} <- Staking.list_pools(),
         {:ok, perps} <- Perps.list_pools() do
      Enum.filter(bow, &bow_query(query, &1))
      |> Enum.concat(Enum.filter(thorchain, &thorchain_query(query, &1)))
      |> Enum.concat(Enum.filter(index, &index_query(query, &1)))
      |> Enum.concat(Enum.filter(staking, &staking_query(query, &1)))
      |> Enum.concat(Enum.filter(perps, &perps_query(query, &1)))
      |> Enum.filter(&filter_type(&1, typenames))
      |> Enum.sort_by(
        fn item ->
          sort_fn = sort_by(item, sort_by)
          sort_fn.(item)
        end,
        sort_dir
      )
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
             fn x ->
               case Thorchain.liquidity_provider(x.asset.id, address) do
                 {:ok, %{units: 0}} -> :skip
                 other -> other
               end
             end
           ),
         {:ok, index} <- Index.accounts(address),
         {:ok, pools} <- Staking.list_pools(),
         {:ok, staking} <-
           Rujira.Enum.reduce_async_while_ok(
             pools,
             fn x ->
               case Staking.load_account(x, address) do
                 {:ok, %{bonded: 0, liquid_shares: 0}} -> :skip
                 other -> other
               end
             end
           ),
         {:ok, perps} <- Perps.accounts(address) do
      accounts =
        bow
        |> Enum.concat(thorchain)
        |> Enum.concat(index)
        |> Enum.concat(staking)
        |> Enum.concat(perps)

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

  defp thorchain_query(query, %{asset: asset}) do
    with {:ok, halted_pools} <- Thorchain.halted_pools() do
      if Enum.member?(halted_pools, asset.id) do
        false
      else
        Assets.query_match(query, asset, Assets.from_string("THOR.RUNE"))
      end
    end
  end

  defp index_query(query, %{status: %{allocations: allocations}}) do
    Enum.any?(allocations, fn %{denom: denom} ->
      case Assets.from_denom(denom) do
        {:ok, asset} -> Assets.query_match(query, asset, asset)
        _ -> false
      end
    end)
  end

  defp staking_query(query, %{bond_denom: denom}) do
    case Assets.from_denom(denom) do
      {:ok, asset} ->
        Assets.matches(query, asset)

      _ ->
        false
    end
  end

  defp perps_query(query, %{quote_denom: quote_denom}) do
    case Assets.from_denom(quote_denom) do
      {:ok, asset} -> Assets.matches(query, asset)
      _ -> false
    end
  end

  def filter_type(_, nil), do: true
  def filter_type(%Bow.Xyk{}, list), do: Enum.member?(list, "BowPoolXyk")

  def filter_type(%QueryPoolResponse{}, list),
    do: Enum.member?(list, "ThorchainPool")

  def filter_type(%Index.Vault{}, list),
    do: Enum.member?(list, "IndexVault")

  def filter_type(%Staking.Pool{}, list),
    do: Enum.member?(list, "StakingPool")

  def filter_type(%Perps.Pool{}, list),
    do: Enum.member?(list, "PerpsPool")

  # ---- Sort By ----

  # ThorchainPool
  def sort_by(%QueryPoolResponse{}, :name), do: & &1.asset.symbol
  def sort_by(%QueryPoolResponse{}, :tvl), do: &Prices.value_usd("RUNE", &1.balance_rune * 2)
  # def sort_by(%QueryPoolResponse{}, :apr), do: & &1.asset.symbol

  # BowPoolXyk
  def sort_by(%Bow.Xyk{config: %{x: x, y: y}}, :name) do
    with {:ok, x} <- Assets.from_denom(x),
         {:ok, y} <- Assets.from_denom(y) do
      "#{x.symbol}-#{y.symbol}"
    end
  end

  def sort_by(%Bow.Xyk{config: %{x: x}}, :tvl) do
    with {:ok, x} <- Assets.from_denom(x) do
      &Prices.value_usd(x.symbol, &1.state.x * 2)
    end
  end

  # def sort_by(%Bow.Xyk{}, :apr), do: &("#{&1.config.x}-#{&1.config.y}")

  # IndexVault
  def sort_by(%Index.Vault{share_denom: share_denom}, :name) do
    with {:ok, asset} <- Assets.from_denom(share_denom) do
      asset.symbol
    end
  end

  def sort_by(%Index.Vault{}, :tvl), do: & &1.status.total_value
  # def sort_by(%Index.Vault{}, :apr), do: & &1.status.apr

  # StakingPool
  def sort_by(%Staking.Pool{bond_denom: bond_denom}, :name) do
    with {:ok, asset} <- Assets.from_denom(bond_denom) do
      asset.symbol
    end
  end

  def sort_by(
        %Staking.Pool{
          bond_denom: bond_denom,
          status: %{
            account_bond: account_bond,
            liquid_bond_size: liquid_bond_size
          }
        },
        :tvl
      ) do
    with {:ok, bond_asset} <- Assets.from_denom(bond_denom) do
      Prices.value_usd(bond_asset.ticker, account_bond + liquid_bond_size)
    end
  end

  # def sort_by(%Staking.Pool{}, :apr), do: & &1.bond_denom

  # PerpsPool
  def sort_by(%Perps.Pool{}, :name), do: & &1.base_denom
  def sort_by(%Perps.Pool{}, :tvl), do: & &1.liquidity.total
  # def sort_by(%Perps.Pool{}, :apr), do: & &1.stats.lp_apr
end
