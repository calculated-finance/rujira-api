defmodule RujiraWeb.Socket do
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: RujiraWeb.Schema

  def id(socket) do
    IO.inspect(socket)
    nil
  end

  def connect(params, socket, _connect_info) do
    IO.inspect(params, label: :connect)
    {:ok, socket}
  end
end
