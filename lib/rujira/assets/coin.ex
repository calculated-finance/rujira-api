defmodule Rujira.Assets.Coin do
  @moduledoc false
  defstruct [:denom, :amount]

  def parse(%{"denom" => denom, "amount" => amount}) do
    {:ok, %__MODULE__{denom: denom, amount: amount}}
  end

  def parse(nil), do: {:ok, nil}
end
