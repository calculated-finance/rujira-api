defmodule Rujira.Perps.Pool do
  @moduledoc """
  Rujira Perps Pool.
  """

  @roi_endpoint "https://indexer-mainnet.levana.finance/v2/markets-earn-data?network=rujira-mainnet&factory=thor1gclfrvam6a33yhpw3ut3arajyqs06esdvt9pfvluzwsslap9p6uqt4rzxs"

  defmodule Stats do
    @moduledoc false
    defstruct [
      :sharpe_ratio,
      :lp_apr,
      :xlp_apr,
      :risk
    ]

    @type t :: %__MODULE__{
            sharpe_ratio: non_neg_integer(),
            lp_apr: non_neg_integer(),
            xlp_apr: non_neg_integer(),
            risk: atom()
          }
  end

  defstruct [
    :id,
    :address,
    :name,
    :base_denom,
    :quote_denom,
    :liquidity,
    :stats
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          name: String.t(),
          base_denom: String.t(),
          quote_denom: String.t(),
          stats: Stats.t()
        }

  def from_query(address, %{
        "base" => base,
        "liquidity" => liquidity,
        "market_id" => market_id,
        "config" => %{"max_leverage" => max_leverage},
        "collateral" => %{"native" => %{"denom" => quote_denom}}
      }) do
    with {:ok, liquidity} <- parse_liquidity(liquidity) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         name: market_id,
         base_denom: base,
         quote_denom: quote_denom,
         liquidity: liquidity
       }
       |> add_stats(max_leverage)}
    end
  end

  def add_stats(pool, max_leverage) do
    {lp, xlp, sharpe_ratio} = get_roi_data(pool.address)
    risk = parse_risk(max_leverage)

    %__MODULE__{
      pool
      | stats: %__MODULE__.Stats{
          sharpe_ratio: sharpe_ratio,
          lp_apr: lp,
          xlp_apr: xlp,
          risk: risk
        }
    }
  end

  defp parse_liquidity(%{"unlocked" => unlocked, "locked" => locked}) do
    with {unlocked, ""} <- Decimal.parse(unlocked),
         {locked, ""} <- Decimal.parse(locked) do
      {:ok,
       %{
         total: normalize(Decimal.add(unlocked, locked)),
         unlocked: normalize(unlocked),
         locked: normalize(locked)
       }}
    end
  end

  defp parse_risk(max_leverage) do
    case Decimal.parse(max_leverage) do
      {:ok, parsed} ->
        cond do
          Decimal.compare(parsed, Decimal.new(30)) != :lt -> :low
          Decimal.compare(parsed, Decimal.new(10)) != :lt -> :medium
          true -> :high
        end

      # fallback in case of parse failure
      _ ->
        :high
    end
  end

  defp get_roi_data(address) do
    case Tesla.get(client(), @roi_endpoint) do
      {:ok, res} ->
        data = Map.get(res.body, address, %{})
        roi7 = Map.get(data, "roi7", %{})
        sharpe = Map.get(data, "sharpe", %{})
        annualized_roi30_rate = Map.get(sharpe, "annualized_roi30_rate", %{})

        {lp, ""} =
          Map.get(roi7, "lp", "0")
          |> Decimal.parse()

        {xlp, ""} =
          Map.get(roi7, "xlp", "0")
          |> Decimal.parse()

        {sharpe_ratio, ""} =
          Map.get(annualized_roi30_rate, "xlp", "0")
          |> Decimal.parse()

        sharpe_ratio = Decimal.div(sharpe_ratio, 3) |> Decimal.mult(100)

        {lp, xlp, sharpe_ratio}

      {:error, _} ->
        {Decimal.new(0), Decimal.new(0), Decimal.new(0)}
    end
  end

  defp client do
    Tesla.client([Tesla.Middleware.JSON, {Tesla.Middleware.Timeout, timeout: 10_000}])
  end

  # query store liquidity as decimal
  # need to normalize and add the 8 decimals places according to the api standard
  defp normalize(decimal),
    do: Decimal.round(decimal) |> Decimal.mult(100_000_000) |> Decimal.to_integer()
end
