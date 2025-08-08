defmodule RujiraWeb.Resolvers.Pilot do
  @moduledoc false

  alias Absinthe.Relay
  alias Rujira.Pilot
  alias Rujira.Repo
  alias Rujira.Ventures

  def accounts(%{address: address}, _, _) do
    with {:ok, sales} <- Ventures.load_sales(nil, nil) do
      Rujira.Enum.reduce_async_while_ok(sales, fn
        %{
          venture: %{sale: %{address: sale}}
        }
        when not is_nil(sale) ->
          Pilot.load_account(sale, address)

        _ ->
          :skip
      end)
    end
  end

  def bids_summary(%{account: account, sale: sale}, _, _) do
    Pilot.bids_summary(sale, account)
  end

  def bids(%{account: account, sale: sale}, args, _) do
    with {:ok, bids} <- Pilot.bids(sale, account, nil, nil) do
      Relay.Connection.from_list(bids, args)
    end
  end

  def account_bid_history(%{account: account, sale: sale}, args, _) do
    sale
    |> Pilot.list_account_bid_action_query(account)
    |> Relay.Connection.from_query(&Repo.all/1, args)
  end

  def bid_history(%{address: nil}, args, _), do: Relay.Connection.from_list([], args)

  def bid_history(%{address: address}, args, _) do
    address
    |> Pilot.list_all_bid_actions_query()
    |> Relay.Connection.from_query(&Repo.all/1, args)
  end

  def total_bids(%{address: address}, _, _), do: Pilot.total_bids(address)
end
