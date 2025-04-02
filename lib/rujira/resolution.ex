defmodule Rujira.Resolution do
  import Ecto.Query

  @resolutions ["1", "3", "5", "15", "30", "60", "120", "180", "240", "1D", "1M", "12M"]
  def resolutions(), do: @resolutions

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

  def shift_from_back(from, period, resolution) do
    case Integer.parse(resolution) do
      {res, ""} ->
        from |> DateTime.add(-period * res, :minute)

      _ ->
        case resolution do
          "1D" -> DateTime.add(from, -period * 1440, :minute)
          "1M" -> DateTime.add(from, -period * 43200, :minute)
          "12M" -> DateTime.add(from, -period * 518_400, :minute)
          _ -> from
        end
    end
  end

  def with_range(q, from, to, "1") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin + '1 minute'::interval * -1 min, bin max from generate_series(?::timestamptz, ?::timestamptz, '1 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "3") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '3 minute' max from generate_series(?::timestamptz, ?::timestamptz, '3 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "5") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '5 minute' max from generate_series(?::timestamptz, ?::timestamptz, '5 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "15") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '15 minute' max from generate_series(?::timestamptz, ?::timestamptz, '15 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "30") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '30 minute' max from generate_series(?::timestamptz, ?::timestamptz, '30 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "60") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '60 minute' max from generate_series(?::timestamptz, ?::timestamptz, '60 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "120") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '120 minute' max from generate_series(?::timestamptz, ?::timestamptz, '120 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "180") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '180 minute' max from generate_series(?::timestamptz, ?::timestamptz, '180 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "240") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '240 minute' max from generate_series(?::timestamptz, ?::timestamptz, '240 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "1D") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '1 day' max from generate_series(?::timestamptz, ?::timestamptz, '1 day') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "1M") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '1 month' max from generate_series(?::timestamptz, ?::timestamptz, '1 month') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "12M") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '1 year' max from generate_series(?::timestamptz, ?::timestamptz, '1 year') bin",
          ^from,
          ^to
        )
    )
  end
end
