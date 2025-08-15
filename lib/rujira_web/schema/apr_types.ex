defmodule RujiraWeb.Schema.AprTypes do
  @moduledoc """
  Defines GraphQL types for APR type in the Rujira API.
  """

  use Absinthe.Schema.Notation

  enum :apr_status do
    value(:available)
    value(:soon)
    value(:not_applicable)
  end

  object :apr do
    field :value, :bigint
    field :status, non_null(:apr_status)
  end
end
