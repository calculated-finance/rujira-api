defmodule Rujira.Fin.Candle do
  alias Rujira.Fin.TradingView
  alias Rujira.Fin
  import Ecto.Changeset
  require Logger
  use Ecto.Schema
  use GenServer

  def start_link(resolution) do
    GenServer.start_link(__MODULE__, resolution)
  end

  @impl true
  def init(resolution) do
    next =
      DateTime.utc_now()
      |> TradingView.truncate(resolution)
      |> TradingView.add(resolution)

    send(self(), next)
    {:ok, resolution}
  end

  @impl true
  def handle_info(time, resolution) do
    now = DateTime.utc_now()

    case DateTime.compare(time, now) do
      :gt ->
        now = DateTime.utc_now()
        delay = max(0, DateTime.diff(time, now, :millisecond))
        Process.send_after(self(), time, delay)
        {:noreply, resolution}

      _ ->
        Logger.debug("#{__MODULE__} #{resolution} #{time}")
        Fin.insert_candles(time, resolution)

        time = TradingView.add(time, resolution)
        delay = max(0, DateTime.diff(time, now, :millisecond))
        Process.send_after(self(), time, delay)
        {:noreply, resolution}
    end
  end

  @primary_key false
  schema "candles" do
    field :id, :string

    field :contract, :string, primary_key: true
    field :resolution, :string, primary_key: true
    field :bin, :utc_datetime, primary_key: true

    field :close, :decimal
    field :high, :decimal
    field :low, :decimal
    field :open, :decimal
    field :volume, :integer

    timestamps(type: :utc_datetime_usec)
  end

  def id(contract, resolution, bin), do: "#{contract}/#{resolution}/#{DateTime.to_iso8601(bin)}"

  @doc false
  def changeset(candle, attrs) do
    candle
    |> cast(attrs, [:id, :contract, :resolution, :bin, :high, :low, :open, :close, :volume])
    |> validate_required([:id, :contract, :resolution, :bin, :high, :low, :open, :close, :volume])
  end
end
