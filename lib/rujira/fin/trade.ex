defmodule Rujira.Fin.Trades.Trade do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  A normalized Trade event. Primary key is on the (height, tx_idx, idx) tuple
  """

  @type t :: %__MODULE__{
          height: non_neg_integer(),
          tx_idx: non_neg_integer(),
          idx: non_neg_integer(),
          contract: String.t(),
          txhash: String.t(),
          offer: non_neg_integer(),
          bid: non_neg_integer(),
          rate: Decimal.t(),
          side: :base | :quote,
          protocol: :fin,
          timestamp: DateTime.t()
        }

  schema "trades" do
    field :height, :integer
    field :tx_idx, :integer
    field :idx, :integer

    field :contract, :string
    field :txhash, :string
    field :offer, :integer
    field :bid, :integer
    field :rate, :decimal
    field :side, Ecto.Enum, values: [:base, :quote]
    field :protocol, Ecto.Enum, values: [:fin]
    field :timestamp, :utc_datetime_usec
  end

  def changeset(trade, params) do
    trade
    |> cast(params, [
      :height,
      :tx_idx,
      :idx,
      :contract,
      :txhash,
      :offer,
      :bid,
      :rate,
      :side,
      :protocol,
      :timestamp
    ])
    |> validate_required([
      :height,
      :tx_idx,
      :idx,
      :contract,
      :txhash,
      :offer,
      :bid,
      :rate,
      :side,
      :protocol,
      :timestamp
    ])
    |> unique_constraint([:height, :tx_idx, :idx], name: :trades_key)
  end
end
