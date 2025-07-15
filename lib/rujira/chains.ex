defmodule Rujira.Chains do
  @moduledoc """
  Manages blockchain chain adapters and their configurations.
  """
  use GenServer

  def start_link(_) do
    Supervisor.start_link(
      [
        __MODULE__.Avax,
        __MODULE__.Base,
        __MODULE__.Bsc,
        __MODULE__.Eth,
        __MODULE__.Gaia,
        __MODULE__.Noble
        # __MODULE__.Xrp
      ],
      strategy: :one_for_one
    )
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @spec get_native_adapter(atom()) :: {:ok, module()} | {:error, any()}
  def get_native_adapter(chain) when is_atom(chain) do
    name = chain |> Atom.to_string() |> String.capitalize()
    module = Module.concat(__MODULE__, name)

    if Code.ensure_loaded?(module) do
      {:ok, module}
    else
      {:error, "no adapter for #{chain}"}
    end
  end
end
