defmodule Rujira.Ventures do
  @moduledoc false

  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Ventures.Keiko
  alias Rujira.Ventures.Pilot

  def address, do: Deployments.get_target(Keiko, "keiko").address

  def keiko do
    Contracts.get({Keiko, address()})
  end

  def sales do
    with {:ok, ventures} <- Contracts.query_state_smart(address(), %{ventures: %{}}) do
      Rujira.Enum.reduce_while_ok(ventures, [], &sale_from_query/1)
    end
  end

  def sales_by_owner(owner) do
    with {:ok, ventures} <-
           Contracts.query_state_smart(address(), %{ventures_by_owner: %{owner: owner}}) do
      Rujira.Enum.reduce_while_ok(ventures, [], &sale_from_query/1)
    end
  end

  def sales_by_status(status) do
    with {:ok, ventures} <-
           Contracts.query_state_smart(address(), %{
             ventures_by_status: %{status: Atom.to_string(status)}
           }) do
      Rujira.Enum.reduce_while_ok(ventures, [], &sale_from_query/1)
    end
  end

  def sale_by_idx(idx) do
    with {:ok, venture} <-
           Contracts.query_state_smart(address(), %{venture: %{idx: idx}}) do
      # Update if we do Bond sale types later
      sale_from_query(venture)
    end
  end

  defp sale_from_query(%{
         "venture_type" => "pilot",
         "owner" => owner,
         "idx" => idx,
         "status" => status,
         "venture" => %{"pilot" => pilot}
       }),
       do: Pilot.from_query(owner, idx, status, pilot)

  def validate_token(token) do
    Contracts.query_state_smart(address(), %{validate_token: %{token: token}})
  end

  def validate_tokenomics(token_payload, tokenomics_payload) do
    Contracts.query_state_smart(address(), %{
      validate_tokenomics: %{token: token_payload, tokenomics: tokenomics_payload}
    })
  end

  def validate_venture(venture_payload) do
    Contracts.query_state_smart(address(), %{validate_venture: %{venture: venture_payload}})
  end
end
