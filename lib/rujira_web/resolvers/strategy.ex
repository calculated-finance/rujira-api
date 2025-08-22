defmodule RujiraWeb.Resolvers.Strategy do
  @moduledoc """
  Handles GraphQL queries for DeFi strategies including Bow pools, Thorchain LPs, and Index vaults.
  """
  alias Absinthe.Relay.Connection
  alias Rujira.Assets
  alias Rujira.Bow
  alias Rujira.Ghost
  alias Rujira.Index
  alias Rujira.Perps
  alias Rujira.Prices
  alias Rujira.Staking
  alias Thorchain.Types.QueryPoolResponse

  @loaders %{
    "BowPoolXyk" => {&Bow.list_pools/0, &__MODULE__.bow_query/2},
    "GhostVault" => {&Ghost.list_vaults/0, &__MODULE__.ghost_query/2},
    "IndexVault" => {&Index.load_vaults/0, &__MODULE__.index_query/2},
    "PerpsPool" => {&Perps.list_pools/0, &__MODULE__.perps_query/2},
    "StakingPool" => {&Staking.list_pools/0, &__MODULE__.staking_query/2},
    "ThorchainPool" => {&Thorchain.pools/0, &__MODULE__.thorchain_query/2}
  }

  @account_loaders [
    &__MODULE__.bow_accounts/1,
    &__MODULE__.thorchain_accounts/1,
    &Index.accounts/1,
    &__MODULE__.staking_accounts/1,
    &Perps.accounts/1
  ]

  def list(_, args, _) do
    typenames = Map.get(args, :typenames, Map.keys(@loaders))
    query = Map.get(args, :query)
    sort_by = Map.get(args, :sort_by)
    sort_dir = Map.get(args, :sort_dir)

    with {:ok, list} <-
           typenames
           |> Enum.filter(&Enum.member?(Map.keys(@loaders), &1))
           |> Rujira.Enum.reduce_async_while_ok(
             fn name ->
               with {load, filter} <- Map.get(@loaders, name),
                    {:ok, list} <- load.() do
                 {:ok, Enum.filter(list, &filter.(query, &1))}
               end
             end,
             timeout: 30_000
           ) do
      list
      |> Enum.concat()
      |> sort(sort_by, sort_dir)
      |> Connection.from_list(args)
    end
  end

  def accounts(%{address: address}, _, _) do
    with {:ok, accounts} <- Rujira.Enum.reduce_async_while_ok(@account_loaders, & &1.(address)) do
      {:ok, Enum.concat(accounts)}
    end
  end

  def bow_accounts(address) do
    with {:ok, pools} <- Bow.list_pools() do
      Rujira.Enum.reduce_while_ok(pools, [], fn x ->
        case Bow.load_account(x, address) do
          {:ok, %{shares: 0}} -> :skip
          other -> other
        end
      end)
    end
  end

  def thorchain_accounts(address) do
    with {:ok, pools} <- Thorchain.pools() do
      Rujira.Enum.reduce_async_while_ok(
        pools,
        fn x ->
          case Thorchain.liquidity_provider(x.asset.id, address) do
            {:ok, %{units: 0}} -> :skip
            other -> other
          end
        end
      )
    end
  end

  def staking_accounts(address) do
    with {:ok, pools} <- Staking.list_pools() do
      Rujira.Enum.reduce_async_while_ok(
        pools,
        fn x ->
          case Staking.load_account(x, address) do
            {:ok, %{bonded: 0, liquid_shares: 0}} -> :skip
            other -> other
          end
        end
      )
    end
  end

  def bow_query(query, %{config: %{x: x, y: y}}) do
    with {:ok, x} <- Assets.from_denom(x),
         {:ok, y} <- Assets.from_denom(y) do
      Assets.query_match(query, x, y)
    else
      _ -> false
    end
  end

  def ghost_query(query, %{denom: denom}) do
    case Assets.from_denom(denom) do
      {:ok, asset} ->
        Assets.matches(query, asset)

      _ ->
        false
    end
  end

  def thorchain_query(_, %{asset: %{symbol: "TCY"}}), do: false

  def thorchain_query(query, %{asset: asset}) do
    with {:ok, halted_pools} <- Thorchain.halted_pools() do
      if Enum.member?(halted_pools, asset.id) do
        false
      else
        Assets.query_match(query, asset, Assets.from_string("THOR.RUNE"))
      end
    end
  end

  def index_query(query, %{
        share_denom: share_denom,
        status: %{allocations: allocations}
      }) do
    allocations
    |> Enum.concat([%{denom: share_denom}])
    |> Enum.any?(fn %{denom: denom} ->
      case Assets.from_denom(denom) do
        {:ok, asset} -> Assets.query_match(query, asset, asset)
        _ -> false
      end
    end)
  end

  def staking_query(query, %{bond_denom: denom}) do
    case Assets.from_denom(denom) do
      {:ok, asset} ->
        Assets.query_match(query, asset, asset)

      _ ->
        false
    end
  end

  def perps_query(query, %{quote_denom: quote_denom}) do
    case Assets.from_denom(quote_denom) do
      {:ok, asset} -> Assets.query_match(query, asset, asset)
      _ -> false
    end
  end

  # ---- Sort By ----

  def sort(enum, nil, _), do: enum

  def sort(enum, sort_by, sort_dir) do
    Enum.sort_by(
      enum,
      &sort_by(&1, sort_by),
      sort_dir
    )
  end

  # ThorchainPool
  def sort_by(%QueryPoolResponse{asset: asset}, :name), do: asset.symbol

  def sort_by(%QueryPoolResponse{balance_rune: balance_rune}, :tvl),
    do: Prices.value_usd("RUNE", balance_rune * 2)

  # BowPoolXyk
  def sort_by(%Bow.Xyk{config: %{x: x, y: y}}, :name) do
    with {:ok, x} <- Assets.from_denom(x),
         {:ok, y} <- Assets.from_denom(y) do
      "#{x.symbol}-#{y.symbol}"
    end
  end

  def sort_by(%Bow.Xyk{config: %{x: x}, state: state}, :tvl) do
    with {:ok, %{symbol: symbol}} <- Assets.from_denom(x) do
      Prices.value_usd(symbol, state.x * 2)
    end
  end

  # IndexVault
  def sort_by(%Index.Vault{share_denom: share_denom}, :name) do
    with {:ok, asset} <- Assets.from_denom(share_denom) do
      asset.symbol
    end
  end

  def sort_by(%Index.Vault{status: status}, :tvl), do: status.nav

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

  def sort_by(%Staking.Pool{status: :not_loaded} = pool, by) do
    with {:ok, pool} <- Staking.load_pool(pool) do
      sort_by(pool, by)
    end
  end

  # PerpsPool
  def sort_by(%Perps.Pool{base_denom: base_denom}, :name), do: base_denom
  def sort_by(%Perps.Pool{liquidity: liquidity}, :tvl), do: liquidity.total

  # GhostVault
  def sort_by(%Ghost.Vault{denom: denom}, :name) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      asset.symbol
    end
  end

  def sort_by(%Ghost.Vault{denom: denom, status: %{deposit_pool: %{size: size}}}, :tvl) do
    with {:ok, %{symbol: symbol}} <- Assets.from_denom(denom) do
      Prices.value_usd(symbol, size)
    end
  end

  def sort_by(%Ghost.Vault{status: :not_loaded} = vault, :tvl) do
    with {:ok, vault} <- Ghost.load_vault(vault) do
      sort_by(vault, :tvl)
    end
  end

  def sort_by(%{deployment_status: :preview}, :tvl), do: -1
end
