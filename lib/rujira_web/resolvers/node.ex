defmodule RujiraWeb.Resolvers.Node do
  alias Rujira.Bow
  alias RujiraWeb.Resolvers
  alias Rujira.Contracts
  alias Rujira.Assets
  alias Rujira.Accounts
  alias Rujira.Bank
  alias Rujira.Merge
  alias Rujira.Fin
  alias Rujira.Staking
  alias Rujira.Leagues
  alias Rujira.Prices

  def id(%{id: encoded_id}, _) do
    resolve_id(encoded_id)
  end

  def list(_, %{ids: ids}, _) do
    Enum.reduce(ids, {:ok, []}, fn id, agg ->
      with {:ok, agg} <- agg,
           {:ok, id} <- resolve_id(id) do
        {:ok, [id | agg]}
      end
    end)
  end

  def type(%Accounts.Account{}, _), do: :account
  def type(%Accounts.Layer1{}, _), do: :layer_1_account
  def type(%Assets.Asset{}, _), do: :asset
  def type(%Bank.Supply{}, _), do: :bank_supply
  def type(%Bow.Account{}, _), do: :bow_account
  def type(%Bow.Xyk{}, _), do: :bow_pool_xyk
  def type(%Contracts.Contract{}, _), do: :contract
  def type(%Merge.Account{}, _), do: :merge_account
  def type(%Merge.Pool{}, _), do: :merge_pool
  def type(%Fin.Pair{}, _), do: :fin_pair
  def type(%Fin.Book{}, _), do: :fin_book
  def type(%Fin.Trade{}, _), do: :fin_trade
  def type(%Fin.Candle{}, _), do: :fin_candle
  def type(%Fin.Order{}, _), do: :fin_order
  def type(%Prices.Price{}, _), do: :price
  def type(%{league: _, season: _, address: _}, _), do: :league_account
  def type(%Staking.Account{}, _), do: :staking_account
  def type(%Staking.Pool{}, _), do: :staking_pool
  def type(%Staking.Pool.Status{}, _), do: :staking_status
  def type(%Staking.Pool.Summary{}, _), do: :staking_summary
  def type(%Thorchain.Tor.Candle{}, _), do: :thorchain_tor_candle

  def type(%Thorchain.Types.QueryLiquidityProviderResponse{}, _),
    do: :thorchain_liquidity_provider

  def type(%Thorchain.Types.QueryInboundAddressResponse{}, _), do: :thorchain_inbound_address
  def type(%Thorchain.Types.QueryPoolResponse{}, _), do: :thorchain_pool
  def type(%{observed_tx: _}, _), do: :thorchain_tx_in
  def type(%Thorchain.Oracle{}, _), do: :thorchain_oracle

  defp resolve_id(id) do
    case Absinthe.Relay.Node.from_global_id(id, RujiraWeb.Schema) do
      {:ok, %{type: :account, id: id}} ->
        Accounts.from_id(id)

      {:ok, %{type: :layer_1_account, id: id}} ->
        Accounts.layer_1_from_id(id)

      {:ok, %{type: :asset, id: id}} ->
        Assets.from_id(id)

      {:ok, %{type: :bow_pool, id: id}} ->
        Bow.pool_from_id(id)

      {:ok, %{type: :bow_pool_xyk, id: id}} ->
        Bow.pool_from_id(id)

      {:ok, %{type: :contract, id: id}} ->
        Contracts.from_id(id)

      {:ok, %{type: :bank_supply, id: id}} ->
        Bank.supply(id)

      {:ok, %{type: :bow_account, id: id}} ->
        Bow.account_from_id(id)

      {:ok, %{type: :merge_account, id: id}} ->
        Merge.account_from_id(id)

      {:ok, %{type: :merge_pool, id: id}} ->
        Merge.pool_from_id(id)

      {:ok, %{type: :fin_pair, id: id}} ->
        Fin.pair_from_id(id)

      {:ok, %{type: :fin_book, id: id}} ->
        Fin.book_from_id(id)

      {:ok, %{type: :fin_candle, id: id}} ->
        Fin.candle_from_id(id)

      {:ok, %{type: :fin_order, id: id}} ->
        Fin.order_from_id(id)

      {:ok, %{type: :fin_trade, id: id}} ->
        Fin.trade_from_id(id)

      {:ok, %{type: :price, id: id}} ->
        Prices.price_from_id(id)

      {:ok, %{type: :staking_pool, id: id}} ->
        Staking.pool_from_id(id)

      {:ok, %{type: :staking_account, id: id}} ->
        Staking.account_from_id(id)

      {:ok, %{type: :staking_status, id: id}} ->
        Staking.status_from_id(id)

      {:ok, %{type: :staking_summary, id: id}} ->
        Staking.summary_from_id(id)

      {:ok, %{type: :thorchain_liquidity_provider, id: id}} ->
        Thorchain.liquidity_provider_from_id(id)

      {:ok, %{type: :thorchain_pool, id: id}} ->
        Thorchain.pool_from_id(id)

      {:ok, %{type: :thorchain_inbound_address, id: id}} ->
        Resolvers.Thorchain.inbound_address(id)

      {:ok, %{type: :thorchain_tx_in, id: id}} ->
        Thorchain.tx_in(id)

      {:ok, %{type: :league_account, id: id}} ->
        Leagues.account_from_id(id)

      {:ok, %{type: :thorchain_oracle, id: id}} ->
        Thorchain.oracle_from_id(id)

      {:ok, %{type: :thorchain_tor_candle, id: id}} ->
        Thorchain.Tor.candle_from_id(id)

      # ---
      # TODO: remove once UIs are using v2
      {:ok, %{type: :inbound_address, id: id}} ->
        Resolvers.Thorchain.inbound_address(id)

      {:ok, %{type: :pool, id: id}} ->
        Thorchain.pool_from_id(id)

      {:ok, %{type: :tx_in, id: id}} ->
        Thorchain.tx_in(id)

      # ---

      {:error, error} ->
        {:error, error}
    end
  end

  def encode_id(node_name, id),
    do: Absinthe.Relay.Node.to_global_id(node_name, id, RujiraWeb.Schema)
end
