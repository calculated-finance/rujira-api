defmodule Rujira.Ventures do
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
end
