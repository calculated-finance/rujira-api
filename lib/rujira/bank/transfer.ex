defmodule Rujira.Bank.Transfer do
  @moduledoc """
  Listens for token transfer events and persists them to the database.

  This module implements the `Thornode.Observer` behavior to monitor and process
  blockchain transfer events, maintaining a complete history of token transfers
  including sender, recipient, amount, and timestamp.
  """
  use Ecto.Schema
  use Thornode.Observer

  @primary_key false
  schema "bank_transfers" do
    field :height, :integer, primary_key: true
    field :event_idx, :integer, primary_key: true
    field :denom, :string, primary_key: true
    field :sender, :string
    field :recipient, :string
    field :amount, :integer
    field :timestamp, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  @impl true
  def handle_new_block(
        %{
          header: %{time: timestamp, height: height},
          txs: txs,
          begin_block_events: begin_block_events,
          end_block_events: end_block_events
        },
        state
      ) do
    transfers =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)
      |> Enum.concat(begin_block_events)
      |> Enum.concat(end_block_events)
      |> Enum.flat_map(&scan_transfer/1)
      |> Enum.with_index()
      |> Enum.map(fn {transfer, idx} ->
        Map.merge(transfer, %{
          event_idx: idx,
          timestamp: timestamp,
          height: height,
          updated_at: DateTime.utc_now(),
          inserted_at: DateTime.utc_now()
        })
      end)

    Rujira.Repo.insert_all(__MODULE__, transfers, on_conflict: :nothing)

    {:noreply, state}
  end

  defp scan_transfer(%{
         attributes: %{"recipient" => recipient, "sender" => sender, "amount" => amount},
         type: "transfer"
       }) do
    parse_tokens(amount)
    |> Enum.map(&Map.merge(&1, %{recipient: recipient, sender: sender}))
  end

  defp scan_transfer(_), do: []

  defp parse_tokens(input) do
    input
    |> String.split(",")
    |> Enum.map(&parse_token/1)
  end

  defp parse_token(input) do
    [amount, denom] = Regex.run(~r/^(\d+)(.+)$/, input, capture: :all_but_first)
    %{amount: String.to_integer(amount), denom: denom}
  end
end
