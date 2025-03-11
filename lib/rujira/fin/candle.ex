defmodule Rujira.Fin.Candle do
  alias Rujira.Fin.TradingView
  use Ecto.Schema
  import Ecto.Changeset

  use GenServer
  require Logger

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
        send(self(), time)
        {:noreply, resolution}

      _ ->
        insert_candles(time, resolution)
        send(self(), TradingView.add(time, resolution))
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

  @doc false
  def changeset(candle, attrs) do
    candle
    |> cast(attrs, [:id, :contract, :resolution, :bin, :high, :low, :open, :close, :volume])
    |> validate_required([:id, :contract, :resolution, :bin, :high, :low, :open, :close, :volume])
  end

  def insert_candles(time, resolution) do
  end
end
