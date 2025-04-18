defmodule Rujira.Bank.Transfer do
  use Ecto.Schema
  use GenServer

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

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, nil}
  end

  @impl true
  def handle_info(
        %{
          header: %{time: timestamp, height: height},
          txs: txs,
          begin_block_events: begin_block_events,
          end_block_events: end_block_events
        },
        state
      ) do
    events =
      txs
      |> Enum.flat_map(fn x ->
        case x["result"]["events"] do
          nil -> []
          xs when is_list(xs) -> xs
        end
      end)

    {:ok, timestamp, _} = DateTime.from_iso8601(timestamp)

    transfers =
      begin_block_events
      |> Enum.concat(events)
      |> Enum.concat(end_block_events)
      |> Enum.with_index()
      |> scan_events()
      |> Enum.map(
        &Map.merge(&1, %{
          timestamp: timestamp,
          height: height,
          updated_at: DateTime.utc_now(),
          inserted_at: DateTime.utc_now()
        })
      )

    Rujira.Repo.insert_all(__MODULE__, transfers, on_conflict: :nothing)

    {:noreply, state}
  end

  defp scan_events(attributes, collection \\ [])

  defp scan_events(
         [
           {%{
              "amount" => amount,
              "recipient" => recipient,
              "sender" => sender,
              "type" => "transfer"
            }, idx}
           | rest
         ],
         collection
       ) do
    entries =
      amount
      |> parse_tokens()
      |> Enum.map(&Map.merge(&1, %{event_idx: idx, recipient: recipient, sender: sender}))

    scan_events(rest, collection ++ entries)
  end

  defp scan_events([_ | rest], collection), do: scan_events(rest, collection)
  defp scan_events([], collection), do: collection

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
