defmodule Rujira.Chains do
  alias __MODULE__.Layer1.Adapter
  @spec get_native_adapter(atom()) :: {:ok, Adapter.t()} | {:error, any()}
  def get_native_adapter(chain) do
    try do
      name = chain |> Atom.to_string() |> String.capitalize()
      module = Module.concat([__MODULE__, :Layer1, name])
      {:ok, struct(module, [])}
    catch
      _ ->
        {:error, "no adapter for #{chain}"}
    end
  end
end
