defmodule RujiraWeb.Resolvers.Fin do
  alias Rujira.Fin
  alias Absinthe.Resolution.Helpers

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, pair} <- Rujira.Fin.get_pair(address) do
        {:ok, put_id(pair)}
      end
    end)
  end

  def account(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, orders} <- Rujira.Fin.list_all_orders(address),
           {:ok, history} <- Rujira.Fin.account_history(address) do
        {:ok, %{orders: orders, history: history}}
      end
    end)
  end

  defp put_id(%{address: address} = pair) do
    %{pair | id: RujiraWeb.Resolvers.Node.encode_id(:contract, :fin, address)}
  end
end
