defmodule RujiraWeb.Fragments.AprFragments do
  @moduledoc false

  @apr_fragment """
  fragment AprFragment on Apr {
    value
    status
  }
  """

  def get_apr_fragment, do: @apr_fragment
end
