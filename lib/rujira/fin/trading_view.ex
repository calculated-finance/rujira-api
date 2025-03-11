defmodule Rujira.Fin.TradingView do
  alias Rujira.Fin.Candle
  use GenServer

  @resolutions ["1", "3", "5", "15", "30", "60", "120", "180", "240", "1D", "1M", "12M"]

  def start_link(_) do
    children = Enum.map(@resolutions, &Supervisor.child_spec({Candle, &1}, id: &1))
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def active(now) do
    Enum.map(@resolutions, &{&1, truncate(now, &1)})
  end

  def add(%DateTime{} = datetime, resolution) do
    case Integer.parse(resolution) do
      {minutes, ""} -> DateTime.add(datetime, minutes, :minute)
      {days, "D"} -> DateTime.add(datetime, days, :day)
      {months, "M"} -> Timex.shift(datetime, months: months)
    end
  end

  def truncate(%DateTime{} = datetime, "1") do
    d = DateTime.truncate(datetime, :second)
    %{d | second: 0}
  end

  def truncate(%DateTime{} = datetime, "3"),
    do: datetime |> truncate("1") |> Map.update!(:minute, &(&1 - rem(&1, 3)))

  def truncate(%DateTime{} = datetime, "5"),
    do: datetime |> truncate("1") |> Map.update!(:minute, &(&1 - rem(&1, 5)))

  def truncate(%DateTime{} = datetime, "15"),
    do: datetime |> truncate("1") |> Map.update!(:minute, &(&1 - rem(&1, 15)))

  def truncate(%DateTime{} = datetime, "30"),
    do: datetime |> truncate("1") |> Map.update!(:minute, &(&1 - rem(&1, 30)))

  def truncate(%DateTime{} = datetime, "60"),
    do: datetime |> truncate("1") |> Map.put(:minute, 0)

  def truncate(%DateTime{} = datetime, "120"),
    do: datetime |> truncate("60") |> Map.update!(:hour, &(&1 - rem(&1, 2)))

  def truncate(%DateTime{} = datetime, "180"),
    do: datetime |> truncate("60") |> Map.update!(:hour, &(&1 - rem(&1, 3)))

  def truncate(%DateTime{} = datetime, "240"),
    do: datetime |> truncate("60") |> Map.update!(:hour, &(&1 - rem(&1, 4)))

  def truncate(%DateTime{} = datetime, "1D"),
    do: datetime |> truncate("60") |> Map.put(:hour, 0)

  def truncate(%DateTime{} = datetime, "1M"),
    do: datetime |> truncate("1D") |> Map.put(:day, 1)

  def truncate(%DateTime{} = datetime, "12M"),
    do: datetime |> truncate("1M") |> Map.put(:month, 1)

  def validate(%DateTime{} = datetime, resolution) do
    if truncate(datetime, resolution) == datetime do
      :ok
    else
      {:error, :invalid_bin}
    end
  end
end
