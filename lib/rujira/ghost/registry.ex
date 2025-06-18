defmodule Rujira.Ghost.Registry do
  defstruct [:id]

  @type t :: %__MODULE__{
          id: String.t()
        }

  def init_msg(%{"code_id" => code_id, "checksum" => checksum}) do
    %{
      code_id: code_id,
      checksum: checksum
    }
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(_, _), do: "rujira-ghost-registry"
end
