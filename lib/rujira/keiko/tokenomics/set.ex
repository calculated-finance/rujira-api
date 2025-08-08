defmodule Rujira.Keiko.Tokenomics.Set do
  @moduledoc """
  This module provides the type definition and parsing logic for a Tokenomics set used by the Keiko deployment orchestrator.
  """

  defstruct [:amount]

  @type t :: %__MODULE__{
          amount: non_neg_integer()
        }

  def from_query(%{"amount" => amount}) do
    with {amount, ""} <- Integer.parse(amount) do
      {:ok, %__MODULE__{amount: amount}}
    end
  end
end
