defmodule RujiraWeb.Resolvers.Thorchain do
  alias Thorchain.Types.QueryQuoteSwapResponse
  alias Thorchain.Types.QueryQuoteSwapRequest
  import Thorchain.Types.Query.Stub, only: [quote_swap: 2]

  def quote(_prev, %{from_asset: from_asset, to_asset: to_asset, amount: amount} = x, _res) do
    streaming_interval = Map.get(x, :streaming_interval, nil)
    streaming_quantity = Map.get(x, :streaming_quantity, nil)
    destination = Map.get(x, :destination, nil)
    tolerance_bps = Map.get(x, :tolerance_bps, nil)
    refund_address = Map.get(x, :refund_address, nil)
    affiliate = Map.get(x, :affiliate, nil)
    affiliate_bps = Map.get(x, :affiliate_bps, nil)
    height = Map.get(x, :height, nil)

    req = %QueryQuoteSwapRequest{
      from_asset: from_asset,
      to_asset: to_asset,
      amount: Integer.to_string(amount),
      streaming_interval: streaming_interval,
      streaming_quantity: streaming_quantity,
      destination: destination,
      tolerance_bps: tolerance_bps,
      refund_address: refund_address,
      affiliate: affiliate,
      affiliate_bps: affiliate_bps,
      height: height
    }

    with {:ok, conn} <- Rujira.Chains.Cosmos.Thor.connection(),
         {:ok, %QueryQuoteSwapResponse{} = res} <- quote_swap(conn, req),
         {:ok, expiry} <- DateTime.from_unix(res.expiry) do
      {:ok, Map.put(%{res | expiry: expiry}, :request, req)}
    end
  end
end
