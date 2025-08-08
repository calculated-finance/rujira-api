defmodule Rujira.Keiko.TokenomicsConfig do
  @moduledoc """
  This module handles the parsing and validation of tokenomics-related configuration
  parameters for Rujira's Keiko deployment orchestrator.

  """

  defstruct [:min_liquidity]
  @type t :: %__MODULE__{min_liquidity: Decimal.t()}

  def from_query(%{"minimum_liquidity_one_side" => min_liquidity}) do
    with {min_liquidity, ""} <- Decimal.parse(min_liquidity) do
      {:ok, %__MODULE__{min_liquidity: min_liquidity}}
    end
  end
end
