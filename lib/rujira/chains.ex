defmodule Rujira.Chains do
  use GenServer

  def start_link(_) do
    Supervisor.start_link(
      [
        __MODULE__.Eth
        # __MODULE__.Gaia
      ],
      strategy: :one_for_one
    )
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  alias __MODULE__.Adapter
  @spec get_native_adapter(atom()) :: {:ok, Adapter.t()} | {:error, any()}
  def get_native_adapter(chain) do
    try do
      name = chain |> Atom.to_string() |> String.capitalize()
      module = Module.concat([__MODULE__, name])
      {:ok, struct(module, [])}
    catch
      _ ->
        {:error, "no adapter for #{chain}"}
    end
  end
end
