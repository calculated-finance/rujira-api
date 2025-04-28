defmodule Rujira.Enum do
  def reduce_while_ok(enum, initial_acc \\ [], fun) when is_function(fun, 1) do
    Enum.reduce_while(enum, {:ok, initial_acc}, fn element, {:ok, acc} ->
      case fun.(element) do
        {:ok, el} -> {:cont, {:ok, acc + el}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end
