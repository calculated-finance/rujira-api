defmodule Rujira.Events do
  def publish_node(type, id) do
    id = Absinthe.Relay.Node.to_global_id(type, id, RujiraWeb.Schema)
    Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
  end

  def publish_edge(type, prefix, id) do
    id = Absinthe.Relay.Node.to_global_id(type, id, RujiraWeb.Schema)
    prefix = Absinthe.Relay.Node.to_global_id(type, prefix, RujiraWeb.Schema)
    Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id, edge: prefix)
  end
end
