defmodule Rujira.Calc.Strategy do
  @moduledoc """
  Single strategy instantiated from Rujira.Calc.Manager.
  """

  defmodule Config do
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
      with {:ok, nodes} <- Rujira.Enum.reduce_while_ok(nodes, &parse_node/1) do
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

  defstruct [
    :idx,
    :source,
    :owner,
    :address,
    :created_at,
    :updated_at,
    :label,
    :status,
    :config
  ]

  @type t :: %__MODULE__{
          idx: integer(),
          source: String.t() | nil,
          owner: String.t(),
          address: String.t(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          label: String.t(),
          status: :active | :paused,
          config: Config.t() | :not_loaded
        }

  def from_query(
        %{
          "id" => id,
          "owner" => owner,
          "contract_address" => contract_address,
          "created_at" => created_at,
          "updated_at" => updated_at,
          "label" => label,
          "status" => status
        } = map
      ) do
    with {:ok, status} <- parse_status(status),
         {created_at, ""} <- Integer.parse(created_at),
         {updated_at, ""} <- Integer.parse(updated_at),
         {:ok, created_at} <- DateTime.from_unix(created_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at) do
      source = Map.get(map, "source", nil)

      {:ok,
       %__MODULE__{
         idx: id,
         source: source,
         owner: owner,
         address: contract_address,
         created_at: created_at,
         updated_at: updated_at,
         label: label,
         status: status,
         config: :not_loaded
       }}
    end
  end

  def parse_status("active"), do: {:ok, :active}
  def parse_status("paused"), do: {:ok, :paused}
  def parse_status(_), do: {:error, :invalid_status}
end
