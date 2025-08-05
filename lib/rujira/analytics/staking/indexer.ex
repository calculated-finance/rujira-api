defmodule Rujira.Analytics.Staking.Indexer do
  @moduledoc "Indexer for staking events."

  alias Rujira.{Analytics, Assets, Prices, Staking}
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{header: %{time: time}, txs: txs}, state) do
    events = Enum.flat_map(txs, &extract_events/1)

    revenue =
      events
      |> Enum.map(&scan_revenue(&1, state))
      |> Enum.sum()

    inflows =
      events
      |> Enum.map(&scan_pool_inflows(&1, state))
      |> Enum.reduce({{0, 0}, {0, 0}}, &sum_inflows/2)

    if revenue > 0 or inflows != {{0, 0}, {0, 0}} do
      build_bin(revenue, inflows, state, time)
      |> Analytics.Staking.update_bins()
    end

    {:noreply, state}
  end

  defp extract_events(%{result: %{events: events}}) when is_list(events), do: events
  defp extract_events(_), do: []

  defp scan_revenue(
         %{attributes: %{"recipient" => r, "amount" => amt}, type: "transfer"},
         %{address: r, revenue_denom: denom}
       ) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, {amount, ^denom}} <- Rujira.parse_amount_and_denom(amt) do
      Prices.value_usd(asset.symbol, amount)
    else
      _ -> 0
    end
  end

  defp scan_revenue(_, _), do: 0

  defp scan_pool_inflows(
         %{attributes: %{"_contract_address" => c, "amount" => a}, type: t},
         %{address: c}
       ) do
    with {a, ""} <- Integer.parse(a) do
      case t do
        "wasm-rujira-staking/account.bond" -> {{a, 0}, {0, 0}}
        "wasm-rujira-staking/account.withdraw" -> {{0, a}, {0, 0}}
        "wasm-rujira-staking/liquid.bond" -> {{0, 0}, {a, 0}}
        "wasm-rujira-staking/liquid.unbond" -> {{0, 0}, {0, a}}
        _ -> {{0, 0}, {0, 0}}
      end
    end
  end

  defp scan_pool_inflows(_, _), do: {{0, 0}, {0, 0}}

  defp sum_inflows({{ai1, ao1}, {li1, lo1}}, {{ai2, ao2}, {li2, lo2}}) do
    {
      {ai1 + ai2, ao1 + ao2},
      {li1 + li2, lo1 + lo2}
    }
  end

  defp build_bin(
         revenue,
         {{account_in, account_out}, {liquid_in, liquid_out}},
         %{address: address, bond_denom: denom} = pool,
         time
       ) do
    with {:ok, %{status: s}} <- Staking.load_pool(pool),
         {:ok, asset} <- Assets.from_denom(denom),
         {:ok, lp_weight} <- lp_weight(asset) do
      total = s.account_bond + s.liquid_bond_size
      weight = Decimal.div(s.account_bond, total)

      comp_revenue =
        Decimal.mult(revenue, weight) |> Decimal.round(0, :floor) |> Decimal.to_integer()

      noncomp_revenue = revenue - comp_revenue

      redemption_rate = Decimal.div(s.liquid_bond_size, s.liquid_bond_shares)

      %{
        timestamp: time,
        contract: address,
        lp_weight: lp_weight,
        total_revenue: revenue,
        liquid_revenue: comp_revenue,
        account_revenue: noncomp_revenue,
        total_balance: total,
        liquid_balance: s.liquid_bond_size,
        account_balance: s.account_bond,
        total_value: Prices.value_usd(asset.symbol, total),
        liquid_value: Prices.value_usd(asset.symbol, s.liquid_bond_size),
        account_value: Prices.value_usd(asset.symbol, s.account_bond),
        liquid_redemption_rate_start: redemption_rate,
        liquid_redemption_rate_current: redemption_rate,
        account_inflows: account_in,
        account_outflows: account_out,
        liquid_inflows: liquid_in,
        liquid_outflows: liquid_out
      }
    end
  end

  defp lp_weight(%{display: "x/bow-xyk-" <> _} = _asset) do
    # TODO: calculate lp weight
    {:ok, Decimal.new(1)}
  end

  defp lp_weight(_), do: {:ok, Decimal.new(1)}
end
