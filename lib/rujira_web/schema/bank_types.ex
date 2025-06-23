defmodule RujiraWeb.Schema.BankTypes do
  @moduledoc """
  Defines GraphQL types for bank-related data in the Rujira API.

  This module contains the type definitions and field resolvers for bank-related
  GraphQL objects, including bank supply information and related fields.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias RujiraWeb.Resolvers

  @desc "A rujira represents data about rujira products"
  object :bank do
    field :supply, non_null(list_of(non_null(:bank_supply))) do
      resolve(&Resolvers.Bank.total_supply/3)
    end
  end

  node object(:bank_supply) do
    field :balance, non_null(:balance)
  end
end
