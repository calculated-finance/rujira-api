defmodule Rujira.Events do
  @schema RujiraWeb.Schema
  @endpoint RujiraWeb.Endpoint

  def publish_node(type, id) do
    id = Absinthe.Relay.Node.to_global_id(type, id, @schema)
    Absinthe.Subscription.publish(@endpoint, %{id: id}, node: id)
  end

  def publish_edge(type, prefix, id) do
    id = Absinthe.Relay.Node.to_global_id(type, id, @schema)
    prefix = Absinthe.Relay.Node.to_global_id(type, prefix, @schema)
    Absinthe.Subscription.publish(@endpoint, %{id: id}, node: id, edge: prefix)
  end
end
