defmodule Rujira.Enum do
  def reduce_while_ok(enum, initial_acc \\ [], fun) when is_function(fun, 1) do
    case Enum.reduce_while(enum, {:ok, initial_acc}, fn element, {:ok, acc} ->
           case fun.(element) do
             {:ok, el} -> {:cont, {:ok, [el | acc]}}
             {:error, reason} -> {:halt, {:error, reason}}
           end
         end) do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      {:error, reason} -> {:error, reason}
    end
  end
end
