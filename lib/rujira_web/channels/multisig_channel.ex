defmodule RujiraWeb.MultisigChannel do
  use Phoenix.Channel
  alias RujiraWeb.Presence

  def join("multisig:new:" <> _id, %{"key" => key}, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :key, key)}
  end

  def join(
        "multisig:sign:" <> _address,
        %{"key" => key, "sign_response" => sign_response},
        socket
      ) do
    send(self(), :after_join)
    {:ok, socket |> assign(:key, key) |> assign(:sign_response, sign_response)}
  end

  def handle_info(:after_join, %{assigns: %{key: key}} = socket) do
    {:ok, _} = Presence.track(socket, key, %{})
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_info(:after_join, %{assigns: %{sign_response: sign_response, key: key}} = socket) do
    {:ok, _} = Presence.track(socket, key, %{sign_response: sign_response})
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
