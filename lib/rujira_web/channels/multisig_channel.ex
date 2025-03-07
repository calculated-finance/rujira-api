defmodule RujiraWeb.MultisigChannel do
  use Phoenix.Channel
  alias RujiraWeb.Presence

  def join("multisig:new:" <> _id, %{"key" => key}, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :key, key)}
  end

  def join("multisig:sign:" <> _address, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.key, %{})

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
