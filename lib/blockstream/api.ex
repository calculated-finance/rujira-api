defmodule Blockstream.Api do
  @moduledoc """
  Module to query Bitcoin wallet balances using Blockstream API and Finch.
  """

  @api_url "https://blockstream.info/api"

  def get_balance(address) do
    url = Finch.build(:get, "#{@api_url}/address/#{address}")

    with {:ok, %{status: 200, body: body}} <- Finch.request(url, Rujira.Finch),
         {:ok, %{"chain_stats" => %{"funded_txo_sum" => funded, "spent_txo_sum" => spent}}} <-
           Jason.decode(body) do
      {:ok, funded - spent}
    else
      {:ok, %{status: status}} ->
        {:error, "Failed with status code: #{status}"}

      {:error, error} ->
        {:error, error}
    end
  end
end
