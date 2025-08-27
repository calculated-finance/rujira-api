defmodule RujiraWeb.Schema.Calc.Common.DestinationTypes do
  use Absinthe.Schema.Notation
  alias Rujira.Calc.Common.Recipient

  object :calc_destination do
    field :shares, non_null(:integer)
    field :recipient, non_null(:calc_recipient_type)
    field :label, :string
  end

  union :calc_recipient_type do
    types([:calc_recipient_bank, :calc_recipient_contract, :calc_recipient_deposit])

    resolve_type(fn
      %Recipient.Bank{}, _ -> :calc_recipient_bank
      %Recipient.Contract{}, _ -> :calc_recipient_contract
      %Recipient.Deposit{}, _ -> :calc_recipient_deposit
    end)
  end

  object :calc_recipient_bank do
    field :address, non_null(:address)
  end

  object :calc_recipient_contract do
    field :address, non_null(:address)
    field :msg, non_null(:string)
  end

  object :calc_recipient_deposit do
    field :memo, non_null(:string)
  end
end
