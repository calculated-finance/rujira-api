defmodule Rujira.Index.NavBin do
    alias Rujira.Resolution
    alias Rujira.Index
    import Ecto.Changeset
    require Logger
    use Ecto.Schema
    use GenServer

    @type t :: %__MODULE__{
            id: String.t(),
            contract: String.t(),
            resolution: String.t(),
            bin: DateTime.t(),
            open: Decimal.t(),
            inserted_at: DateTime.t(),
            updated_at: DateTime.t()
          }

    @primary_key false
    schema "index_nav_bins" do
      field :id, :string

      field :contract, :string, primary_key: true
      field :resolution, :string, primary_key: true
      field :bin, :utc_datetime, primary_key: true

      field :open, :decimal

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
          Index.insert_nav_bin(time, resolution)

          time = Resolution.add(time, resolution)
          delay = max(0, DateTime.diff(time, now, :millisecond))
          Process.send_after(self(), time, delay)
          {:noreply, resolution}
      end
    end

    def id(contract, resolution, bin), do: "#{contract}/#{resolution}/#{DateTime.to_iso8601(bin)}"

    @doc false
    def changeset(candle, attrs) do
      candle
      |> cast(attrs, [:id, :contract, :resolution, :bin, :open])
      |> validate_required([:id, :contract, :resolution, :bin, :open])
    end
end
