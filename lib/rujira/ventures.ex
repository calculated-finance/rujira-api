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

  defp sale_from_query(%{
         "venture_type" => "pilot",
         "owner" => owner,
         "status" => status,
         "venture" => %{"pilot" => pilot}
       }),
       do: Pilot.from_query(owner, status, pilot)
end
