defmodule Rujira.Calc.Common.Recipient do
  defmodule Bank do
    defstruct address: ""

    @type t :: %__MODULE__{
            address: String.t()
          }
  end

  defmodule Contract do
    defstruct address: "", msg: <<>>

    @type t :: %__MODULE__{
            address: String.t(),
            msg: binary()
          }
  end

  defmodule Deposit do
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
