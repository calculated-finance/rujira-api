defmodule Rujira.Prices.Price do
  @moduledoc """
  Defines the structure for price data.
  """

  defstruct [:id, :source, :current, :change_day, :mcap, :timestamp]
end
