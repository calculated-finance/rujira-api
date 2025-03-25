defmodule RujiraWeb.Resolvers.Thorchain.Analytics do
  alias Absinthe.Resolution.Helpers
  alias Absinthe.Relay

  @mock_pools_snaps [
    %{
      bin_open_time: DateTime.from_unix!(1_000_000),
      resolution: "1D",
      deposits_value: 1_000_000,
      earnings: 1_000_000,
      earnings_moving_avg: 1_000_000,
      liquidity_utilization: 1_000_000,
      liquidity_utilization_moving_avg: 1_000_000,
      swaps_num: 1_000_000,
      swaps_num_moving_avg: 1_000_000,
      tvl_by_asset: [
        %{
          asset: "BTC.BTC",
          tvl: 1_000_000,
          weight: 1_000_000
        }
      ],
      tvl_by_chain: [
        %{
          chain: :avax,
          tvl: 1_000_000,
          weight: 1_000_000
        }
      ],
      tvl_end_of_bin: 1_000_000,
      unique_deposit_users: 1_000_000,
      unique_swap_users: 1_000_000,
      unique_withdraw_users: 1_000_000,
      volume: 1_000_000,
      volume_moving_avg: 1_000_000,
      withdrawals_value: 1_000_000
    }
  ]

  def pools_snaps(_, %{after: _, before: _, first: f, resolution: _, ma_period: _}, _) do
    Helpers.async(fn ->
      Relay.Connection.from_list(@mock_pools_snaps, %{first: f})
    end)
  end

  def pools_overview(_, _, _) do
    Helpers.async(fn ->
      {:ok,
       [
         %{
           asset: "BTC.BTC",
           tvl: -100,
           volume_24h: 50,
           volume_7d: 25,
           dlur: 10,
           dlur_moving_avg: 9,
           apr_30d: 1
         },
         %{
           asset: "ETH.ETH",
           tvl: -100,
           volume_24h: 50,
           volume_7d: 25,
           dlur: 10,
           dlur_moving_avg: 9,
           apr_30d: 1
         }
       ]}
    end)
  end

  def pool_snaps(_, %{after: _, before: _, first: f, resolution: _, asset: _, ma_period: _}, _) do
    Helpers.async(fn ->
      Relay.Connection.from_list(mock_pool(), %{first: f})
    end)
  end

  def pool_aggregated_data(_, _, _) do
    Helpers.async(fn ->
      {:ok, mock_pool()}
    end)
  end

  def mock_pool() do
    with {:ok, date} <- DateTime.now("Etc/UTC") do
      %{
        apr: 12_345_678_901,
        apr_moving_avg: 11_234_567_890,
        asset: "BTC.BTC",
        bin_open_time: date,
        closing_balance_asset: 500_000_000_000,
        closing_balance_rune: 1_000_000_000_000,
        closing_lp_units: 10_000_000_000,
        closing_price_asset: 20_000_000_000,
        closing_price_rune: 5_000_000_000,
        closing_value: 30_000_000_000,
        deposits_asset_quantity: 2_500_000_000,
        deposits_rune_quantity: 1_000_000_000,
        deposits_value: 5_000_000_000_000,
        earnings: 150_000_000_000,
        earnings_per_lp_unit: 5_000_000_000,
        impermanent_loss: 20_000_000_000,
        liquidity_utilization: 75_000_000_000,
        liquidity_utilization_moving_avg: 72_000_000_000,
        opening_balance_asset: 600_000_000_000,
        opening_balance_rune: 1_500_000_000_000,
        opening_lp_units: 15_000_000_000,
        opening_price_asset: 18_000_000_000,
        opening_price_rune: 4_500_000_000,
        opening_value: 28_500_000_000,
        price_pl: 2_500_000_000,
        price_pl_approx: 2_000_000_000,
        resolution: "1D",
        volume: 1_000_000_000_000,
        volume_moving_avg: 950_000_000_000,
        withdrawals_asset_quantity: 1_200_000_000,
        withdrawals_rune_quantity: 500_000_000,
        withdrawals_value: 3_000_000_000_000
      }
    end
  end
end
