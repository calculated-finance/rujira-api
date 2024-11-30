defimpl Enumerable, for: GRPC.RPCError do
  def count(%GRPC.RPCError{message: message}),
    do: Enumerable.count(%{message: message})

  def member?(%GRPC.RPCError{message: message}, element),
    do: Enumerable.member?(%{message: message}, element)

  def reduce(%GRPC.RPCError{message: message}, acc, fun),
    do: Enumerable.reduce(%{message: message}, acc, fun)

  def slice(%GRPC.RPCError{message: message}),
    do: Enumerable.slice(%{message: message})
end

defmodule RujiraWeb.Grpc do
  def to_string(int) when is_integer(int), do: Integer.to_string(int)
  def to_string(nil), do: ""
end
