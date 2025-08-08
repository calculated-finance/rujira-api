defmodule Rujira.Pilot do
  @moduledoc """
  Rujira.Pilot
  """
  use GenServer
  use Memoize

  import Ecto.Query
  require Logger

  alias Rujira.Contracts
  alias Rujira.Pilot.Account
  alias Rujira.Pilot.Bid
  alias Rujira.Pilot.BidAction
  alias Rujira.Pilot.BidPools
  alias Rujira.Pilot.Pool
  alias Rujira.Pilot.Sale
  alias Rujira.Repo

  # --- Supervision / GenServer ---

  def start_link(_) do
    children = [
      __MODULE__.Listener,
      __MODULE__.Indexer
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  # --- Public API (alphabetical) ---

  @doc "Load an account struct from sale and account."
  def load_account(sale, account) do
    {:ok, %Account{id: "#{sale}/#{account}", sale: sale, account: account}}
  end

  @doc "Load an account struct from a composite ID."
  def account_from_id(id) do
    [sale, account] = String.split(id, "/", parts: 2)
    {:ok, %Account{id: id, sale: sale, account: account}}
  end

  @doc "Queries for a specific bid by owner and premium."
  def bid(address, owner, premium) do
    with {:ok, order_data} <- query_order(address, owner, premium) do
      {:ok, Bid.from_query(%{address: address}, order_data)}
    end
  end

  @doc "Get a bid from its composite ID."
  def bid_from_id(id) do
    [sale, owner, premium] = String.split(id, "/", parts: 3)

    with {:ok, bid_data} <- query_order(sale, owner, premium) do
      {:ok, Bid.from_query(%{address: sale}, bid_data)}
    end
  end

  @doc "Fetches bid pools for a pilot contract."
  def bid_pools_from_id(address), do: pools(%Sale{address: address}, nil, nil)

  @doc "Queries for paginated bids for a specific owner."
  def bids(address, owner, offset, limit) do
    with {:ok, %{"orders" => orders}} <- query_bids(address, owner, offset, limit) do
      Rujira.Enum.reduce_async_while_ok(orders, fn bid ->
        Bid.from_query(%{address: address}, bid)
      end)
    end
  end

  @doc "Summary of bids for a specific owner."
  def bids_summary(address, owner) do
    with {:ok, bids} <- bids(address, owner, nil, nil) do
      Account.Summary.from_bids(bids)
    end
  end

  @doc "Get history for an account."
  def list_account_bid_action_query(address, owner) do
    BidAction
    |> where([o], o.contract == ^address and o.owner == ^owner)
    |> order_by([o], desc: o.timestamp)
  end

  @doc "Queries for all orders for a specific sale."
  def list_all_bid_actions_query(address) do
    BidAction
    |> where([o], o.contract == ^address)
    |> order_by([o], desc: o.timestamp)
  end

  @doc "Queries for paginated liquidity pools."
  def pools(%Sale{address: address}, offset, limit) do
    with {:ok, %{"pools" => pools}} <- query_pools(address, offset, limit),
         {:ok, pools} <- Rujira.Enum.reduce_async_while_ok(pools, &Pool.from_query/1) do
      {:ok, %BidPools{id: address, pools: pools}}
    end
  end

  @doc "Total number of bids for a specific sale."
  def total_bids(nil), do: {:ok, nil}

  def total_bids(address) do
    BidAction
    |> where([o], o.contract == ^address)
    |> select([o], count(o.id))
    |> Repo.one()
    |> case do
      nil -> {:ok, 0}
      count -> {:ok, count}
    end
  end

  # --- DB operations ---
  def insert_bid_actions(bid_actions) do
    with {count, items} when is_list(items) <-
           Repo.insert_all(BidAction, bid_actions, on_conflict: :nothing, returning: true) do
      broadcast_bid_actions({count, items})
    end
  end

  def broadcast_bid_actions({_count, bid_actions}) do
    for o <- bid_actions do
      Logger.debug("#{__MODULE__} broadcast Pilot bid action #{o.id}")
      Rujira.Events.publish_edge(:pilot_bid_action, o.contract, o.id)
      Rujira.Events.publish_node(:pilot_sale, o.contract)
    end
  end

  # --- Private/Internal (memoized) queries ---
  defmemo query_bids(address, owner, offset, limit) do
    query_params =
      %{
        owner: owner,
        offset: offset,
        limit: limit
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    Contracts.query_state_smart(address, %{orders: query_params})
  end

  defmemo query_order(address, owner, premium) do
    # Rust query expects a tuple [String, u8]
    Contracts.query_state_smart(address, %{order: [owner, premium]})
  end

  defmemo query_pools(address, offset, limit) do
    query_params =
      [offset: offset, limit: limit]
      |> Enum.reject(&is_nil(elem(&1, 1)))
      |> Map.new()

    Contracts.query_state_smart(address, %{pools: query_params})
  end
end
