defmodule Rujira.Calc.Common.Recipient do
  @moduledoc """
  Defines recipient types for asset distribution in Calc actions.

  Recipients specify where distributed assets should be sent. Supports bank accounts,
  smart contract calls, and deposit operations with different target mechanisms.
  """

  defmodule Bank do
    @moduledoc "Bank account recipient for direct token transfers."
    defstruct address: ""

    @type t :: %__MODULE__{
            address: String.t()
          }
  end

  defmodule Contract do
    @moduledoc "Smart contract recipient for contract execution with message data."
    defstruct address: "", msg: <<>>

    @type t :: %__MODULE__{
            address: String.t(),
            msg: binary()
          }
  end

  defmodule Deposit do
    @moduledoc "Deposit operation recipient with memo-based routing."
    defstruct memo: ""

    @type t :: %__MODULE__{
            memo: String.t()
          }
  end

  @type t :: Bank.t() | Contract.t() | Deposit.t()

  def default, do: %Deposit{}

  def from_config(%{"bank" => %{"address" => address}}) do
    {:ok, %Bank{address: address}}
  end

  def from_config(%{"contract" => %{"address" => address, "msg" => msg}}) do
    {:ok, %Contract{address: address, msg: msg}}
  end

  def from_config(%{"deposit" => %{"memo" => memo}}) do
    {:ok, %Deposit{memo: memo}}
  end
end
