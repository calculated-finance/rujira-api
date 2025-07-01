defmodule Rujira.Balances do
  @moduledoc """
  Handles blockchain balance queries and UTXO management.
  """
  alias Rujira.Assets.Asset
  use GenServer

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Listener], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Fetches the balances of THORChain supported assets on native chains, with the correct Asset string for THORChain usage
  """
  @spec balances(atom(), String.t()) ::
          {:ok, list(%{asset: Asset.t(), amount: String.t()})} | {:error, any()}
  def balances(chain, address) do
    with {:ok, module} <- Rujira.Chains.get_native_adapter(chain),
         assets <- Rujira.Assets.erc20(chain) do
      module.balances(address, assets)
    end
  end

  @spec utxos(atom(), String.t()) ::
          {:ok, nil | list(map())} | {:error, any()}
  def utxos(chain, address) do
    with {:ok, module} <- Rujira.Chains.get_native_adapter(chain) do
      if Kernel.function_exported?(module, :utxos, 1) do
        module.utxos(address)
      else
        {:ok, nil}
      end
    end
  end

  def flatten(list) do
    list
    |> Enum.reduce({[], MapSet.new()}, fn %{amount: amount, asset: asset}, {acc, seen} ->
      if MapSet.member?(seen, asset) do
        # Asset already seen - update the existing entry
        {Enum.map(acc, fn
           %{asset: ^asset} = item -> %{item | amount: item.amount + amount}
           item -> item
         end), seen}
      else
        # First time seeing this asset - add to accumulator and mark as seen
        {acc ++ [%{amount: amount, asset: asset}], MapSet.put(seen, asset)}
      end
    end)
    |> elem(0)
  end
end
