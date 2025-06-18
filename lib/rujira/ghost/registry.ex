defmodule Rujira.Ghost.Registry do
  defstruct [:id, :checksum, :code_id]

  @type t :: %__MODULE__{
          id: String.t(),
          checksum: String.t(),
          code_id: non_neg_integer()
        }

  def from_config(address, %{"checksum" => checksum, "code_id" => code_id}) do
    {:ok, %__MODULE__{id: address, checksum: checksum, code_id: code_id}}
  end

  def init_msg(%{"code_id" => code_id, "checksum" => checksum}) do
    %{
      code_id: code_id,
      checksum: checksum
    }
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(_, _), do: "rujira-ghost-registry"
end
