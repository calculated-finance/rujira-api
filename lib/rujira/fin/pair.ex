defmodule Rujira.Fin.Pair do
  defstruct [
    :address,
    :token_base,
    :token_quote,
    :price_precision,
    :decimal_delta,
    :is_bootstrapping,
    :fee_taker,
    :fee_maker,
    :book,
    :id,
    :history,
    :summary
  ]
end
