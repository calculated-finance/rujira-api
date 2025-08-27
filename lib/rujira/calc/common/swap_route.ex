defmodule Rujira.Calc.Common.SwapRoute do
  alias Rujira.Calc.Common.SwapRoute.Thorchain.StreamingSwap

  defmodule Fin do
    defstruct pair_address: ""

    @type t :: %__MODULE__{pair_address: String.t()}
  end

  defmodule Thorchain do
    defstruct streaming_interval: nil,
              max_streaming_quantity: nil,
              affiliate_code: nil,
              affiliate_bps: nil,
              latest_swap: nil

    @type t :: %__MODULE__{
            streaming_interval: non_neg_integer() | nil,
            max_streaming_quantity: non_neg_integer() | nil,
            affiliate_code: String.t() | nil,
            affiliate_bps: non_neg_integer() | nil,
            latest_swap: StreamingSwap.t() | nil
          }
  end

  defmodule Thorchain.StreamingSwap do
    alias Rujira.Balances.Balance

    defstruct swap_amount: nil,
              expected_receive_amount: nil,
              starting_block: 0,
              streaming_swap_blocks: 0,
              memo: ""

    @type t :: %__MODULE__{
            swap_amount: Balance.t(),
            expected_receive_amount: Balance.t(),
            starting_block: non_neg_integer(),
            streaming_swap_blocks: non_neg_integer(),
            memo: String.t()
          }

    def from_config(%{
          "swap_amount" => swap_amount,
          "expected_receive_amount" => expected_receive_amount,
          "starting_block" => starting_block,
          "streaming_swap_blocks" => streaming_swap_blocks,
          "memo" => memo
        }) do
      with {:ok, swap_amount} <- Balance.parse(swap_amount),
           {:ok, expected_receive_amount} <- Balance.parse(expected_receive_amount) do
        {:ok,
         %__MODULE__{
           swap_amount: swap_amount,
           expected_receive_amount: expected_receive_amount,
           starting_block: starting_block,
           streaming_swap_blocks: streaming_swap_blocks,
           memo: memo
         }}
      end
    end
  end

  def from_config(%{"fin" => %{"pair_address" => pair_address}}) do
    {:ok, %Fin{pair_address: pair_address}}
  end

  def from_config(%{
        "thorchain" => %{
          "streaming_interval" => streaming_interval,
          "max_streaming_quantity" => max_streaming_quantity,
          "affiliate_code" => affiliate_code,
          "affiliate_bps" => affiliate_bps,
          "latest_swap" => latest_swap
        }
      }) do
    with {:ok, latest_swap} <- StreamingSwap.from_config(latest_swap) do
      {:ok,
       %Thorchain{
         streaming_interval: streaming_interval,
         max_streaming_quantity: max_streaming_quantity,
         affiliate_code: affiliate_code,
         affiliate_bps: affiliate_bps,
         latest_swap: latest_swap
       }}
    end
  end
end
