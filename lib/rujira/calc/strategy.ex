defmodule Rujira.Calc.Strategy do
  @moduledoc """
  Single strategy instantiated from Rujira.Calc.Manager.
  """

  alias Rujira.Calc.Action
  alias Rujira.Calc.Condition

  defstruct [:address, :manager, :owner, :nodes]

  @type t :: %__MODULE__{
          address: String.t(),
          manager: String.t(),
          owner: String.t(),
          nodes: [Action.t() | Condition.t()]
        }

  def from_config(address, %{"manager" => manager, "owner" => owner, "nodes" => nodes}) do
    with {:ok, nodes} <- Rujira.Enum.reduce_async_while_ok(nodes, &parse_node/1) do
      {:ok,
       %__MODULE__{
         address: address,
         manager: manager,
         owner: owner,
         nodes: nodes
       }}
    end
  end

  def parse_node(%{"action" => action, "index" => index} = map) do
    next = Map.get(map, "next", nil)

    with {:ok, action} <- Action.from_config(action) do
      {:ok,
       %Action{
         action: action,
         index: index,
         next: next
       }}
    end
  end

  def parse_node(%{"condition" => condition, "index" => index} = map) do
    on_success = Map.get(map, "on_success", nil)
    on_failure = Map.get(map, "on_failure", nil)

    with {:ok, condition} <- Condition.from_config(condition) do
      {:ok,
       %Condition{
         condition: condition,
         index: index,
         on_success: on_success,
         on_failure: on_failure
       }}
    end
  end
end
