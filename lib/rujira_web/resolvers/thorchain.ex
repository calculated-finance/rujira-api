defmodule RujiraWeb.Resolvers.Thorchain do
  alias Thorchain.Types.QueryPoolsResponse
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.QueryPoolResponse
  alias Thorchain.Types.QueryPoolRequest
  alias Thorchain.Types.QueryQuoteSwapResponse
  alias Thorchain.Types.QueryQuoteSwapRequest
  alias Thorchain.Types.Query.Stub, as: Q

  def quote(_prev, %{from_asset: from_asset, to_asset: to_asset, amount: amount} = x, _res) do
    streaming_interval = Map.get(x, :streaming_interval, nil)
    streaming_quantity = Map.get(x, :streaming_quantity, nil)
    destination = Map.get(x, :destination, nil)
    tolerance_bps = Map.get(x, :tolerance_bps, nil)
    refund_address = Map.get(x, :refund_address, nil)
    affiliate = Map.get(x, :affiliate, nil)
    affiliate_bps = Map.get(x, :affiliate_bps, [])
    height = Map.get(x, :height, nil)

    req = %QueryQuoteSwapRequest{
      from_asset: from_asset,
      to_asset: to_asset,
      amount: RujiraWeb.Grpc.to_string(amount),
      streaming_interval: RujiraWeb.Grpc.to_string(streaming_interval),
      streaming_quantity: RujiraWeb.Grpc.to_string(streaming_quantity),
      destination: destination,
      tolerance_bps: RujiraWeb.Grpc.to_string(tolerance_bps),
      refund_address: refund_address,
      affiliate: affiliate,
      affiliate_bps: Enum.map(affiliate_bps, &RujiraWeb.Grpc.to_string/1),
      height: height
    }

    with {:ok, conn} <- Rujira.Chains.Cosmos.Thor.connection(),
         {:ok, %QueryQuoteSwapResponse{} = res} <- Q.quote_swap(conn, req),
         {:ok, expiry} <- DateTime.from_unix(res.expiry) do
      {:ok, %{res | expiry: expiry} |> Map.put(:request, req) |> Map.put(:asset_in, from_asset)}
    end
  end

  def pools(_, _, _) do
    req = %QueryPoolsRequest{}

    with {:ok, conn} <- Rujira.Chains.Cosmos.Thor.connection(),
         {:ok, %QueryPoolsResponse{pools: pools}} <- Q.pools(conn, req) do
      {:ok, Enum.map(pools, &cast_pool/1)}
    end
  end

  def pool(_, %{asset: asset}, _) do
    req = %QueryPoolRequest{asset: asset}

    with {:ok, conn} <- Rujira.Chains.Cosmos.Thor.connection(),
         {:ok, %QueryPoolResponse{} = pool} <- Q.pool(conn, req) do
      {:ok, cast_pool(pool)}
    end
  end

  defp cast_pool(pool) do
    pool
    |> Map.put(:lp_units, Map.get(pool, :LP_units))
    |> Map.update(:derived_depth_bps, "0", &String.to_integer/1)
    |> Map.update(:savers_fill_bps, "0", &String.to_integer/1)
  end
end
