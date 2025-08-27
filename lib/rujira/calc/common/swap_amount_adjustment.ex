defmodule Rujira.Calc.Common.SwapAmountAdjustment do
  @moduledoc false
  alias Rujira.Balances.Balance

  defmodule LinearScalar do
    @moduledoc false
    defstruct base_receive_amount: nil,
              minimum_swap_amount: nil,
              scalar: 0.0
  end

  defmodule Fixed do
    @moduledoc false
    defstruct []
  end

  @type t :: LinearScalar.t() | Fixed.t()

  def default, do: %Fixed{}

  def from_config(%{
        "linear_scalar" => %{
          "base_receive_amount" => base_receive_amount,
          "minimum_swap_amount" => minimum_swap_amount,
          "scalar" => scalar
        }
      }) do
    with {:ok, base_receive_amount} <- Balance.parse(base_receive_amount),
         {:ok, minimum_swap_amount} <- Balance.parse(minimum_swap_amount) do
      {:ok,
       %LinearScalar{
         base_receive_amount: base_receive_amount,
         minimum_swap_amount: minimum_swap_amount,
         scalar: scalar
       }}
    end
  end

  def from_config("fixed") do
    {:ok, %Fixed{}}
  end
end
