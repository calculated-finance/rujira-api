defmodule Thorchain do
  # alias Thorchain.Types.QueryNodesResponse
  # alias Thorchain.Types.QueryNodesRequest
  alias Thorchain.Swaps
  alias Thorchain.Types.QueryAsgardVaultsRequest
  alias Thorchain.Types.QueryAsgardVaultsResponse
  alias Thorchain.Types.QueryNetworkRequest
  alias Thorchain.Types.QueryPoolsResponse
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.Query.Stub, as: Q

  def network() do
    req = %QueryNetworkRequest{}

    with {:ok, res} <- Thorchain.Node.stub(&Q.network/2, req) do
      {:ok, res}
    end
  end

  def pools() do
    req = %QueryPoolsRequest{}

    with {:ok, %QueryPoolsResponse{pools: pools}} <-
           Thorchain.Node.stub(&Q.pools/2, req) do
      {:ok, pools}
    end
  end

  def total_bonds() do
    # req = %QueryNodesRequest{}
    api = Application.get_env(:rujira, Thorchain.Node)[:api]

    client =
      Tesla.client([
        {Tesla.Middleware.BaseUrl, api},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]}
      ])

    with {:ok, %{rune_price_in_tor: price}} <- network(),
         # {:ok, %QueryNodesResponse{nodes: nodes}} <- Thorchain.Node.stub(&Q.nodes/2, req) do
         {:ok, response} <- Tesla.get(client, "/thorchain/nodes") do
      total_bonds =
        response.body
        |> Enum.reduce(0, fn node, acc ->
          bond = String.to_integer(Map.get(node, "total_bond", "0"))
          acc + bond
        end)

      {:ok, Rujira.Prices.normalize(total_bonds * String.to_integer(price), 16)}
    end
  end

  def tvl() do
    with {:ok, pools} <- pools() do
      tvl =
        pools
        |> Enum.reduce(0, fn pool, acc ->
          balance_asset = String.to_integer(Map.get(pool, :balance_asset))
          asset_tor_price = String.to_integer(Map.get(pool, :asset_tor_price))
          tvl = balance_asset * asset_tor_price * 2
          acc + tvl
        end)

      {:ok, Rujira.Prices.normalize(tvl, 16)}
    end
  end

  def chains() do
    req = %QueryAsgardVaultsRequest{}

    with {:ok, %QueryAsgardVaultsResponse{asgard_vaults: vaults}} <-
           Thorchain.Node.stub(&Q.asgard_vaults/2, req) do
      [vault | _] = vaults
      {:ok, vault.chains}
    end
  end

  def swaps_data() do
    with total_swap_volume <- Swaps.total_volume(),
         daily_swap_volume <- Swaps.total_volume(:daily),
         total_swaps <- Swaps.count_swaps(),
         affiliate_transactions <- Swaps.count_affiliate_swaps(),
         affiliate_volume <- Swaps.total_affiliate_volume() do
      {:ok,
       %{
         total_swap_volume: total_swap_volume,
         daily_swap_volume: daily_swap_volume,
         total_swaps: total_swaps,
         affiliate_volume: affiliate_volume,
         affiliate_transactions: affiliate_transactions
       }}
    end
  end

  def get_affiliate(memo) do
    parts = String.split(memo, ":")

    if length(parts) >= 6 do
      affiliate_id = Enum.at(parts, 4)
      affiliate_bp = Enum.at(parts, 5)

      {:ok, {affiliate_id, affiliate_bp}}
    else
      {:error, :no_affiliate}
    end
  end
end
