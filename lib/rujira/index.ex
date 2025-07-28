defmodule Rujira.Index do
  @moduledoc """
  Rujira Index - unified interface for Nav and Fixed index types.
  """

  alias Rujira.Assets
  alias Rujira.Chains.Thor
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Index.Account
  alias Rujira.Index.EntryAdapter
  alias Rujira.Index.Fixed
  alias Rujira.Index.Nav
  alias Rujira.Index.NavBin
  alias Rujira.Index.Vault
  alias Rujira.Prices
  alias Rujira.Repo
  alias Rujira.Resolution

  import Ecto.Query

  use GenServer
  use Memoize

  def start_link(_) do
    children =
      ["1D", "1M", "12M"]
      |> Enum.map(&Supervisor.child_spec({NavBin, &1}, id: &1))
      |> Enum.concat([__MODULE__.Listener])

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    list_vaults()
    {:ok, state}
  end

  defp index_types, do: [Nav, Fixed]

  @doc """
  List all Index Vaults
  """

  def list_vaults do
    with {:ok, vaults} <-
           Rujira.Enum.reduce_async_while_ok(index_types(), &fetch_vaults_for/1, timeout: 20_000) do
      {:ok, List.flatten(vaults)}
    end
  end

  defp fetch_vaults_for(type) do
    type
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_while_ok([], fn
      %{status: :preview} ->
        :skip

      %{module: m, address: a} ->
        Contracts.get({m, a})
    end)
  end

  @doc """
  Load all Index Vaults.
  """
  @spec load_vaults() :: {:ok, list(Vault.t())} | {:error, any()}
  def load_vaults do
    with {:ok, vaults} <- list_vaults() do
      Rujira.Enum.reduce_async_while_ok(vaults, &load_index/1, timeout: 20_000)
    end
  end

  @doc """
  Gets an Index Vault by address.
  """
  @spec get_index(String.t()) ::
          {:ok, Vault.t()} | {:error, :not_found} | {:error, any()}
  def get_index(address) do
    with {:ok, vaults} <- list_vaults() do
      vault = Enum.find(vaults, fn vault -> vault.address == address end)

      case vault do
        nil -> {:error, :not_found}
        vault -> {:ok, vault}
      end
    end
  end

  @doc """
  Loads a specific index with additional chain data.
  """
  @spec load_index(Vault.t()) :: {:ok, Vault.t()} | {:error, any()}
  def load_index(index) do
    with {:ok, res} <- query_status(index.address),
         {:ok, status} <- Vault.status(res),
         {:ok, fees} <- query_fees(index.address) do
      %Vault{index | status: status, fees: fees}
      |> add_nav_change_24h()
      |> add_nav_quote()
      |> add_vault_entry_adapter()
      |> add_apr_30d()
      |> then(&{:ok, &1})
    end
  end

  defmemo query_status(address) do
    Contracts.query_state_smart(address, %{status: %{}})
  end

  defmemo query_fees(address) do
    with {:ok, res} <- Contracts.query_state_smart(address, %{fees: %{}}) do
      Vault.Fees.from_query(res)
    end
  end

  @doc """
  Load and return a fully hydrated index by address.
  """
  @spec index_from_id(String.t()) ::
          {:ok, Vault.t()} | {:error, any()}
  def index_from_id(address) do
    with {:ok, index} <- get_index(address) do
      load_index(index)
    end
  end

  @doc """
  Loads an Account Index by account address
  """
  @spec load_account(Vault.t() | nil, String.t()) ::
          {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(nil, _), do: {:ok, nil}

  def load_account(index, account) do
    with {:ok, %{amount: shares}} <- Thor.balance_of(account, index.share_denom),
         {shares, ""} <- Integer.parse(shares) do
      value =
        value(shares, index)
        |> Decimal.round()
        |> Decimal.to_integer()

      {:ok,
       %Account{
         id: "#{account}/#{index.share_denom}",
         account: account,
         index: index,
         shares: shares,
         shares_value: value
       }}
    end
  end

  def account_from_id(id) do
    [account, share_denom] = String.split(id, "/")

    with {:ok, vault_id} <- get_vault_id(share_denom),
         {:ok, vault} <- index_from_id(vault_id) do
      load_account(vault, account)
    end
  end

  def accounts(address) do
    with {:ok, pools} <- load_vaults() do
      Rujira.Enum.reduce_async_while_ok(pools, fn pool ->
        case load_account(pool, address) do
          {:ok, %{shares: 0}} -> :skip
          other -> other
        end
      end)
    end
  end

  def get_vault_id("nami-index-" <> rest) do
    case String.split(rest, "-rcpt") do
      [type_and_address, ""] ->
        case String.split(type_and_address, "-", parts: 2) do
          [_type, address] -> {:ok, address}
          _ -> {:error, :not_found}
        end

      _ ->
        {:error, :not_found}
    end
  end

  def insert_nav_bin(time, resolution) do
    now = DateTime.utc_now()

    with {:ok, vaults} <- load_vaults() do
      bins =
        vaults
        |> Enum.map(
          &%{
            id: NavBin.id(&1.address, resolution, time),
            contract: &1.address,
            resolution: resolution,
            open: &1.status.nav,
            tvl: &1.status.total_value,
            bin: time,
            inserted_at: now,
            updated_at: now
          }
        )

      Repo.insert_all(NavBin, bins,
        on_conflict: :nothing,
        returning: true
      )
    end
  end

  def query_nav_bins(address, from, to, resolution) do
    NavBin
    |> where(
      [n],
      n.contract == ^address and n.resolution == ^resolution and n.bin >= ^from and n.bin <= ^to
    )
    |> order_by([n], asc: n.bin)
  end

  def query_nav_bin_at(address, resolution, time) do
    NavBin
    |> where(
      [n],
      n.contract == ^address and n.resolution == ^resolution and n.bin == ^time
    )
    |> order_by([n], asc: n.bin)
    |> Repo.one()
  end

  def add_nav_change_24h(vault) do
    {nav_change, tvl_change} =
      change_24h(vault.address, vault.status.nav, vault.status.total_value)

    %Vault{
      vault
      | status: %{vault.status | nav_change: nav_change, total_value_change: tvl_change}
    }
  end

  def add_nav_quote(vault) do
    with {:ok, asset} <- Assets.from_denom(vault.config.quote_denom),
         {:ok, %{current: price}} <- Prices.get(asset.symbol) do
      nav_quote = Decimal.div(vault.status.nav, price)
      %Vault{vault | status: %{vault.status | nav_quote: nav_quote}}
    end
  end

  def change_24h(address, current_nav, current_tvl) do
    today = Resolution.truncate(DateTime.utc_now(), "1D")
    nav_24h_ago = query_nav_bin_at(address, "1D", DateTime.add(today, -1, :day))

    case nav_24h_ago do
      nil ->
        {nil, nil}

      _ ->
        nav_change =
          Decimal.new(current_nav)
          |> Decimal.sub(nav_24h_ago.open)
          |> Decimal.div(nav_24h_ago.open)

        tvl_change =
          Decimal.new(current_tvl)
          |> Decimal.sub(nav_24h_ago.tvl)
          |> Decimal.div(nav_24h_ago.tvl)

        {nav_change, tvl_change}
    end
  end

  def load_entry_adapters do
    EntryAdapter
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_while_ok([], fn %{module: module, address: address} ->
      Contracts.get({module, address})
    end)
  end

  defmemo add_vault_entry_adapter(%Vault{module: Rujira.Index.Fixed, config: config} = vault) do
    with {:ok, entry_adapters} <- load_entry_adapters() do
      entry_adapter =
        Enum.find(entry_adapters, fn entry_adapter ->
          entry_adapter.quote_denom == config.quote_denom
        end)

      %Vault{vault | entry_adapter: entry_adapter.address}
    end
  end

  defmemo(add_vault_entry_adapter(vault), do: vault)

  def value(shares, %Vault{status: %Vault.Status{nav: nav}}),
    do: Decimal.mult(nav, Decimal.new(shares))

  def deposit_query(address, deposit_amount, slippage_bps) do
    with {:ok, vault} <- get_index(address),
         {:ok, vault} <- load_index(vault) do
      Fixed.deposit_query(vault, deposit_amount, slippage_bps)
    end
  end

  def get_yield_vaults do
    ids = [
      "yrune-1.0.1",
      "ytcy"
    ]

    Nav
    |> Deployments.list_targets()
    |> Enum.filter(fn %{id: id} -> id in ids end)
    |> Enum.map(fn %{address: address} -> address end)
  end

  def apr_30d(%{address: address} = vault) do
    today = Resolution.truncate(DateTime.utc_now(), "1D")
    nav_30d_ago = query_nav_bin_at(address, "1D", DateTime.add(today, -30, :day))

    case nav_30d_ago do
      nil ->
        %Vault{vault | status: %{vault.status | apr: "Soon™"}}

      _ ->
        # APR = ((NAV / OPEN) - 1) * (365 / 30)
        growth_factor = Decimal.div(vault.status.nav, nav_30d_ago.open)

        apr =
          growth_factor
          |> Decimal.sub(1)
          |> Decimal.mult(Decimal.new(365))
          |> Decimal.div(30)

        %Vault{vault | status: %{vault.status | apr: apr}}
    end
  end

  def add_apr_30d(vault) do
    yield_vaults = get_yield_vaults()

    if vault.address in yield_vaults do
      apr_30d(vault)
    else
      vault
    end
  end
end
