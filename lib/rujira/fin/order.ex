defmodule Rujira.Fin.Order do
  defstruct [
    :pair,
    :id,
    :owner,
    :price,
    :offer_token,
    :original_offer_amount,
    :remaining_offer_amount,
    :filled_amount,
    :created_at
  ]

end
