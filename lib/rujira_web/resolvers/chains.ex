defmodule RujiraWeb.Resolvers.Chains do
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
       thor: %{chain: :thor}
     }}
  end
end
