defmodule Rujira.Keiko.Sale.Pilot do
  @moduledoc """
  This module Parses the sale data of a pilot sale venture type from the Keiko contract
  """

  defstruct [
    :fin,
    :bow,
    :sale,
    :token,
    :tokenomics,
    :terms_conditions_accepted
  ]

  alias Rujira.Keiko.Token
  alias Rujira.Keiko.Tokenomics
  alias Rujira.Pilot.Sale

  @type t :: %__MODULE__{
          fin: String.t(),
          bow: String.t(),
          sale: Sale.t(),
          token: Token.t(),
          tokenomics: Tokenomics.t(),
          terms_conditions_accepted: boolean()
        }

  def from_query(status, %{
        "bow" => bow,
        "fin" => fin,
        "pilot" => pilot,
        "terms_conditions_accepted" => terms_conditions_accepted,
        "token" => token,
        "tokenomics" => tokenomics
      }) do
    with {:ok, tokenomics} <- Tokenomics.from_query(tokenomics),
         {:ok, sale_amount} <- Tokenomics.get_sale_amount(tokenomics),
         {:ok, sale} <- Sale.from_query(status, sale_amount, pilot),
         {:ok, token} <- Token.from_query(token) do
      {:ok,
       %__MODULE__{
         fin: fin,
         bow: bow,
         sale: sale,
         token: token,
         tokenomics: tokenomics,
         terms_conditions_accepted: terms_conditions_accepted
       }}
    else
      _ -> {:error, :invalid_data_pilot_sale}
    end
  end
end
