defmodule Thorchain.Oracle do
  @moduledoc """
  Module defining the Oracle struct for Thorchain price oracle data.
  """
  defstruct [:id, :asset, :price]
end
