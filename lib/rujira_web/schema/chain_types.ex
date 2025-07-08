defmodule RujiraWeb.Schema.ChainTypes do
  @moduledoc """
  Defines GraphQL types for blockchain chain data in the Rujira API.

  This module contains the type definitions for different blockchain networks
  and their associated data structures used throughout the application.
  """

  use Absinthe.Schema.Notation

  @desc """
  Represents supported blockchain networks.

  Each value corresponds to a chain identifier used across accounts, transactions, and other protocol-specific data.
  This enum is used to differentiate Layer 1 networks (e.g., Ethereum, Bitcoin, Thorchain, etc.).
  """
  enum :chain do
    value(:avax)
    value(:base)
    value(:btc)
    value(:bch)
    value(:bsc)
    value(:doge)
    value(:eth)
    value(:gaia)
    value(:kuji)
    value(:ltc)
    value(:noble)
    value(:thor)
    value(:terra2)
    value(:terra)
    value(:xrp)
  end
end
