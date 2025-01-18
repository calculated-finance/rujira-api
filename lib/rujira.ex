defmodule Rujira do
  @moduledoc """
  Rujira keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  # Function to convert a maps with "key" => "value" to the standardized key value format
  # map(%{"key" => "value", "key" => "value","key" => "value") to list_of(%{key: :key, value: "value"})
  # necessary for handling differerent types of events coming from api or grpc
  def convert_attributes(attributes) do
    Enum.map(attributes, fn
      {key, value} ->
        %{key: key, value: value}
    end)
  end

  def convert_map(map) do
    Enum.map(map, fn {key, value} ->
      key_atom = String.to_atom(key)
      value = if is_map(value), do: convert_map(value), else: value
      {key_atom, value}
    end)
    |> Enum.into(%{})
  end
end
