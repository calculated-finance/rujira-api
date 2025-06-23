defmodule Rujira.Contracts.Listener do
  @moduledoc """
  Listens for and processes smart contract-related blockchain events.

  Handles block transactions to detect contract interactions, updates cached data,
  and publishes real-time updates through the events system.

  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, state) do
    txs
    |> Enum.flat_map(fn
      %{result: %{events: xs}} when is_list(xs) -> xs
      _ -> []
    end)
    |> Enum.map(&scan_contract_event/1)
    |> Enum.reject(&is_nil/1)
    |> Rujira.Enum.uniq()
    |> Enum.each(&invalidate/1)

    {:noreply, state}
  end

  defp scan_contract_event(%{
         type: "message",
         attributes: attrs
       }) do
    action = Map.get(attrs, "action")

    case action do
      "/cosmwasm.wasm.v1.MsgStoreCode" ->
        {Rujira.Contracts, :codes}

      "/cosmwasm.wasm.v1.MsgInstantiateContract" ->
        {Rujira.Contracts, :by_code, [Map.get(attrs, "code_id")]}

      _ ->
        nil
    end
  end

  defp scan_contract_event(_), do: nil

  defp invalidate({module, function, args}) do
    Logger.debug("#{__MODULE__} invalidating #{module}.#{function} #{Enum.join(args, ",")}")
    Memoize.invalidate(module, function, args)
  end

  defp invalidate({module, function}) do
    Logger.debug("#{__MODULE__} invalidating #{module}.#{function}")
    Memoize.invalidate(module, function)
  end
end
