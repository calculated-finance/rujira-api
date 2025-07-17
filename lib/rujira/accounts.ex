defmodule Rujira.Accounts do
  @moduledoc """
  Handles account-related operations including address translation and account creation.
  """
  alias Rujira.Accounts.Account
  alias Rujira.Accounts.Layer1

  def layer_1_from_id(id) do
    [chain, address] = String.split(id, ":")

    try do
      {:ok, %Layer1{id: id, chain: String.to_existing_atom(chain), address: address}}
    catch
      {:error, :invalid_chain}
    end
  end

  def from_id(id) do
    {:ok, %Account{id: id, chain: :thor, address: id}}
  end

  # def translate_address("0x" <> address) do
  #   case Base.decode16(address, case: :mixed) do
  #     {:ok, bytes} ->
  #       {:ok, Bech32.encode("thor", bytes)}

  #     _ ->
  #       {:error, :invalid_address}
  #   end
  # end

  def translate_address("thor" <> _ = address), do: {:ok, address}
  def translate_address("sthor" <> _ = address), do: {:ok, address}

  def translate_address(address) do
    case Bech32.decode(address) do
      {:ok, _, bytes} ->
        {:ok, Bech32.encode("thor", bytes)}

      _ ->
        {:error, :invalid_address}
    end
  end
end
