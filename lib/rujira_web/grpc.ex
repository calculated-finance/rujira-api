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
  def to_string(int) when is_integer(int), do: Integer.to_string(int)
  def to_string(nil), do: ""
end
