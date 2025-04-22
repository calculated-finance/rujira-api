defmodule Rujira.Ventures do
  alias Rujira.Ventures.Pilot
  alias Rujira.Ventures.Keiko
  alias Rujira.Contract

  @keiko_address Application.compile_env(:rujira, __MODULE__,
                   keiko_address:
                     "sthor1dvg75l42g6r8ze24khnm0k65ahaz8naaczsxvae2u7yze62ufx3qlgy4pm"
                 )
                 |> Keyword.get(:keiko_address)

  def keiko() do
    Contract.get({Keiko, @keiko_address})
  end

  def sales() do
    with {:ok, ventures} <- Contract.query_state_smart(@keiko_address, %{ventures: %{}}) do
      Rujira.Enum.reduce_while_ok(ventures, [], &sale_from_query/1)
    end
  end

  def sales_by_owner(owner) do
    with {:ok, ventures} <-
           Contract.query_state_smart(@keiko_address, %{ventures_by_owner: %{owner: owner}}) do
      Rujira.Enum.reduce_while_ok(ventures, [], &sale_from_query/1)
    end
  end

  def sales_by_status(status) do
    with {:ok, ventures} <-
           Contract.query_state_smart(@keiko_address, %{
             ventures_by_status: %{status: Atom.to_string(status)}
           }) do
      Rujira.Enum.reduce_while_ok(ventures, [], &sale_from_query/1)
    end
  end

  def sale_by_idx(idx) do
    with {:ok, venture} <-
           Contract.query_state_smart(@keiko_address, %{venture: %{idx: idx}}) do
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
    Contract.query_state_smart(@keiko_address, %{validate_token: %{token: token}})
  end

  def validate_tokenomics(token_payload, tokenomics_payload) do
    Contract.query_state_smart(@keiko_address, %{
      validate_tokenomics: %{token: token_payload, tokenomics: tokenomics_payload}
    })
  end

  def validate_venture(venture_payload) do
    Contract.query_state_smart(@keiko_address, %{validate_venture: %{venture: venture_payload}})
  end
end
