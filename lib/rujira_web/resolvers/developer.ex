defmodule RujiraWeb.Resolvers.Developer do
  alias Absinthe.Resolution.Helpers

  defstruct []

  def codes(_, _, _) do
    with {:ok, codes} <- Rujira.Contract.codes() do
      {:ok,
       Enum.map(
         codes,
         &%{
           id: &1.code_id,
           creator: &1.creator,
           checksum: Base.encode16(&1.data_hash)
         }
       )}
    end
  end

  def contracts(%{id: id}, _, _) do
    Helpers.async(fn ->
      with {:ok, contracts} <- Rujira.Contract.by_code(id) do
        {:ok, Enum.map(contracts, &%{address: &1})}
      end
    end)
  end

  def config(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, config} <- Rujira.Contract.get({__MODULE__, address}) do
        {:ok, config}
      else
        _ -> {:ok, nil}
      end
    end)
  end

  def from_config(_address, map), do: Jason.encode(map)
end
