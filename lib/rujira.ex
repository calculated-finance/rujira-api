defmodule Rujira do
  @moduledoc """
  Rujira keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  # UTILS MUST BE SOMEWHERE ElSE
  def parse_timestamp(nanoseconds) when is_binary(nanoseconds) do
    with nanoseconds <- String.to_integer(nanoseconds),
         seconds <- div(nanoseconds, 1_000_000_000),
         {:ok, date_time} <- DateTime.from_unix(seconds) do
      {:ok, date_time}
    end
  end
end
