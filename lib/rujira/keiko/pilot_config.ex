defmodule Rujira.Keiko.PilotConfig do
  @moduledoc """
  This module provides the type definition and parsing logic for Rujira Pilot contract
  configuration used by the Keiko deployment orchestrator.
  """

  defmodule Deposit do
    @moduledoc """
     Deposit is the configuration for the deposited denom and amount in the pilot contract
    """
    defstruct [:denom, :amount]
    @type t :: %__MODULE__{denom: String.t(), amount: non_neg_integer()}

    def from_query(%{"denom" => denom, "amount" => amount}) do
      with {amount, ""} <- Integer.parse(amount) do
        {:ok, %__MODULE__{denom: denom, amount: amount}}
      end
    end
  end

  defmodule BidDenom do
    @moduledoc """
     BidDenom is the configuration for a specific bid denom in the pilot contract
    """
    defstruct [:denom, :min_raise_amount]
    @type t :: %__MODULE__{denom: String.t(), min_raise_amount: non_neg_integer()}

    def from_query(%{"denom" => denom, "min_raise_amount" => min_raise_amount}) do
      with {min_raise_amount, ""} <- Integer.parse(min_raise_amount) do
        {:ok, %__MODULE__{denom: denom, min_raise_amount: min_raise_amount}}
      end
    end
  end

  defstruct [
    :admin,
    :code_id,
    :deposit,
    :fee_address,
    :fee_maker,
    :fee_taker,
    :max_premium,
    :bid_denoms
  ]

  @type t :: %__MODULE__{
          admin: String.t(),
          code_id: non_neg_integer(),
          deposit: Deposit.t(),
          fee_address: String.t(),
          fee_maker: Decimal.t(),
          fee_taker: Decimal.t(),
          max_premium: non_neg_integer(),
          bid_denoms: list(BidDenom.t())
        }

  def from_query(%{
        "admin" => admin,
        "code_id" => code_id,
        "deposit" => deposit,
        "fee_address" => fee_address,
        "fee_maker" => fee_maker,
        "fee_taker" => fee_taker,
        "max_premium" => max_premium,
        "bid_denoms" => bid_denoms
      }) do
    with {:ok, deposit} <- Deposit.from_query(deposit),
         {fee_maker, ""} <- Decimal.parse(fee_maker),
         {fee_taker, ""} <- Decimal.parse(fee_taker),
         {:ok, bid_denoms} <-
           Rujira.Enum.reduce_while_ok(bid_denoms, [], &BidDenom.from_query/1) do
      {:ok,
       %__MODULE__{
         admin: admin,
         code_id: code_id,
         deposit: deposit,
         fee_address: fee_address,
         fee_maker: fee_maker,
         fee_taker: fee_taker,
         max_premium: max_premium,
         bid_denoms: bid_denoms
       }}
    end
  end
end
