defmodule Rujira.Fixtures.Block do
  @moduledoc """
  Helpers for dumping and loading Thorchain block fixtures
  with full Elixir types preserved.
  """

  @doc """
  Dump the result of `Thorchain.block(height)` to
  `test/fixtures/blocks/<network>_<name>.term`.

  Example:
      iex> Rujira.Fixtures.Block.dump_block("balances", "42123")
      :ok
  """
  @spec dump_block(height :: String.t()) :: :ok | {:error, term()}
  def dump_block(height) when is_binary(height) do
    network  = Application.get_env(:rujira, :network)
    base_name = "#{network}_#{height}"
    term_path = Path.join(__DIR__, base_name <> ".term")
    txt_path  = Path.join(__DIR__, base_name <> ".txt")

    with {:ok, block} <- Thorchain.block(height) do
      File.mkdir_p!(Path.dirname(term_path))
      File.write!(term_path, :erlang.term_to_binary(block))

      # human readable version of the block for debugging
      text = inspect(block, pretty: true, limit: :infinity, width: 80)
      File.write!(txt_path, text)
    end
  end

  @doc """
  Load the previously dumped `.term` fixture and return
  the exact same Elixir term you dumped.

  Example:
      iex> {:ok, block} = Rujira.Fixtures.Block.load_block("4573812")
      iex> block.header.time
      #DateTime<...>
  """
  @spec load_block(height :: String.t()) :: {:ok, any()} | {:error, term()}
  def load_block(height) when is_binary(height) do
    network  = Application.get_env(:rujira, :network)
    filename = "#{network}_#{height}.term"
    path     = Path.join(__DIR__, filename)

    case File.read(path) do
      {:ok, binary} ->
        {:ok, :erlang.binary_to_term(binary)}

      error ->
        error
    end
  end
end
