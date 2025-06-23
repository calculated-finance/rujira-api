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
  alias Rujira.Index.NavBin
  alias Rujira.Index.Vault
  alias Rujira.Prices
  alias Rujira.Repo

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

  defp index_types, do: [Rujira.Index.Nav, Rujira.Index.Fixed]

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
    |> Rujira.Enum.reduce_while_ok([], fn %{module: m, address: a} ->
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
    nav_change = change_24h(vault.address, vault.status.nav)

    %Vault{vault | status: %{vault.status | nav_change: nav_change}}
  end

  def add_nav_quote(vault) do
    with {:ok, asset} <- Assets.from_denom(vault.config.quote_denom),
         {:ok, %{current: price}} <- Prices.get(asset.symbol) do
      nav_quote = Decimal.div(vault.status.nav, price)
      %Vault{vault | status: %{vault.status | nav_quote: nav_quote}}
    end
  end

  def change_24h(address, nav) do
    nav_24h_ago = query_nav_bin_at(address, "1D", DateTime.add(DateTime.utc_now(), -1, :day))

    case nav_24h_ago do
      nil ->
        nil

      _ ->
        Decimal.new(nav_24h_ago.open)
        |> Decimal.sub(nav)
        |> Decimal.div(nav_24h_ago.open)
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
end
