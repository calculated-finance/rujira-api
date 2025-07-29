defmodule RujiraWeb.Schema.SortTypes do
  @moduledoc """
  Defines GraphQL types for Sort data in the Rujira API.
  """

  use Absinthe.Schema.Notation

  enum :sort_dir do
    value(:asc)
    value(:desc)
  end
end
