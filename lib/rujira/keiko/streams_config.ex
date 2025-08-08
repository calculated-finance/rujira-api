defmodule Rujira.Keiko.StreamsConfig do
  @moduledoc """
  This module provides the type definition and parsing logic for Rujira Streams contract
  configuration used by the Keiko deployment orchestrator.
  """

  defstruct [:cw1_contract_address, :payroll_factory_contract_address]

  @type t :: %__MODULE__{
          cw1_contract_address: String.t(),
          payroll_factory_contract_address: String.t()
        }

  def from_query(%{
        "cw1_contract_address" => cw1_contract_address,
        "payroll_factory_contract_address" => payroll_factory_contract_address
      }) do
    {:ok,
     %__MODULE__{
       cw1_contract_address: cw1_contract_address,
       payroll_factory_contract_address: payroll_factory_contract_address
     }}
  end
end
