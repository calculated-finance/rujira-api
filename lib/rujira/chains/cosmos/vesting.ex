defmodule Rujira.Chains.Cosmos.Vesting do
  @moduledoc """
  Handles periodic vesting account operations for the Cosmos blockchain.

  This module provides functionality to query and process periodic vesting account data,
  including vesting schedules and unlockable amounts. It interfaces with the Cosmos SDK's
  auth and vesting modules to fetch and deserialize vesting account information.
  """
  alias Cosmos.Auth.V1beta1.Query.Stub
  alias Cosmos.Vesting.V1beta1.PeriodicVestingAccount
  alias Protobuf.Decoder

  defstruct [:start_time, :vesting_periods]

  def get_vesting_account(address, conn) do
    with {:ok, %{account: %{value: value, type_url: type_url}}} <-
           Stub.account(conn, %Cosmos.Auth.V1beta1.QueryAccountRequest{
             address: address
           }) do
      if type_url == "/cosmos.vesting.v1beta1.PeriodicVestingAccount" do
        account = Decoder.decode(value, PeriodicVestingAccount)
        {:ok, serialize_account(account)}
      else
        {:ok, nil}
      end
    end
  end

  def serialize_account(%PeriodicVestingAccount{
        start_time: start_time,
        vesting_periods: vesting_periods
      }) do
    with {:ok, start_time} <- DateTime.from_unix(start_time) do
      vesting_periods =
        serialize_vesting_period(start_time, vesting_periods, [])

      %__MODULE__{
        start_time: start_time,
        vesting_periods: vesting_periods
      }
    end
  end

  def serialize_vesting_period(start_time, [period | rest], collection) do
    with end_time <- DateTime.add(start_time, period.length, :second) do
      serialize_vesting_period(
        end_time,
        rest,
        collection ++
          [
            %{
              end_time: end_time,
              balances: period.amount
            }
          ]
      )
    end
  end

  def serialize_vesting_period(_, [], collection), do: collection
end
