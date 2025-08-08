defmodule Rujira.Ventures do
  @moduledoc """
  Provides the main interface for interacting with Rujira Ventures products.

  This module acts as the central entry point for business logic related to
  various venture products — currently focused on the Keiko launchpad platform,
  with support for sales, validation, and deployment orchestration.

  Future products will be integrated under this umbrella.
  """

  alias Rujira.Keiko

  # -- Keiko Config --

  @doc "Loads the active Keiko configuration from deployment."
  def keiko, do: Keiko.load()

  # -- Keiko Sales --
  @doc "Fetches a specific sale by id."
  def sale_from_id(id), do: Keiko.query_sale(id)

  @doc """
  Queries sales based on optional filters: `:owner`, `:status`.
  Only one filter should be used at a time.
  """
  def load_sales(owner, status), do: Keiko.load_sales(owner, status)

  # -- Keiko Validation --

  @doc "Validates the token metadata."
  def validate_token(token), do: Keiko.validate_token(token)

  @doc "Validates tokenomics parameters against token payload."
  def validate_tokenomics(token_payload, tokenomics_payload),
    do: Keiko.validate_tokenomics(token_payload, tokenomics_payload)

  @doc "Validates a full venture payload before deployment."
  def validate_venture(venture_payload), do: Keiko.validate_venture(venture_payload)
end
