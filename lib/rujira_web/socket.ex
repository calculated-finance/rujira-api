defmodule RujiraWeb.Socket do
  @moduledoc """
  WebSocket handler for real-time communication with the Rujira frontend.

  This module implements the Phoenix Socket behavior and integrates with Absinthe
  to provide GraphQL subscriptions and real-time updates to connected clients.
  """
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: RujiraWeb.Schema

  def id(_) do
    nil
  end

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end
end
