defmodule Rujira.Balances.Listener do
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(
        %{txs: txs, begin_block_events: begin_block_events, end_block_events: end_block_events},
        state
      ) do
    addresses =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)
      |> Enum.concat(begin_block_events)
      |> Enum.concat(end_block_events)
      |> Enum.flat_map(&scan_event/1)
      |> Enum.uniq()

    for a <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")
      # TODO: extract specific denoms
      Memoize.invalidate(Rujira.Chains.Thor, :balance_of, [a, :_])

      Rujira.Events.publish_node(:layer_1_account, "thor:#{a}")
    end

    {:noreply, state}
  end

  defp scan_event(%{attributes: attributes, type: "transfer"}) do
    scan_attributes(attributes)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [_, %{value: recipient, key: "recipient"}, %{value: sender, key: "sender"} | rest],
         collection
       ) do
    scan_attributes(rest, [
      recipient,
      sender | collection
    ])
  end

  # x/wasm doesn't emit sorted events for the transfer when a contract is instantiated.
  defp scan_attributes(
         [%{value: recipient, key: "recipient"}, %{value: sender, key: "sender"} | rest],
         collection
       ) do
    scan_attributes(rest, [
      recipient,
      sender | collection
    ])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection
end
