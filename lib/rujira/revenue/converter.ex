defmodule Rujira.Revenue.Converter do
  alias Cosmos.Base.V1beta1.Coin
  defstruct [:id, :address, :balances, :target_tokens, :target_addresses]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          balances: list(Coin.t()),
          target_tokens: list(String.t()),
          target_addresses: %{String.t() => non_neg_integer()}
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()}
  def from_config(address, %{
        "target_tokens" => target_tokens,
        "target_addresses" => target_addresses
      }) do
    {:ok,
     %__MODULE__{
       id: address,
       address: address,
       balances: [],
       target_tokens: target_tokens,
       target_addresses: Enum.reduce(target_addresses, %{}, &Map.put(&2, &1[0], &1[1]))
     }}
  end

  def init_msg(%{
        "executor" => executor,
        "target_addresses" => target_addresses,
        "target_denoms" => target_denoms
      }) do
    %{
      owner: executor,
      executor: executor,
      target_addresses:
        Enum.map(target_addresses, fn
          %{"address" => address, "weight" => weight} -> [address, weight]
        end),
      target_denoms: target_denoms
    }
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(%{"target_denoms" => x}), do: "rujira-revenue:#{Enum.join(x, ",")}"
end
