defmodule Rujira.Assets.Coin do
  @moduledoc false
  defstruct denom: "", amount: 0

  def default, do: %__MODULE__{}

  def parse(%{"denom" => denom, "amount" => amount}) do
    {:ok, %__MODULE__{denom: denom, amount: amount}}
  end

  def parse(nil), do: {:ok, nil}
end
