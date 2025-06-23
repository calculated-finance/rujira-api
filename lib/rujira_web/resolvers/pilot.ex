defmodule RujiraWeb.Resolvers.Pilot do
  @moduledoc false

  alias Absinthe.Relay

  def account(%{address: address}, _, _) do
    {:ok, %{address: address, bids: nil, history: nil}}
  end

  def bids(_, args, _) do
    Relay.Connection.from_list([], args)
  end
end
