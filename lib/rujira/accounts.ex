defmodule Rujira.Accounts do
  alias Rujira.Accounts.Account
  alias Rujira.Accounts.Layer1

  def layer_1_from_id(id) do
    [chain, address] = String.split(id, ":")
    {:ok, %Layer1{id: id, chain: String.to_existing_atom(chain), address: address}}
  end

  def from_id(id) do
    {:ok, %Account{id: id, chain: :thor, address: id}}
  end
end
