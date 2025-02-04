defmodule RujiraWeb.Resolvers.Node do
  alias Rujira.Assets
  alias Rujira.Accounts
  alias Rujira.Merge
  alias Rujira.Fin
  alias Rujira.Staking

  def id(%{id: encoded_id}, _) do
    decode_id(encoded_id)
  end

  def list(_, %{ids: ids}, _) do
    Enum.reduce(ids, {:ok, []}, fn id, agg ->
      with {:ok, agg} <- agg,
           {:ok, id} <- decode_id(id) do
        {:ok, [id | agg]}
      end
    end)
  end

  def type(%Accounts.Account{}, _), do: :account
  def type(%Accounts.Layer1{}, _), do: :layer_1_account
  def type(%Assets.Asset{}, _), do: :asset
  def type(%Merge.Pool{}, _), do: :merge_pool
  def type(%Fin.Pair{}, _), do: :fin_pair
  def type(%Fin.Book{}, _), do: :fin_book
  # def type(%Fin.Trade{}, _), do: :fin_trade
  def type(%Fin.Candle{}, _), do: :fin_candle
  def type(%Fin.Order{}, _), do: :fin_order
  def type(%Staking.Pool{}, _), do: :staking_pool

  defp decode_id(id) do
    case Absinthe.Relay.Node.from_global_id(id, RujiraWeb.Schema) do
      {:ok, %{type: :account, id: id}} ->
        {:ok, %Accounts.Account{id: id, chain: :thor, address: id}}

      {:ok, %{type: :layer_1_account, id: id}} ->
        [chain, address] = String.split(id, ":")
        {:ok, %Accounts.Layer1{id: id, chain: String.to_existing_atom(chain), address: address}}

      {:ok, %{type: :asset, id: id}} ->
        {:ok, Assets.from_string(id)}

      {:ok, %{type: :merge_pool, id: id}} ->
        {:ok, %Merge.Pool{id: id, address: id}}

      {:ok, %{type: :fin_pair, id: id}} ->
        {:ok, %Fin.Pair{id: id, address: id}}

      {:ok, %{type: :fin_book, id: id}} ->
        {:ok, %Fin.Book{id: id}}

      {:ok, %{type: :fin_candle, id: id}} ->
        {:ok, %Fin.Candle{id: id}}

      {:ok, %{type: :fin_order, id: id}} ->
        Fin.order_from_id(id)

      {:ok, %{type: :staking_pool, id: id}} ->
        {:ok, %Staking.Pool{id: id, address: id}}

      {:error, error} ->
        {:error, error}
    end
  end

  def encode_id(node_name, id),
    do: Absinthe.Relay.Node.to_global_id(node_name, id, RujiraWeb.Schema)
end
