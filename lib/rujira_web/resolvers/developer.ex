defmodule RujiraWeb.Resolvers.Developer do
  alias Rujira.Contract
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
      Rujira.Contract.by_code(id)
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

  def info(%{address: address}, _, _) do
    Helpers.async(fn ->
      Rujira.Contract.info(address)
    end)
  end

  def from_config(_address, map), do: Jason.encode(map)

  def query_smart(%{address: address}, %{query: query}, _) do
    with {:ok, query} <- Jason.decode(query),
         {:ok, response} <- Contract.query_state_smart(address, query) do
      Jason.encode(response)
    end
  end

  def state(%{address: address}, _, _) do
    with {:ok, entries} <- Contract.query_state_all(address) do
      {:ok,
       Enum.map(entries, fn {k, v} ->
         %{key: Base.encode16(k), key_ascii: to_ascii_string(k), value: Jason.encode!(v)}
       end)}
    end
  end

  def to_ascii_string(binary) do
    binary
    |> :binary.bin_to_list()
    |> Enum.map(&byte_to_ascii/1)
    |> Enum.join()
  end

  defp byte_to_ascii(byte) when byte in 32..126 do
    <<byte>>
  end

  # Preserve tab as "\t"
  defp byte_to_ascii(9), do: "\t"

  defp byte_to_ascii(byte) do
    ("\\x" <> Integer.to_string(byte, 16))
    # pad to ensure two hex digits (modify padding if desired)
    |> String.pad_leading(4, "0")
    # remove extra zeros if you prefer
    |> String.replace_prefix("00", "")
  end
end
