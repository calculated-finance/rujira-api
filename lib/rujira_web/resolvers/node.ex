defmodule RujiraWeb.Resolvers.Node do
  @moduledoc """
  Handles GraphQL resolution for node-related queries and operations.

  This module implements the Relay Global Object Identification specification,
  providing a unified way to fetch any object in the system by its global ID.
  """

  # ===== Module Aliases =====
  # Grouped by functional domain for better organization

  # Core Modules
  alias Rujira.Accounts
  alias Rujira.Assets
  alias Rujira.Bank
  alias Rujira.Contracts
  alias Rujira.Prices

  # Protocol Modules
  alias Rujira.Bow
  alias Rujira.Fin
  alias Rujira.Index
  alias Rujira.Leagues
  alias Rujira.Merge
  alias Rujira.Staking

  # Data & Analytics

  # Web & Resolvers
  alias RujiraWeb.Resolvers

  # ===== Public API =====

  @doc """
  Resolves a single node by its global ID.
  """
  def id(%{id: encoded_id}, _) do
    resolve_id(encoded_id)
  end

  @doc """
  Resolves multiple nodes by their global IDs in parallel.

  Returns `{:ok, list}` where each element is either a resolved node or an error.
  """
  def list(_, %{ids: ids}, _) do
    Rujira.Enum.reduce_async_while_ok(ids, &resolve_id/1)
  end

  # ===== Type Resolution =====
  # Maps Elixir structs to their corresponding GraphQL type names

  # Core Types
  def type(%Accounts.Account{}, _), do: :account
  def type(%Accounts.Layer1{}, _), do: :layer_1_account
  def type(%Assets.Asset{}, _), do: :asset
  def type(%Bank.Supply{}, _), do: :bank_supply
  def type(%Contracts.Contract{}, _), do: :contract

  # Bow Protocol
  def type(%Bow.Account{}, _), do: :bow_account
  def type(%Bow.Xyk{}, _), do: :bow_pool_xyk

  # Merge Protocol
  def type(%Merge.Account{}, _), do: :merge_account
  def type(%Merge.Pool{}, _), do: :merge_pool

  # FIN Protocol
  def type(%Fin.Pair{}, _), do: :fin_pair
  def type(%Fin.Book{}, _), do: :fin_book
  def type(%Fin.Trade{}, _), do: :fin_trade
  def type(%Fin.Candle{}, _), do: :fin_candle
  def type(%Fin.Order{}, _), do: :fin_order

  # Staking
  def type(%Staking.Account{}, _), do: :staking_account
  def type(%Staking.Pool{}, _), do: :staking_pool
  def type(%Staking.Pool.Status{}, _), do: :staking_status
  def type(%Staking.Pool.Summary{}, _), do: :staking_summary

  # Leagues
  def type(%Leagues.Account{}, _), do: :league_account

  # Prices & Market Data
  def type(%Prices.Price{}, _), do: :price

  # Index Module
  def type(%Index.Account{}, _), do: :index_account
  def type(%Index.Vault{}, _), do: :index_vault

  # Thorchain Integration
  def type(%Thorchain.Tor.Candle{}, _), do: :thorchain_tor_candle

  def type(%Thorchain.Types.QueryLiquidityProviderResponse{}, _),
    do: :thorchain_liquidity_provider

  def type(%Thorchain.Types.QueryInboundAddressResponse{}, _), do: :thorchain_inbound_address
  def type(%Thorchain.Types.QueryPoolResponse{}, _), do: :thorchain_pool
  def type(%{observed_tx: _}, _), do: :thorchain_tx_in
  def type(%Thorchain.Oracle{}, _), do: :thorchain_oracle

  # ===== ID Resolution =====
  # Resolves GraphQL global IDs to their associated Elixir domain entities

  # Entrypoint for global ID resolution
  defp resolve_id(id) when is_binary(id),
    do: resolve_id(Absinthe.Relay.Node.from_global_id(id, RujiraWeb.Schema))

  # --- Core Accounts ---
  defp resolve_id({:ok, %{type: :account, id: id}}), do: Accounts.from_id(id)
  defp resolve_id({:ok, %{type: :layer_1_account, id: id}}), do: Accounts.layer_1_from_id(id)

  # --- Assets & Contracts ---
  defp resolve_id({:ok, %{type: :asset, id: id}}), do: Assets.from_id(id)
  defp resolve_id({:ok, %{type: :contract, id: id}}), do: Contracts.from_id(id)

  # --- Bow Module ---
  defp resolve_id({:ok, %{type: :bow_pool, id: id}}), do: Bow.pool_from_id(id)
  defp resolve_id({:ok, %{type: :bow_pool_xyk, id: id}}), do: Bow.pool_from_id(id)
  defp resolve_id({:ok, %{type: :bow_account, id: id}}), do: Bow.account_from_id(id)

  # --- Merge Module ---
  defp resolve_id({:ok, %{type: :merge_account, id: id}}), do: Merge.account_from_id(id)
  defp resolve_id({:ok, %{type: :merge_pool, id: id}}), do: Merge.pool_from_id(id)

  # --- Fin Module ---
  defp resolve_id({:ok, %{type: :fin_pair, id: id}}), do: Fin.pair_from_id(id)
  defp resolve_id({:ok, %{type: :fin_book, id: id}}), do: Fin.book_from_id(id)
  defp resolve_id({:ok, %{type: :fin_candle, id: id}}), do: Fin.candle_from_id(id)
  defp resolve_id({:ok, %{type: :fin_order, id: id}}), do: Fin.order_from_id(id)
  defp resolve_id({:ok, %{type: :fin_trade, id: id}}), do: Fin.trade_from_id(id)

  # --- Prices & Bank ---
  defp resolve_id({:ok, %{type: :price, id: id}}), do: Prices.price_from_id(id)
  defp resolve_id({:ok, %{type: :bank_supply, id: id}}), do: Bank.supply(id)

  # --- Staking ---
  defp resolve_id({:ok, %{type: :staking_pool, id: id}}), do: Staking.pool_from_id(id)
  defp resolve_id({:ok, %{type: :staking_account, id: id}}), do: Staking.account_from_id(id)
  defp resolve_id({:ok, %{type: :staking_status, id: id}}), do: Staking.status_from_id(id)
  defp resolve_id({:ok, %{type: :staking_summary, id: id}}), do: Staking.summary_from_id(id)

  # --- Thorchain ---
  defp resolve_id({:ok, %{type: :thorchain_liquidity_provider, id: id}}),
    do: Thorchain.liquidity_provider_from_id(id)

  defp resolve_id({:ok, %{type: :thorchain_pool, id: id}}),
    do: Thorchain.pool_from_id(id)

  defp resolve_id({:ok, %{type: :thorchain_inbound_address, id: id}}),
    do: Resolvers.Thorchain.inbound_address(id)

  defp resolve_id({:ok, %{type: :thorchain_tx_in, id: id}}),
    do: Thorchain.tx_in(id)

  defp resolve_id({:ok, %{type: :thorchain_oracle, id: id}}),
    do: Thorchain.oracle_from_id(id)

  defp resolve_id({:ok, %{type: :thorchain_tor_candle, id: id}}),
    do: Thorchain.Tor.candle_from_id(id)

  # --- League ---
  defp resolve_id({:ok, %{type: :league_account, id: id}}),
    do: Leagues.account_from_id(id)

  # --- Deprecated / Aliases (TODO: remove once UIs migrate) ---
  defp resolve_id({:ok, %{type: :inbound_address, id: id}}),
    do: Resolvers.Thorchain.inbound_address(id)

  defp resolve_id({:ok, %{type: :pool, id: id}}),
    do: Thorchain.pool_from_id(id)

  defp resolve_id({:ok, %{type: :tx_in, id: id}}),
    do: Thorchain.tx_in(id)

  # --- Index Module ---
  defp resolve_id({:ok, %{type: :index_vault, id: id}}),
    do: Index.index_from_id(id)

  defp resolve_id({:ok, %{type: :index_account, id: id}}),
    do: Index.account_from_id(id)

  # --- Fallback Error Case ---
  defp resolve_id({:error, error}), do: {:error, error}

  # ===== Helper Functions =====

  @doc """
  Encodes a local ID and type into a global ID.

  ## Parameters
    * `node_name` - The type of the node (e.g., :account, :asset)
    * `id` - The local ID to encode

  Returns a base64-encoded global ID string.
  """
  def encode_id(node_name, id) do
    Absinthe.Relay.Node.to_global_id(node_name, id, RujiraWeb.Schema)
  end

  @doc """
  Returns a list of supported Relay node types and their expected ID formats.

  Each type follows the format `type:id`, where `id` varies per domain. This allows
  clients to correctly construct global IDs for fetching nodes via Relay.

  Groups are divided by functional domains for clarity.
  """
  def supported_node_types(_, _, _) do
    {:ok,
     [
       # --- Core Types ---
       %{type: "Account", format: "account_address"},
       %{type: "Layer1Account", format: "chain:account_address"},

       # --- Assets & Contracts ---
       %{type: "Asset", format: "id"},
       %{type: "Contract", format: "contract_address"},

       # --- Bow Protocol ---
       %{type: "BowAccount", format: "account_address/denom"},
       %{type: "BowPool", format: "pool_address"},
       %{type: "BowPoolXyk", format: "pool_address"},

       # --- Merge Protocol ---
       %{type: "MergeAccount", format: "pool_address/account_address"},
       %{type: "MergePool", format: "pool_address"},

       # --- FIN Protocol ---
       %{type: "FinPair", format: "pair_address"},
       %{type: "FinBook", format: "pair_address"},
       %{type: "FinCandle", format: "pair_address/resolution/bin"},
       %{type: "FinOrder", format: "pair_address/side/price/owner_address"},
       %{type: "FinTrade", format: ""},

       # --- Staking ---
       %{type: "StakingPool", format: "pool_address"},
       %{type: "StakingAccount", format: "pool_address/account_address"},
       %{type: "StakingStatus", format: "pool_address"},
       %{type: "StakingSummary", format: "pool_address"},

       # --- Thorchain ---
       %{type: "ThorchainLiquidityProvider", format: ""},
       %{type: "ThorchainPool", format: "asset_id"},
       %{type: "ThorchainInboundAddress", format: ""},
       %{type: "ThorchainTxIn", format: ""},
       %{type: "ThorchainOracle", format: ""},
       %{type: "ThorchainTorCandle", format: "asset_id/resolution/bin"},

       # --- League ---
       %{type: "LeagueAccount", format: "league/season/account_address"},

       # --- Index ---
       %{type: "IndexAccount", format: "account_address/denom"},
       %{type: "IndexVault", format: "vault_address"},

       # --- Prices & Market Data ---
       %{type: "Price", format: "symbol"},

       # --- Deprecated / Aliases (to be removed) ---
       %{type: "InboundAddress", format: ""},
       %{type: "Pool", format: ""},
       %{type: "TxIn", format: ""}
     ]}
  end
end
