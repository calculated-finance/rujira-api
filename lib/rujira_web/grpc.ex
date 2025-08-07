defimpl Enumerable, for: GRPC.RPCError do
  def count(%GRPC.RPCError{message: message}),
    do: Enumerable.count(%{status: message, message: message})

  def member?(%GRPC.RPCError{message: message}, element),
    do: Enumerable.member?(%{status: message, message: message}, element)

  def reduce(%GRPC.RPCError{message: message}, acc, fun),
    do: Enumerable.reduce(%{status: message, message: message}, acc, fun)

  def slice(%GRPC.RPCError{message: message}),
    do: Enumerable.slice(%{status: message, message: message})
end

defmodule RujiraWeb.Grpc do
  @moduledoc """
  Provides utilities for working with gRPC in the Rujira application.

  ## Protocol Implementations

  Implements the `Enumerable` protocol for `GRPC.RPCError` to enable enumeration
  and pattern matching on gRPC error messages.

  ## Helper Functions

  Provides conversion functions between Elixir and gRPC data types.
  """

  def to_string(int) when is_integer(int), do: Integer.to_string(int)
  def to_string(nil), do: ""
end

defimpl Enumerable, for: Mint.TransportError do
  def count(%Mint.TransportError{reason: reason}),
    do: Enumerable.count(%{status: reason, reason: reason})

  def member?(%Mint.TransportError{reason: reason}, element),
    do: Enumerable.member?(%{status: reason, reason: reason}, element)

  def reduce(%Mint.TransportError{reason: reason}, acc, fun),
    do: Enumerable.reduce(%{status: reason, reason: reason}, acc, fun)

  def slice(%Mint.TransportError{reason: reason}),
    do: Enumerable.slice(%{status: reason, reason: reason})
end
