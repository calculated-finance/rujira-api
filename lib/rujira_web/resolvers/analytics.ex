defmodule RujiraWeb.Resolvers.Analytics do
  alias Absinthe.Resolution.Helpers
  alias Absinthe.Relay

  @mock_ruji_swaps_snaps [
    %{
      bin_open_time: DateTime.from_unix!(1_000_000),
      resolution: "1D",
      swaps_num: 1_000_000,
      swaps_num_ma: 1_000_000,
      volume: 1_000_000,
      volume_ma: 1_000_000,
      liquidity_fee_paid_to_tc: 1_000_000,
      liquidity_fee_paid_to_tc_ma: 1_000_000,
      affiliate_fee: 1_000_000,
      affiliate_fee_ma: 1_000_000
    }
  ]

  def ruji_swaps_snaps(_, %{after: _, before: _, first: f, resolution: _, ma_period: _}, _) do
    Helpers.async(fn ->
      Relay.Connection.from_list(@mock_ruji_swaps_snaps, %{first: f})
    end)
  end
end
