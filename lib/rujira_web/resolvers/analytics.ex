defmodule RujiraWeb.Resolvers.Analytics do
  alias Absinthe.Resolution.Helpers
  alias Absinthe.Relay

  @swap_snapshots [
    %{
      bin: DateTime.from_unix!(1_000_000),
      resolution: "1D",
      swaps: %{value: 1_000_000, moving_avg: 1_000_000},
      volume: %{value: 1_000_000, moving_avg: 1_000_000},
      liquidity_fee_paid_to_tc: %{value: 1_000_000, moving_avg: 1_000_000},
      affiliate_fee: %{value: 1_000_000, moving_avg: 1_000_000}
    }
  ]

  def swap_snapshots(_, %{after: _, before: _, first: f, resolution: _, period: _}, _) do
    Helpers.async(fn ->
      Relay.Connection.from_list(@swap_snapshots, %{first: f})
    end)
  end
end
