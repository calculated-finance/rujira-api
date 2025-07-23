defmodule RujiraWeb.Resolvers.Chains do
  @moduledoc """
  Handles GraphQL resolution for blockchain network-related queries.
  """
  def resolver(_, _, _) do
    {:ok,
     %{
       avax: %{chain: :avax},
       btc: %{chain: :btc},
       bch: %{chain: :bch},
       bsc: %{chain: :bsc},
       doge: %{chain: :doge},
       eth: %{chain: :eth},
       gaia: %{chain: :gaia},
       kuji: %{chain: :kuji},
       ltc: %{chain: :ltc},
       osmo: %{chain: :osmo},
       thor: %{chain: :thor}
     }}
  end
end
