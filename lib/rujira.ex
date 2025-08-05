defmodule Rujira do
  @moduledoc """
  Rujira keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def parse_amount_and_denom(str) do
    case Regex.run(~r/^(\d+)(.+)$/, str) do
      [_, amount, denom] ->
        {:ok, {String.to_integer(amount), denom}}

      _ ->
        {:error, :invalid_format}
    end
  end
end
