defmodule Rujira.Keiko.Tokenomics.Send do
  @moduledoc """
  This module provides the type definition and parsing logic for a Tokenomics send used by the Keiko deployment orchestrator.
  """

  defstruct [:address, :amount]

  @type t :: %__MODULE__{
          address: String.t(),
          amount: non_neg_integer()
        }

  def from_query(%{"address" => address, "amount" => amount}) do
    with {amount, ""} <- Integer.parse(amount) do
      {:ok, %__MODULE__{address: address, amount: amount}}
    end
  end
end
