defmodule Thorchain.Tor.Candle do
  @moduledoc """
  Defines the schema and behavior for Thorchain TOR candles.

  This module handles the storage and updating of TOR candle data, which represents
  price movements of assets over time. It uses a GenServer for periodic updates.
  """
  alias Rujira.Resolution
  import Ecto.Changeset
  require Logger
  use Ecto.Schema
  use GenServer

  @type t :: %__MODULE__{
          id: String.t(),
          asset: String.t(),
          resolution: String.t(),
          bin: DateTime.t(),
          close: Decimal.t(),
          high: Decimal.t(),
          low: Decimal.t(),
          open: Decimal.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  schema "thorchain_tor_candles" do
    field :id, :string

    field :asset, :string, primary_key: true
    field :resolution, :string, primary_key: true
    field :bin, :utc_datetime, primary_key: true

    field :close, :decimal
    field :high, :decimal
    field :low, :decimal
    field :open, :decimal
    field :volume, :integer, virtual: true, default: 0

    timestamps(type: :utc_datetime_usec)
  end

  def start_link(resolution) do
    GenServer.start_link(__MODULE__, resolution)
  end

  @impl true
  def init(resolution) do
    next =
      DateTime.utc_now()
      |> Resolution.truncate(resolution)
      |> Resolution.add(resolution)

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
        Thorchain.Tor.insert_candles(time, resolution)
        time = Resolution.add(time, resolution)
        delay = max(0, DateTime.diff(time, now, :millisecond))
        Process.send_after(self(), time, delay)
        {:noreply, resolution}
    end
  end

  def id(asset, resolution, bin), do: "#{asset}/#{resolution}/#{DateTime.to_iso8601(bin)}"

  @doc false
  def changeset(candle, attrs) do
    candle
    |> cast(attrs, [:id, :asset, :resolution, :bin, :high, :low, :open, :close, :volume])
    |> validate_required([:id, :asset, :resolution, :bin, :high, :low, :open, :close, :volume])
  end
end
