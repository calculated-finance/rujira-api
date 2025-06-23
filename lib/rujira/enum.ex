defmodule Rujira.Enum do
  @moduledoc """
  Custom enum utilities for safer and more efficient list processing.
  """

  @doc """
  Iterates over an enumerable, applying a function that returns `{:ok, value}`, `{:error, reason}`, or `:skip`.

  - Accumulates all returned values into a list.
  - Halts and returns `{:error, reason}` if any element returns an error.
  - Skips over elements if `:skip` is returned.
  - Returns `{:ok, list}` when all elements succeed.

  ## Examples

      iex> fun = fn x -> if x > 0, do: {:ok, x * 2}, else: {:error, :invalid} end
      iex> Rujira.Enum.reduce_while_ok([1, 2, 3], [], fun)
      {:ok, [2, 4, 6]}

      iex> fun = fn x -> if x > 0, do: {:ok, x * 2}, else: :skip end
      iex> Rujira.Enum.reduce_while_ok([1, -1, 3], [], fun)
      {:ok, [2, 6]}

  """
  def reduce_while_ok(enum, initial_acc \\ [], fun) do
    Enum.reduce_while(enum, {:ok, initial_acc}, fn element, {:ok, acc} ->
      case fun.(element) do
        {:ok, el} ->
          {:cont, {:ok, [el | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}

        :skip ->
          {:cont, {:ok, acc}}
      end
    end)
    |> finalize_reduce_result()
  end

  defp finalize_reduce_result({:ok, acc}), do: {:ok, Enum.reverse(acc)}
  defp finalize_reduce_result({:error, reason}), do: {:error, reason}

  @doc """
  Returns a list of unique elements from the given enumerable, **preserving the original order**.

  This function uses a `MapSet` to track seen elements while iterating through the enumerable,
  ensuring each unique element appears only once and in the order it was first encountered.

  It is faster than `Enum.uniq/1` for large lists due to better average-case performance characteristics.

  ### Performance Notes

  - `Rujira.Enum.uniq/1` runs in **O(n)** time on average, as it uses a hash-based `MapSet` for constant-time lookups and inserts.
  - `Enum.uniq/1` has **O(n²)** worst-case time complexity, since it performs a linear scan for each element.
  - This implementation builds the result list in reverse and reverses it once at the end to maintain order efficiently.

  ## Examples

      iex> Rujira.Enum.uniq([:a, :b, :a, :c])
      [:a, :b, :c]  # order preserved

      iex> Rujira.Enum.uniq(["apple", "banana", "apple", "pear", "banana"])
      ["apple", "banana", "pear"]

  """
  def uniq(enum) do
    {_, acc} =
      Enum.reduce(enum, {MapSet.new(), []}, fn x, {seen, acc} ->
        if MapSet.member?(seen, x) do
          {seen, acc}
        else
          {MapSet.put(seen, x), [x | acc]}
        end
      end)

    Enum.reverse(acc)
  end

  @doc """
  Runs the given function concurrently over the enum using `Task.async_stream/3`,
  short-circuiting on the first error, and collecting only successful results.

  The given function should return either:
  - `{:ok, value}` → accumulated
  - `{:error, reason}` → halts and returns `{:error, reason}`
  - `:skip` → skips the element

  ## Options:
    - Any `Task.async_stream/3` options (e.g. `timeout`, `max_concurrency`)

  ## Example

      Rujira.Enum.reduce_async_while_ok([1, 2, 3], fn x ->
        if x > 1, do: {:ok, x * 2}, else: :skip
      end)

      # => {:ok, [4, 6]}

  """
  def reduce_async_while_ok(enum, fun, opts \\ []) when is_function(fun, 1) do
    enum
    |> Task.async_stream(fun, opts)
    |> reduce_while_ok([], &handle_async_result/1)
  end

  defp handle_async_result({:ok, {:ok, val}}), do: {:ok, val}
  defp handle_async_result({:ok, {:error, reason}}), do: {:error, reason}
  defp handle_async_result({:ok, :skip}), do: :skip
  defp handle_async_result({:ok, val}), do: {:ok, val}
  defp handle_async_result({:exit, reason}), do: {:error, reason}
  defp handle_async_result({:error, reason}), do: {:error, reason}
  defp handle_async_result(_), do: {:error, :unexpected_result}
end
