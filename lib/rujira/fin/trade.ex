defmodule Rujira.Fin.Trade do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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
          timestamp: DateTime.t(),
          quote_amount: non_neg_integer(),
          base_amount: non_neg_integer(),
          # The price submitted by the rujira_rs::Swappable struct.
          # eg prefixes mm:, fixed:, oracle:
          price: String.t(),
          type: :buy | :sell
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
    field :price, :string

    # Derived
    field :quote_amount, :integer, virtual: true
    field :base_amount, :integer, virtual: true
    field :type, Ecto.Enum, values: [:buy, :sell], virtual: true
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

  def query() do
    from t in __MODULE__,
      select_merge: %{
        price: t.rate,
        quote_amount: fragment("CASE WHEN ? = 'base' THEN ? ELSE ? END", t.side, t.offer, t.bid),
        base_amount: fragment("CASE WHEN ? = 'base' THEN ? ELSE ? END", t.side, t.bid, t.offer),
        type: fragment("CASE WHEN ? = 'base' THEN 'buy' ELSE 'sell' END", t.side)
      }
  end
end
