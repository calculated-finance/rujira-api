defmodule Rujira.Bow do
  @moduledoc """
  Rujira Bow - AMM pools.
  """

  alias Rujira.Contracts
  alias Rujira.Bow.Xyk
  # use GenServer

  @code_ids Application.compile_env(:rujira, __MODULE__, code_ids: [110])
            |> Keyword.get(:code_ids)

  # def start_link(_) do
  #   Supervisor.start_link([__MODULE__.Listener], strategy: :one_for_one)
  # end

  # @impl true
  # def init(state) do
  #   {:ok, state}
  # end

  @doc """
  Fetches all Bow Pools
  """

  @spec list_pools(list(integer())) ::
          {:ok, list(Xyk.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(code_ids \\ @code_ids) when is_list(code_ids) do
    with {:ok, contracts} <- Contracts.by_codes(@code_ids) do
      contracts
      |> Task.async_stream(&load_pool/1, timeout: 30_000)
      |> Enum.reduce({:ok, []}, fn
        {:ok, {:ok, x}}, {:ok, xs} ->
          {:ok, [x | xs]}

        _, err ->
          err
      end)
    end
  end

  @doc """
  Fetches the Merge Pool contract and its current config from the chain
  """

  def load_pool(%{address: address}) do
    case Contracts.query_state_smart(address, %{strategy: %{}}) do
      {:ok, %{"xyk" => xyk}} -> Xyk.from_query(address, xyk)
      {:error, err} -> {:error, err}
    end
  end

  def pool_from_id(id) do
    load_pool(id)
  end
end
