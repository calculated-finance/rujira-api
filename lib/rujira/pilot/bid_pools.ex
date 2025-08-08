defmodule Rujira.Pilot.BidPools do
  @moduledoc false

  alias Rujira.Pilot.Pool

  defstruct [:id, :pools]

  @type t :: %__MODULE__{
          id: String.t(),
          pools: list(Pool.t())
        }
end
