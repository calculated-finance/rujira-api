defmodule Rujira.Calc.Common.SwapAmountAdjustment do
  @moduledoc false
  alias Rujira.Assets.Coin

  defmodule LinearScalar do
    @moduledoc false
    defstruct base_receive_amount: Coin.default(),
              minimum_swap_amount: Coin.default(),
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
    with {:ok, base_receive_amount} <- Coin.parse(base_receive_amount),
         {:ok, minimum_swap_amount} <- Coin.parse(minimum_swap_amount) do
      {:ok,
       %LinearScalar{
         base_receive_amount: base_receive_amount,
         minimum_swap_amount: minimum_swap_amount,
         scalar: scalar
       }}
    end
  end

  def from_config(%{"fixed" => _}) do
    {:ok, %Fixed{}}
  end
end
