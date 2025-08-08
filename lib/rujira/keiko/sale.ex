defmodule Rujira.Keiko.Sale do
  @moduledoc """
  This module Parses the sale data from the Keiko contract into a the correct struct
  """

  alias Rujira.Keiko.Sale.Pilot

  defstruct [
    :id,
    :idx,
    :owner,
    :status,
    :title,
    :description,
    :url,
    :beneficiary,
    :venture
  ]

  @type status :: :configured | :scheduled | :in_progress | :executed | :retracted | :completed

  @type t :: %__MODULE__{
          id: String.t(),
          idx: String.t(),
          owner: String.t(),
          status: status(),
          title: String.t(),
          description: String.t(),
          url: String.t(),
          beneficiary: String.t(),
          # Venture type can be PilotSale or other types of venture that will be built
          venture: Pilot.t()
        }

  def from_query(%{
        "venture_type" => "pilot",
        "owner" => owner,
        "idx" => idx,
        "status" => status,
        "venture" => %{"pilot" => venture}
      }) do
    with {:ok, status} <- parse_status(status),
         {:ok, sale} <- Pilot.from_query(status, venture),
         {:ok, {title, description, url, beneficiary}} <- parse_descriptions(venture) do
      {:ok,
       %__MODULE__{
         id: idx,
         idx: idx,
         owner: owner,
         status: status,
         title: title,
         description: description,
         url: url,
         beneficiary: beneficiary,
         venture: sale
       }}
    else
      _ -> {:error, :invalid_data}
    end
  end

  defp parse_descriptions(%{
         "pilot" => %{
           "pilot" => %{
             "title" => title,
             "description" => description,
             "url" => url,
             "beneficiary" => beneficiary
           }
         }
       }) do
    {:ok, {title, description, url, beneficiary}}
  end

  defp parse_status("configured"), do: {:ok, :configured}
  defp parse_status("scheduled"), do: {:ok, :scheduled}
  defp parse_status("in_progress"), do: {:ok, :in_progress}
  defp parse_status("executed"), do: {:ok, :executed}
  defp parse_status("retracted"), do: {:ok, :retracted}
  defp parse_status("completed"), do: {:ok, :completed}
  defp parse_status(_), do: {:error, :invalid_status}
end
