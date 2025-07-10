defmodule Rujira.Events do
  @moduledoc """
  Handles publishing of GraphQL subscription events and real-time updates.
  """
  @schema RujiraWeb.Schema
  @endpoint RujiraWeb.Endpoint

  def publish_node(type, id) do
    id = Absinthe.Relay.Node.to_global_id(type, id, @schema)
    publisher().publish(@endpoint, %{id: id}, node: id)
  end

  def publish_edge(type, prefix, id) do
    id = Absinthe.Relay.Node.to_global_id(type, id, @schema)
    prefix = Absinthe.Relay.Node.to_global_id(type, prefix, @schema)
    publisher().publish(@endpoint, %{id: id}, node: id, edge: prefix)
  end

  def publish(payload, topics) do
    Task.start(fn ->
      publisher().publish(@endpoint, payload, topics)
    end)
  end

  defp publisher do
    :rujira
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:publisher, Absinthe.Subscription)
  end
end
