defmodule RujiraWeb.Resolvers.Vestings do
  @moduledoc """
  Handles GraphQL resolution for Vesting-related queries.
  """
  alias Absinthe.Relay
  alias Rujira.Assets
  alias Rujira.Prices
  alias Rujira.Vestings

  def resolver(_, args, _) do
    creator = Map.get(args, :creator)

    with {:ok, vestings} <- Vestings.list_vestings(creator) do
      vestings
      |> Enum.sort_by(& &1.creator)
      |> Relay.Connection.from_list(args)
    end
  end

  def accounts(%{address: address}, _, _) do
    Vestings.load_account(address)
  end

  def value_usd(vestings) do
    Enum.reduce(vestings, 0, fn %{denom: denom, remaining: remaining}, acc ->
      with {:ok, asset} <- Assets.from_denom(denom) do
        acc + Prices.value_usd(asset.symbol, remaining)
      end
    end)
  end
end
