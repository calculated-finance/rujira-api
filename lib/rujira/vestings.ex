defmodule Rujira.Vestings do
  @moduledoc """
  Rujira Vesting Contracts. Powered by DaoDao payroll-factory and vesting contracts.
  """

  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Vestings.Account
  alias Rujira.Vestings.Vesting

  # factory_address is the address of the payroll factory contract used to query vesting contracts
  def factory_address, do: Deployments.get_target(__MODULE__, "payroll-factory").address

  # Fetches and Loads a single vesting account
  # every account has a list of vesting contracts associated with it
  @spec load_account(String.t()) :: {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(account) do
    with {:ok, vestings} <- query_vestings_by_recipient(account),
         {:ok, vestings} <- Rujira.Enum.reduce_async_while_ok(vestings, &load_vesting/1) do
      {:ok, %Account{id: account, address: account, vestings: vestings}}
    end
  end

  def load_vesting(%{"contract" => address, "instantiator" => instantiator}) do
    with {:ok, info} <- query_vesting(address),
         {:ok, vesting} <- Vesting.from_query(address, info) do
      {:ok, %{vesting | creator: instantiator}}
    end
  end

  def list_vestings(nil) do
    with {:ok, vestings} <- query_vestings() do
      Rujira.Enum.reduce_async_while_ok(vestings, &load_vesting/1)
    end
  end

  def list_vestings(creator) when is_list(creator) do
    with {:ok, vestings} <-
           Rujira.Enum.reduce_async_while_ok(creator, &query_vestings_by_instantiator/1) do
      Rujira.Enum.reduce_async_while_ok(vestings, &load_vesting/1)
    end
  end

  def account_from_id(id) do
    load_account(id)
  end

  def vesting_from_id(id) do
    with {:ok, info} <- query_vesting(id),
         {:ok, vesting} <- Vesting.from_query(id, info),
         {:ok, creator} <- query_owner(id) do
      {:ok, %{vesting | creator: creator}}
    end
  end

  defp query_vestings do
    Contracts.query_state_smart(factory_address(), %{
      "list_vesting_contracts" => %{}
    })
  end

  defp query_vestings_by_recipient(account) do
    Contracts.query_state_smart(factory_address(), %{
      "list_vesting_contracts_by_recipient" => %{"recipient" => account}
    })
  end

  defp query_vestings_by_instantiator(account) do
    Contracts.query_state_smart(factory_address(), %{
      "list_vesting_contracts_by_instantiator" => %{"instantiator" => account}
    })
  end

  defp query_vesting(address) do
    Contracts.query_state_smart(address, %{info: %{}})
  end

  defp query_owner(address) do
    Contracts.query_state_smart(address, %{ownership: %{}})
  end
end
