defmodule Rujira.Index.EntryAdapter do
  defstruct [:address, :quote_denom]

  def from_config(address, %{"quote_denom" => quote_denom}) do
    {:ok,
     %__MODULE__{
       address: address,
       quote_denom: quote_denom
     }}
  end

  def init_msg(msg), do: msg
  def migrate_msg(_from, _to, _), do: %{}
  def init_label(%{"quote_denom" => quote_denom}), do: "nami-index:#{quote_denom}:entry-adapter"
end
