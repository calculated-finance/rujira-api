defimpl Enumerable, for: GRPC.RPCError do
  def count(%GRPC.RPCError{status: status, message: message}),
    do: Enumerable.count(%{status: status, message: message})

  def member?(%GRPC.RPCError{status: status, message: message}, element),
    do: Enumerable.member?(%{status: status, message: message}, element)

  def reduce(%GRPC.RPCError{status: status, message: message}, acc, fun),
    do: Enumerable.reduce(%{status: status, message: message}, acc, fun)

  def slice(%GRPC.RPCError{status: status, message: message}),
    do: Enumerable.slice(%{status: status, message: message})
end
