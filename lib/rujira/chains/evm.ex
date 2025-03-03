defmodule Rujira.Chains.Evm do
  use Appsignal.Instrumentation.Decorators
  use Memoize

  defmacro __using__(opts) do
    asset = Keyword.fetch!(opts, :asset)
    rpc = Keyword.fetch!(opts, :rpc)
    ws = Keyword.fetch!(opts, :ws)

    quote do
      use Memoize
      use WebSockex
      require Logger
      alias Rujira.Assets

      @asset unquote(asset)
      @rpc unquote(rpc)
      @ws unquote(ws)
      @transfer "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

      def start_link(_) do
        Logger.info("#{__MODULE__} Starting node websocket: #{@ws}")

        case WebSockex.start_link(@ws, __MODULE__, %{}) do
          {:ok, pid} ->
            message =
              Jason.encode!(%{
                jsonrpc: "2.0",
                method: "eth_subscribe",
                id: 0,
                params: ["logs", %{"topics" => [@transfer]}]
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
          {:ok, %{"params" => %{"result" => result}}} ->
            handle_result(result)
            {:ok, state}

          {:ok, _} ->
            {:ok, state}
        end
      end

      defmemo native_balance(address) do
        Rujira.Chains.Evm.native_balance(@rpc, address)
      end

      defmemo balance_of(address, asset) do
        Rujira.Chains.Evm.balance_of(@rpc, address, asset)
      end

      def balances_of(address, assets) do
        Rujira.Chains.Evm.balances_of(@rpc, address, assets)
      end

      defp handle_result(%{"address" => contract, "topics" => [_, sender, recipient | _]}) do
        sender = "0x" <> String.slice(sender, -40, 40)
        recipient = "0x" <> String.slice(recipient, -40, 40)

        # Logger.debug("#{__MODULE__} #{contract}:#{sender}:#{recipient}")
        Memoize.invalidate(__MODULE__, :balance_of, [contract, sender])
        Memoize.invalidate(__MODULE__, :balance_of, [contract, recipient])
      end

      def balances(address, assets) do
        with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == @asset)),
             {:ok, native_balance} <-
               native_balance(address),
             {:ok, assets_balance} <-
               balances_of(address, other_assets) do
          {:ok, [%{asset: Assets.from_string(@asset), amount: native_balance} | assets_balance]}
        end
      end
    end
  end

  @decorate transaction_event()
  def native_balance(rpc, address) do
    with {:ok, "0x" <> hex} <-
           Ethereumex.HttpClient.eth_get_balance(address, "latest", url: rpc) do
      {:ok, String.to_integer(hex, 16)}
    else
      {:error, %{"error" => %{"message" => message}}} -> {:error, message}
      err -> err
    end
  end

  @decorate transaction_event()
  defmemo balance_of(rpc, "0x" <> address, asset) do
    [_, contract_address] = String.split(asset.symbol, "-")

    abi_encoded_data =
      "balanceOf(address)"
      |> ABI.encode([Base.decode16!(address, case: :mixed)])
      |> Base.encode16(case: :lower)

    with {:ok, "0x" <> balance_bytes} <-
           Ethereumex.HttpClient.eth_call(
             %{
               data: "0x" <> abi_encoded_data,
               to: contract_address
             },
             "latest",
             url: rpc
           ),
         {:ok, decoded_balance} <- Base.decode16(balance_bytes, case: :lower),
         [balance] <- ABI.TypeDecoder.decode_raw(decoded_balance, [{:uint, 256}]) do
      {:ok, %{asset: asset, amount: balance}}
    else
      {:error, %{"message" => message}} ->
        {:error, message}

      _ ->
        {:error, :unknown_error}
    end
  end

  @decorate transaction_event()
  def balances_of(rpc, address, assets) do
    with {:ok, balances} <-
           Task.async_stream(assets, &balance_of(rpc, address, &1))
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, balance}}, {:ok, acc} -> {:ok, [balance | acc]}
             {:ok, {:error, %{"error" => %{"message" => message}}}}, _ -> {:error, message}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, balances}
    end
  end
end
