defmodule RujiraWeb.Socket do
  use Phoenix.Socket

  channel "multisig:*", RujiraWeb.MultisigChannel

  use Absinthe.Phoenix.Socket,
    schema: RujiraWeb.Schema

  def id(_) do
    nil
  end

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end
end
