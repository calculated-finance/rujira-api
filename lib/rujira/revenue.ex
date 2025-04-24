defmodule Rujira.Revenue do
  @moduledoc """
  Rujira Staking.
  """

  alias Rujira.Revenue.Converter
  alias Rujira.Contracts

  @protocol :rujira
            |> Application.compile_env(__MODULE__, protocol: nil)
            |> Keyword.get(:protocol)

  def protocol(), do: @protocol

  @spec get_converter(String.t() | nil) :: {:ok, Converter.t()} | {:error, :not_found}
  def get_converter(nil), do: {:ok, nil}
  def get_converter(address), do: Contracts.get({Converter, address})
end
