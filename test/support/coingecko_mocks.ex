defmodule Rujira.CoingeckoMocks do
  @moduledoc false
  use Memoize
  use GenServer
  require Logger

  @mock_body_price %{
    "avalanche-2" => %{price: Decimal.new("42.0"), change: 1, mcap: Decimal.new("1000000")},
    "kujira" => %{price: Decimal.new("42.0"), change: 1, mcap: Decimal.new("1000000")},
    "tcy" => %{price: Decimal.new("42.0"), change: 1, mcap: Decimal.new("1000000")},
    "bitcoin" => %{price: Decimal.new("100000.0"), change: 1, mcap: Decimal.new("1000000")},
    "cosmos" => %{price: Decimal.new("100.0"), change: 1, mcap: Decimal.new("1000000")},
    "thorchain" => %{price: Decimal.new("100.0"), change: 1, mcap: Decimal.new("1000000")},
    "nami-protocol" => %{price: Decimal.new("100.0"), change: 1, mcap: Decimal.new("1000000")},
    "mantadao" => %{price: Decimal.new("100.0"), change: 1, mcap: Decimal.new("1000000")},
    "usd-coin" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "binance-peg-dogecoin" => %{
      price: Decimal.new("1.0"),
      change: 1,
      mcap: Decimal.new("1000000")
    },
    "binance-peg-bitcoin-cash" => %{
      price: Decimal.new("1.0"),
      change: 1,
      mcap: Decimal.new("1000000")
    },
    "coinbase-wrapped-btc" => %{
      price: Decimal.new("1.0"),
      change: 1,
      mcap: Decimal.new("1000000")
    },
    "binance-peg-xrp" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "binance-peg-litecoin" => %{
      price: Decimal.new("1.0"),
      change: 1,
      mcap: Decimal.new("1000000")
    },
    "bifrost-bridged-bnb-bifrost" => %{
      price: Decimal.new("230"),
      change: 1,
      mcap: Decimal.new("1000000")
    },
    "bifrost-bridged-eth-bifrost" => %{
      price: Decimal.new("1000"),
      change: 1,
      mcap: Decimal.new("1000000")
    },
    "tether" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "luna-wormhole" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "luna-by-virtuals" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "rujira" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "bnb" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "eth" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "doge" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")},
    "default" => %{price: Decimal.new("1.0"), change: 1, mcap: Decimal.new("1000000")}
  }

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unhandled message in Coingecko GenServer: #{inspect(msg)}")
    {:noreply, state}
  end

  def price(id) do
    case Map.get(@mock_body_price, id) do
      nil -> {:ok, nil}
      price -> {:ok, price}
    end
  end

  def id("AUTO"), do: {:error, :not_found}
  def id("BTC"), do: {:ok, "bitcoin"}
  def id("RKUJI"), do: {:ok, "kujira"}
  def id("rKUJI"), do: {:ok, "kujira"}
  def id("KUJI"), do: {:ok, "kujira"}
  def id("AAVE"), do: {:ok, "aave"}
  def id("DAI"), do: {:ok, "dai"}
  def id("DPI"), do: {:ok, "defipulse-index"}
  def id("FLIP"), do: {:ok, "chainflip"}
  def id("FOX"), do: {:ok, "shapeshift-fox-token"}
  def id("GUSD"), do: {:ok, "gemini-dollar"}
  def id("LINK"), do: {:ok, "chainlink"}
  def id("LUSD"), do: {:ok, "ripple-usd"}
  def id("NAMI"), do: {:ok, "nami-protocol"}
  def id("RAZE"), do: {:ok, "craze"}
  def id("SNX"), do: {:ok, "havven"}
  def id("TCY"), do: {:ok, "tcy"}
  def id("TGT"), do: {:ok, "thorwallet"}
  def id("THOR"), do: {:ok, "thorswap"}
  def id("USDC" <> _), do: {:ok, "usd-coin"}
  def id("USDP"), do: {:ok, "paxos-standard"}
  def id("USDT" <> _), do: {:ok, "tether"}
  def id("WBTC"), do: {:ok, "wrapped-bitcoin"}
  def id("WINK"), do: {:ok, "winkhub"}
  def id("XDEFI"), do: {:ok, "xdefi"}
  def id("XRUNE"), do: {:ok, "thorstarter"}
  def id("YFI"), do: {:ok, "yearn-finance"}
  def id("CBBTC" <> _), do: {:ok, "coinbase-wrapped-btc"}
  def id("BTC/USDT LP"), do: {:ok, "bitcoin"}
  def id("BTC/USDC LP"), do: {:ok, "bitcoin"}
  def id("RUNE"), do: {:ok, "thorchain"}
  def id("RUJI" <> _), do: {:ok, "rujira"}
  def id("BNB" <> _), do: {:ok, "bnb"}
  def id("ETH" <> _), do: {:ok, "eth"}
  def id("LUNC"), do: {:ok, "luna"}
  def id("sRUJI"), do: {:ok, "rujira"}

  def id("NAMI-INDEX-NAV-STHOR1552FJTT2U6EVFXWMNX0W68KH7U4FQT7E6VV0DU3VJ5RWGGUMY5JSMWZJSR-RCPT"),
    do: {:ok, "nami-protocol"}

  def id("NAMI-INDEX-NAV-STHOR14T7NS0ZS8TFNXE8E0ZKE96Y54G07TLWYWGPMS4H3AAFTVDTLPARSKCAFLV-RCPT"),
    do: {:ok, "nami-protocol"}

  def id("MNTA" <> _), do: {:ok, "mantadao"}
  def id("AVAX" <> _), do: {:ok, "avalanche-2"}
  def id("DOGE" <> _), do: {:ok, "doge"}
  def id(_), do: {:ok, "default"}
end
