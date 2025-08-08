defmodule Rujira.Keiko.FinConfig do
  @moduledoc """
  This module provides the type definition and parsing logic for Rujira Fin contract
  configuration used by the Keiko deployment orchestrator.
  """

  defstruct [:admin, :code_id, :fee_address, :fee_maker, :fee_taker]

  @type t :: %__MODULE__{
          admin: String.t(),
          code_id: non_neg_integer(),
          fee_address: String.t(),
          fee_maker: Decimal.t(),
          fee_taker: Decimal.t()
        }

  def from_query(%{
        "admin" => admin,
        "code_id" => code_id,
        "fee_address" => fee_address,
        "fee_maker" => fee_maker,
        "fee_taker" => fee_taker
      }) do
    with {fee_maker, ""} <- Decimal.parse(fee_maker),
         {fee_taker, ""} <- Decimal.parse(fee_taker) do
      {:ok,
       %__MODULE__{
         admin: admin,
         code_id: code_id,
         fee_address: fee_address,
         fee_maker: fee_maker,
         fee_taker: fee_taker
       }}
    end
  end
end
