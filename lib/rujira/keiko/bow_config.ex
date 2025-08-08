defmodule Rujira.Keiko.BowConfig do
  @moduledoc """
  This module provides the type definition and parsing logic for Rujira Bow contract
  configuration used by the Keiko deployment orchestrator.
  """

  defstruct [:admin, :code_id]

  @type t :: %__MODULE__{
          admin: String.t(),
          code_id: non_neg_integer()
        }

  @spec from_query(%{required(String.t()) => any()}) :: {:ok, t()} | :error
  def from_query(%{"admin" => admin, "code_id" => code_id}) do
    {:ok, %__MODULE__{admin: admin, code_id: code_id}}
  end
end
