defmodule Rujira.Chains.Eth do
  @rpc "https://ethereum-rpc.publicnode.com"
  @ws "wss://eth-mainnet.g.alchemy.com/v2/LIEhGG98f4Oybg-zy7ws7P--JDse4-_W"

  @transfer "a9059cbb"
  @transfer_from "23b872dd"

  defstruct rpc: @rpc

  use WebSockex
  require Logger

  def start_link(_) do
    Logger.info("#{__MODULE__} Starting node websocket: #{@ws}")

    case WebSockex.start_link(@ws, __MODULE__, %{}) do
      {:ok, pid} ->
        message =
          Jason.encode!(%{
            jsonrpc: "2.0",
            method: "eth_subscribe",
            id: 0,
            params: ["alchemy_minedTransactions"]
          })

        WebSockex.send_frame(pid, {:text, message})

        {:ok, pid}

      {:error, _} ->
        Logger.error("#{__MODULE__} Error connecting to websocket #{@ws}")
        :ignore
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("#{__MODULE__} Connected")
    {:ok, state}
  end

  def handle_disconnect(_, _) do
    Logger.error("#{__MODULE__} Disconnected")
    raise "#{__MODULE__} Disconnected"
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok,
       %{"params" => %{"result" => %{"transaction" => %{"input" => "0x" <> @transfer <> _} = tx}}}} ->
        handle_tx("transfer", tx)
        {:ok, state}

      {:ok,
       %{
         "params" => %{
           "result" => %{"transaction" => %{"input" => "0x" <> @transfer_from <> _} = tx}
         }
       }} ->
        handle_tx("transfer_from", tx)
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  defp handle_tx(ty, %{
         "input" => "0x" <> input,
         "from" => sender,
         "to" => contract
       }) do
    <<_function::binary-size(4), recipient::binary-size(32), _rest::binary>> =
      Base.decode16!(input, case: :lower)

    <<_padding::binary-size(12), recipient::binary-size(20)>> = recipient
    recipient = "0x" <> Base.encode16(recipient, case: :lower)

    Logger.debug("#{__MODULE__} #{ty} #{contract}:#{sender}:#{recipient}")
    Memoize.invalidate(Rujira.Chains.Evm, :balance_of, [@rpc, contract, sender])
    Memoize.invalidate(Rujira.Chains.Evm, :balance_of, [@rpc, contract, recipient])
  end
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Eth do
  alias Rujira.Assets

  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "ETH.ETH")),
         {:ok, native_balance} <-
           Rujira.Chains.Evm.native_balance(a.rpc, address, Assets.from_string("ETH.ETH")),
         {:ok, assets_balance} <-
           Rujira.Chains.Evm.balances_of(a.rpc, address, other_assets) do
      {:ok, native_balance |> Enum.concat(assets_balance)}
    end
  end
end
