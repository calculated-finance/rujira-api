defmodule Rujira.Analytics.Common do
  import Ecto.Query

  def shift_from_back(from, period, "1D"), do: DateTime.add(from, -period, :day)

  def shift_from_back(from, period, "1M") do
    m_shift = rem(period, 12)
    y_shift = div(period, 12)

    {year, month} =
      if from.month < m_shift do
        {from.year - y_shift - 1, 12 + from.month - m_shift}
      else
        {from.year - y_shift, from.month - m_shift}
      end

    %{from | year: year, month: month}
  end

  def shift_from_back(from, period, "12M"), do: from |> Map.update!(:year, &(&1 - period))

  def shift_from_back(from, period, resolution),
    do: DateTime.add(from, -period * resolution, :minute)

  def with_range(q, from, to, "1") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin + '1 minute'::interval * -1 min, bin max from generate_series(?::timestamp, ?::timestamp, '1 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "3") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '3 minute' max from generate_series(?::timestamp, ?::timestamp, '3 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "5") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '5 minute' max from generate_series(?::timestamp, ?::timestamp, '5 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "15") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '15 minute' max from generate_series(?::timestamp, ?::timestamp, '15 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "30") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '30 minute' max from generate_series(?::timestamp, ?::timestamp, '30 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "60") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '60 minute' max from generate_series(?::timestamp, ?::timestamp, '60 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "120") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '120 minute' max from generate_series(?::timestamp, ?::timestamp, '120 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "180") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '180 minute' max from generate_series(?::timestamp, ?::timestamp, '180 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "240") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '240 minute' max from generate_series(?::timestamp, ?::timestamp, '240 minute') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "1D") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '1 day' max from generate_series(?::timestamp, ?::timestamp, '1 day') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "1M") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '1 month' max from generate_series(?::timestamp, ?::timestamp, '1 month') bin",
          ^from,
          ^to
        )
    )
  end

  def with_range(q, from, to, "12M") do
    with_cte(q, "bins",
      as:
        fragment(
          "SELECT bin min, bin + '1 year' max from generate_series(?::timestamp, ?::timestamp, '1 year') bin",
          ^from,
          ^to
        )
    )
  end
end
