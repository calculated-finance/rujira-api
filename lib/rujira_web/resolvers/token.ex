defmodule RujiraWeb.Resolvers.Token do
  alias Rujira.Assets
  alias RujiraWeb.Resolvers.Node

  def asset(%{asset: "THOR." <> _ = asset}, _, _) do
    {:ok,
     %Assets.Asset{
       id: Node.encode_id(:asset, asset),
       asset: asset,
       type: :layer_1,
       chain: :thor
     }}
  end

  def asset(%{asset: asset}, _, _) do
    {:ok,
     %Assets.Asset{
       id: Node.encode_id(:asset, asset),
       asset: asset,
       type: Rujira.Assets.type(asset),
       chain: get_chain(asset)
     }}
  end

  def asset(%{denom: denom}, _, _) do
    with {:ok, asset} <- Rujira.Assets.from_native(denom) do
      {:ok,
       %Assets.Asset{
         id: Node.encode_id(:asset, asset),
         asset: asset,
         type: Rujira.Assets.type(asset),
         chain: get_chain(asset)
       }}
    end
  end

  def variants(%{asset: asset}, _, _) do
    l1 = Rujira.Assets.to_layer_1(asset)

    l1 = %Assets.Asset{
      id: Node.encode_id(:asset, l1),
      asset: l1,
      type: :layer_1,
      chain: get_chain(asset)
    }

    {:ok,
     %{
       layer1: l1,
       secured: secured(l1.asset),
       native:
         case Rujira.Assets.to_native(asset) do
           {:ok, nil} ->
             nil

           {:ok, denom} ->
             %{
               id: Node.encode_id(:denom, denom),
               denom: denom
             }
         end
     }}
  end

  def secured("THOR." <> _) do
    nil
  end

  def secured(asset) do
    secured = Rujira.Assets.to_secured(asset)

    %Assets.Asset{
      id: Node.encode_id(:asset, secured),
      asset: secured,
      type: :secured,
      chain: get_chain(asset)
    }
  end

  defp get_chain(sym) do
    Rujira.Assets.chain(sym) |> String.downcase() |> String.to_existing_atom()
  end

  @spec denom(%{:denom => any(), optional(any()) => any()}, any(), any()) ::
          {:ok, %{denom: any(), id: <<_::64, _::_*8>>}}
  def denom(%{denom: denom}, _, _) do
    {:ok, %{id: Node.encode_id(:denom, denom), denom: denom}}
  end

  def metadata(%{asset: asset}, _, _) do
    symbol = Rujira.Assets.symbol(asset)
    decimals = Rujira.Assets.decimals(asset)
    {:ok, %{symbol: symbol, decimals: decimals}}
  end

  def metadata(%{denom: denom}, _, _) do
    symbol = Rujira.Denoms.symbol(denom)
    decimals = Rujira.Denoms.decimals(denom)
    {:ok, %{symbol: symbol, decimals: decimals}}
  end

  def prices(_, b) do
    Rujira.Prices.get(b)
  end

  def quote(%{request: %{to_asset: asset}, expected_amount_out: amount}, _, _) do
    {:ok, %{asset: asset, amount: amount}}
  end
end
