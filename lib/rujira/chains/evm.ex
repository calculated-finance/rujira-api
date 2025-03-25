defmodule Rujira.Chains.Evm do
  use Appsignal.Instrumentation.Decorators
  use Memoize

  defmacro __using__(opts) do
    asset = Keyword.fetch!(opts, :asset)
    rpc = Keyword.fetch!(opts, :rpc)
    ws = Keyword.fetch!(opts, :ws)
    addresses = Keyword.get(opts, :addresses)

    quote do
      use Memoize
      use WebSockex
      require Logger
      alias Rujira.Assets

      @asset unquote(asset)
      @rpc unquote(rpc)
      @ws unquote(ws)
      @addresses unquote(addresses)
      @transfer "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

      def start_link(_) do
        Logger.info("#{__MODULE__} Starting node websocket: #{@ws}")

        args =
          case @addresses do
            nil ->
              %{"topics" => [@transfer]}

            as ->
              %{"address" => as, "topics" => [@transfer]}
          end

        case WebSockex.start_link(@ws, __MODULE__, %{}) do
          {:ok, pid} ->
            message =
              Jason.encode!(%{
                jsonrpc: "2.0",
                method: "eth_subscribe",
                id: 0,
                params: ["logs", args]
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

      def native_balance(address) do
        Rujira.Chains.Evm.native_balance(@rpc, address)
      end

      defmemo balance_of(address, asset) do
        Rujira.Chains.Evm.balance_of(@rpc, address, asset)
      end

      @decorate transaction_event()
      def balances_of(address, assets) do
        with {:ok, balances} <-
               assets
               |> Task.async_stream(fn a ->
                 [_, contract] = String.split(a.symbol, "-")
                 {a, balance_of(address, Rujira.Chains.Evm.eip55(contract))}
               end)
               |> Enum.reduce({:ok, []}, fn
                 {:ok, {asset, {:ok, balance}}}, {:ok, acc} ->
                   {:ok, [%{asset: asset, amount: balance} | acc]}

                 {:ok, {:error, %{"error" => %{"message" => message}}}}, _ ->
                   {:error, message}

                 {:ok, {:error, error}}, _ ->
                   {:error, error}

                 {:error, err}, _ ->
                   {:error, err}
               end) do
          {:ok, balances}
        end
      end

      defp handle_result(%{"address" => contract, "topics" => [_, sender, recipient | _]}) do
        sender = Rujira.Chains.Evm.eip55("0x" <> String.slice(sender, -40, 40))
        recipient = Rujira.Chains.Evm.eip55("0x" <> String.slice(recipient, -40, 40))
        contract = Rujira.Chains.Evm.eip55(contract)
        Logger.debug("#{__MODULE__} #{contract}:#{sender}:#{recipient}")

        Memoize.invalidate(__MODULE__, :balance_of, [sender, contract])
        Memoize.invalidate(__MODULE__, :balance_of, [recipient, contract])
      end

      def balances(address, assets) do
        with {:ok, native_balance} <- native_balance(address),
             {:ok, assets_balance} <- balances_of(address, assets) do
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
  def balance_of(rpc, "0x" <> address, contract) do
    abi_encoded_data =
      "balanceOf(address)"
      |> ABI.encode([Base.decode16!(address, case: :mixed)])
      |> Base.encode16(case: :lower)

    with {:ok, "0x" <> balance_bytes} <-
           Ethereumex.HttpClient.eth_call(
             %{data: "0x" <> abi_encoded_data, to: contract},
             "latest",
             url: rpc
           ),
         {:ok, decoded_balance} <- Base.decode16(balance_bytes, case: :lower),
         [balance] <- ABI.TypeDecoder.decode_raw(decoded_balance, [{:uint, 256}]) do
      {:ok, balance}
    else
      {:error, %{"message" => message}} ->
        {:error, message}

      _ ->
        {:error, :unknown_error}
    end
  end

  def eip55(address) when is_binary(address) do
    # Remove the "0x" prefix if present and downcase the address.
    addr =
      address
      |> String.trim()
      |> remove_0x()
      |> String.downcase()

    # Compute the Keccak-256 hash of the lowercase address.
    hash = keccak256(addr)

    # For each character, if it is in [a-f] and the corresponding hash nibble is >= 8, uppercase it.
    checksum_chars =
      addr
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {char, index} ->
        hash_nibble = String.at(hash, index)

        if should_uppercase?(char, hash_nibble) do
          String.upcase(char)
        else
          char
        end
      end)

    "0x" <> Enum.join(checksum_chars, "")
  end

  defp remove_0x("0x" <> rest), do: rest
  defp remove_0x("0X" <> rest), do: rest
  defp remove_0x(other), do: other

  defp keccak256(data) do
    data
    |> ExKeccak.hash_256()
    |> Base.encode16(case: :lower)
  end

  defp should_uppercase?(char, hash_nibble) do
    # Only consider alphabetic characters (a-f) for capitalization.
    if char =~ ~r/[a-f]/ do
      case Integer.parse(hash_nibble, 16) do
        {num, _} when num >= 8 -> true
        _ -> false
      end
    else
      false
    end
  end
end
