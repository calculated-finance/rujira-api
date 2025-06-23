defmodule Rujira.Ventures.Keiko do
  @moduledoc """
  Keiko is the orchestrator contract for the various sale types created via Ventures
  """
  defmodule Bow do
    @moduledoc false
    defstruct [:admin, :code_id]
    @type t :: %__MODULE__{admin: String.t(), code_id: non_neg_integer()}
    def from_query(%{"admin" => admin, "code_id" => code_id}) do
      {:ok, %__MODULE__{admin: admin, code_id: code_id}}
    end
  end

  defmodule Fin do
    @moduledoc false

    defstruct [:admin, :code_id, :fee_address, :fee_maker, :fee_taker]

    @type t :: %__MODULE__{
            admin: String.t(),
            code_id: non_neg_integer(),
            fee_address: String.t(),
            fee_maker: Decimal.t(),
            fee_taker: Decimal.t()
          }

    def from_query(%{
          "admin" => admin,
          "code_id" => code_id,
          "fee_address" => fee_address,
          "fee_maker" => fee_maker,
          "fee_taker" => fee_taker
        }) do
      with {fee_maker, ""} <- Decimal.parse(fee_maker),
           {fee_taker, ""} <- Decimal.parse(fee_taker) do
        {:ok,
         %__MODULE__{
           admin: admin,
           code_id: code_id,
           fee_address: fee_address,
           fee_maker: fee_maker,
           fee_taker: fee_taker
         }}
      end
    end
  end

  defmodule Pilot do
    @moduledoc false

    defmodule Deposit do
      @moduledoc false

      defstruct [:denom, :amount]
      @type t :: %__MODULE__{denom: String.t(), amount: non_neg_integer()}

      def from_query(%{"denom" => denom, "amount" => amount}) do
        with {amount, ""} <- Integer.parse(amount) do
          {:ok, %__MODULE__{denom: denom, amount: amount}}
        end
      end
    end

    defmodule BidDenom do
      @moduledoc false
      defstruct [:denom, :min_raise_amount]
      @type t :: %__MODULE__{denom: String.t(), min_raise_amount: non_neg_integer()}

      def from_query(%{"denom" => denom, "min_raise_amount" => min_raise_amount}) do
        with {min_raise_amount, ""} <- Integer.parse(min_raise_amount) do
          {:ok, %__MODULE__{denom: denom, min_raise_amount: min_raise_amount}}
        end
      end
    end

    defstruct [
      :admin,
      :code_id,
      :deposit,
      :fee_address,
      :fee_maker,
      :fee_taker,
      :max_premium,
      :bid_denoms
    ]

    @type t :: %__MODULE__{
            admin: String.t(),
            code_id: non_neg_integer(),
            deposit: Deposit.t(),
            fee_address: String.t(),
            fee_maker: Decimal.t(),
            fee_taker: Decimal.t(),
            max_premium: non_neg_integer(),
            bid_denoms: list(BidDenom.t())
          }

    def from_query(%{
          "admin" => admin,
          "code_id" => code_id,
          "deposit" => deposit,
          "fee_address" => fee_address,
          "fee_maker" => fee_maker,
          "fee_taker" => fee_taker,
          "max_premium" => max_premium,
          "bid_denoms" => bid_denoms
        }) do
      bid_denoms =
        Enum.reduce(bid_denoms, {:ok, []}, fn v, agg ->
          with {:ok, agg} <- agg,
               {:ok, parsed} <- BidDenom.from_query(v) do
            {:ok, [parsed | agg]}
          end
        end)

      with {:ok, deposit} <- Deposit.from_query(deposit),
           {fee_maker, ""} <- Decimal.parse(fee_maker),
           {fee_taker, ""} <- Decimal.parse(fee_taker),
           {:ok, bid_denoms} <- bid_denoms do
        {:ok,
         %__MODULE__{
           admin: admin,
           code_id: code_id,
           deposit: deposit,
           fee_address: fee_address,
           fee_maker: fee_maker,
           fee_taker: fee_taker,
           max_premium: max_premium,
           bid_denoms: bid_denoms
         }}
      end
    end
  end

  defmodule Streams do
    @moduledoc false

    defstruct [:admin, :code_id]
    @type t :: %__MODULE__{admin: String.t(), code_id: non_neg_integer()}

    def from_query(%{"admin" => admin, "code_id" => code_id}) do
      {:ok, %__MODULE__{admin: admin, code_id: code_id}}
    end
  end

  defmodule Tokenomics do
    @moduledoc false

    defstruct [:min_liquidity]
    @type t :: %__MODULE__{min_liquidity: Decimal.t()}

    def from_query(%{"minimum_liquidity_one_side" => min_liquidity}) do
      with {min_liquidity, ""} <- Decimal.parse(min_liquidity) do
        {:ok, %__MODULE__{min_liquidity: min_liquidity}}
      end
    end
  end

  defstruct [
    :id,
    :address,
    :bow,
    :fin,
    :pilot,
    :streams,
    :tokenomics
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          bow: Bow.t(),
          fin: Fin.t(),
          pilot: Pilot.t(),
          streams: Streams.t(),
          tokenomics: Tokenomics.t()
        }

  @spec from_config(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(
        address,
        %{
          "fin" => fin,
          "bow" => bow,
          "pilot" => pilot,
          "streams" => streams,
          "tokenomics" => tokenomics
        }
      ) do
    with {:ok, fin} <- Fin.from_query(fin),
         {:ok, bow} <- Bow.from_query(bow),
         {:ok, pilot} <- Pilot.from_query(pilot),
         {:ok, streams} <- Streams.from_query(streams),
         {:ok, tokenomics} <- Tokenomics.from_query(tokenomics) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         fin: fin,
         bow: bow,
         pilot: pilot,
         streams: streams,
         tokenomics: tokenomics
       }}
    end
  end

  def init_msg(msg), do: msg
  def migrate_msg(_from, _to, _), do: %{}
  def init_label(_, _), do: "rujira-ventures-factory"
end
