defmodule Rujira.Balances do
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
end
