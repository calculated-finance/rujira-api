defmodule Rujira.Calc.Action.Distribute do
  @moduledoc """
  Action type for distributing assets to multiple recipients.
  Currently a placeholder implementation.
  """

  defstruct denoms: [],
            destinations: []

  @type t :: %__MODULE__{
          denoms: [String.t()],
          destinations: [Destination.t()]
        }

  def from_config(%{"denoms" => denoms, "destinations" => destinations}) do
    with {:ok, denoms} <- Rujira.Enum.reduce_while_ok(denoms, &Destination.from_config/1) do
      {:ok, %__MODULE__{denoms: denoms, destinations: destinations}}
    end
  end
end
