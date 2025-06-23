defmodule Rujira.Chains.Evm do
  @moduledoc """
  Implements the base EVM (Ethereum Virtual Machine) adapter.
  """
  use Appsignal.Instrumentation.Decorators
  use Memoize

  defmacro __using__(opts) do
    chain = Keyword.fetch!(opts, :chain)
    asset = Keyword.fetch!(opts, :asset)
    rpc = Keyword.fetch!(opts, :rpc)
    ws = Keyword.fetch!(opts, :ws)

    quote do
      use Memoize
      use WebSockex
      require Logger
      alias Rujira.Assets
      import Absinthe.Relay.Node
      import Absinthe.Subscription
      import Rujira.Chains.Evm

      @chain unquote(chain)
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

            # Subscribe to new block headers
            new_heads =
              Jason.encode!(%{
                jsonrpc: "2.0",
                method: "eth_subscribe",
                id: 2,
                params: ["newHeads"]
              })

            WebSockex.send_frame(pid, {:text, message})
            WebSockex.send_frame(pid, {:text, new_heads})

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

      def handle_disconnect(x, _) do
        Logger.error("#{__MODULE__} Disconnected")
        raise "#{__MODULE__} Disconnected"
      end

      def handle_frame({:text, msg}, state) do
        case Jason.decode(msg) do
          {:ok, %{"params" => %{"result" => %{"topics" => _} = result}}} ->
            handle_result(result)
            {:ok, state}

          {:ok, %{"params" => %{"result" => %{"hash" => block_hash}}}} ->
            Task.start(fn -> handle_native_transfers(block_hash) end)
            {:ok, state}

          {:ok, _} ->
            {:ok, state}
        end
      end

      def native_balance(address) do
        native_balance(@rpc, address)
      end

      defmemo do_native_balance(address) do
        native_balance(@rpc, eip55(address))
      end

      def balance_of(address, asset) do
        balance_of(@rpc, eip55(address), eip55(asset))
      end

      defmemo do_balance_of(address, asset) do
        balance_of(@rpc, address, asset)
      end

      @decorate transaction_event()
      def balances_of(address, assets) do
        Rujira.Enum.reduce_async_while_ok(assets, fn asset ->
          [_, contract] = String.split(asset.symbol, "-")

          case balance_of(eip55(address), eip55(contract)) do
            {:ok, balance} -> {:ok, %{asset: asset, amount: balance}}
            {:error, %{"error" => %{"message" => message}}} -> {:error, message}
            {:error, error} -> {:error, error}
          end
        end)
      end

      defp handle_result(%{"address" => contract, "topics" => [_, sender, recipient | _]}) do
        sender = eip55("0x" <> String.slice(sender, -40, 40))
        recipient = eip55("0x" <> String.slice(recipient, -40, 40))
        contract = eip55(contract)

        Memoize.invalidate(__MODULE__, :do_balance_of, [sender, contract])
        Memoize.invalidate(__MODULE__, :do_balance_of, [recipient, contract])
        Rujira.Events.publish_node(:layer_1_account, "#{@chain}:#{sender}")
        Rujira.Events.publish_node(:layer_1_account, "#{@chain}:#{recipient}")
      end

      def balances(address, assets) do
        with {:ok, native_balance} <- native_balance(address),
             {:ok, assets_balance} <- balances_of(address, assets) do
          {:ok, [%{asset: Assets.from_string(@asset), amount: native_balance} | assets_balance]}
        end
      end

      defp handle_native_transfers(block_hash) do
        with {:ok, %{"transactions" => txs}} <-
               Ethereumex.HttpClient.eth_get_block_by_hash(block_hash, true, url: @rpc) do
          Task.async_stream(txs, fn %{"from" => from, "to" => to, "value" => "0x" <> value_hex} ->
            if String.to_integer(value_hex, 16) > 0 do
              from = eip55(from)
              to = eip55(to)
              Memoize.invalidate(__MODULE__, :do_native_balance, [from])
              Memoize.invalidate(__MODULE__, :do_native_balance, [to])
              Rujira.Events.publish_node(:layer_1_account, "#{@chain}:#{from}")
              Rujira.Events.publish_node(:layer_1_account, "#{@chain}:#{to}")
            end
          end)
          |> Stream.run()
        end
      end
    end
  end

  @decorate transaction_event()
  def native_balance(rpc, address) do
    case Ethereumex.HttpClient.eth_get_balance(address, "latest", url: with_key(rpc)) do
      {:ok, "0x" <> hex} ->
        {:ok, String.to_integer(hex, 16)}

      {:error, %{"error" => %{"message" => message}}} ->
        {:error, message}

      err ->
        err
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
             url: with_key(rpc)
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

  def with_key(endpoint) do
    case Application.get_env(:rujira, Rujira.Chains.Evm, []) |> Keyword.get(:publicnode_key) do
      nil -> endpoint
      key -> "#{endpoint}/#{key}"
    end
  end

  def eip55(nil), do: nil

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
