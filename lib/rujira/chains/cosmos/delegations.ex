defmodule Rujira.Chains.Cosmos.Delegations do
  @moduledoc """
  Handles delegation operations for the Cosmos blockchain.

  This module provides functionality to query and manage delegator delegations,
  including active delegations and unbonding delegations on the Cosmos network.
  It interfaces with the Cosmos SDK's staking module to fetch delegation data.
  """
  alias Cosmos.Staking.V1beta1.QueryDelegatorDelegationsRequest
  alias Cosmos.Staking.V1beta1.QueryDelegatorDelegationsResponse
  alias Cosmos.Staking.V1beta1.QueryDelegatorUnbondingDelegationsRequest
  alias Cosmos.Staking.V1beta1.QueryDelegatorUnbondingDelegationsResponse
  import Cosmos.Staking.V1beta1.Query.Stub
  alias Cosmos.Base.Query.V1beta1.PageRequest

  def get_delegations(delegator_addr, conn), do: delegation_page(conn, delegator_addr)

  def delegation_page(conn, address, pagination \\ %PageRequest{limit: 100})

  def delegation_page(conn, address, %PageRequest{} = pagination) do
    req = %QueryDelegatorDelegationsRequest{delegator_addr: address, pagination: pagination}

    with {:ok,
          %QueryDelegatorDelegationsResponse{
            delegation_responses: delegation_responses,
            pagination: %{next_key: next_key}
          }}
         when next_key != "" <- delegator_delegations(conn, req),
         {:ok, next} <- delegation_page(conn, address, %PageRequest{key: next_key, limit: 100}) do
      {:ok, delegation_responses ++ next}
    else
      {:ok, %QueryDelegatorDelegationsResponse{delegation_responses: delegation_responses}} ->
        {:ok, delegation_responses}
    end
  end

  def get_unbonding_delegations(delegator_addr, conn),
    do: unbonding_delegation_page(conn, delegator_addr)

  def unbonding_delegation_page(conn, address, pagination \\ %PageRequest{limit: 100})

  def unbonding_delegation_page(conn, address, %PageRequest{} = pagination) do
    req = %QueryDelegatorUnbondingDelegationsRequest{
      delegator_addr: address,
      pagination: pagination
    }

    with {:ok,
          %QueryDelegatorUnbondingDelegationsResponse{
            unbonding_responses: unbonding_responses,
            pagination: %{next_key: next_key}
          }}
         when next_key != "" <-
           delegator_unbonding_delegations(conn, req),
         {:ok, next} <-
           unbonding_delegation_page(conn, address, %PageRequest{key: next_key, limit: 100}) do
      {:ok, unbonding_responses ++ next}
    else
      {:ok, %QueryDelegatorUnbondingDelegationsResponse{unbonding_responses: unbonding_responses}} ->
        {:ok, unbonding_responses}
    end
  end
end
