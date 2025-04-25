defmodule Rujira.Bow.Xyk do
  defmodule Config do
    defstruct [:x, :y, :step, :min_quote, :fee]

    @type t :: %__MODULE__{
            # Denom string of the x asset
            x: String.t(),
            # Denom string of the y asset
            y: String.t(),
            # Step
            step: Decimal,
            # The minimum number that X and Y must meet in order to quote a price
            min_quote: non_neg_integer(),
            # The fee that's charged on each quote and required to be paid
            # in `validate` function
            fee: Decimal.t()
          }

    def from_query(%{"x" => x, "y" => y, "step" => step, "min_quote" => min_quote, "fee" => fee}) do
      with {step, ""} <- Decimal.parse(step),
           {fee, ""} <- Decimal.parse(fee),
           {min_quote, ""} <- Integer.parse(min_quote) do
        {:ok,
         %__MODULE__{
           x: x,
           y: y,
           step: step,
           min_quote: min_quote,
           fee: fee
         }}
      end
    end
  end

  defmodule State do
    defstruct [:id, :x, :y, :k, :shares]

    @type t :: %__MODULE__{
            id: String.t(),
            # Balance of the x token
            x: non_neg_integer(),
            # Balance of the y token
            y: non_neg_integer(),
            # x * y
            k: non_neg_integer(),
            # Number of ownership share tokens issued
            shares: non_neg_integer()
          }

    def from_query(address, %{"x" => x, "y" => y, "k" => k, "shares" => shares}) do
      with {x, ""} <- Integer.parse(x),
           {y, ""} <- Integer.parse(y),
           {k, ""} <- Integer.parse(k),
           {shares, ""} <- Integer.parse(shares) do
        {:ok, %__MODULE__{id: address, x: x, y: y, k: k, shares: shares}}
      end
    end
  end

  defstruct [:id, :address, :config, :state]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          config: Config.t(),
          state: State.t()
        }

  def from_query(address, [config, state]) do
    with {:ok, config} <- Config.from_query(config),
         {:ok, state} <- State.from_query(address, state) do
      {:ok, %__MODULE__{id: address, address: address, config: config, state: state}}
    end
  end
end
