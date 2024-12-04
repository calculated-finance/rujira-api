defmodule Rujira.Contract do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts
  """
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmwasm.Wasm.V1.Query.Stub
  alias Cosmwasm.Wasm.V1.QueryAllContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryContractInfoRequest
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest
  alias Cosmwasm.Wasm.V1.Model

  @spec info(GRPC.Channel.t(), String.t()) ::
          {:ok, Cosmwasm.Wasm.V1.ContractInfo.t()} | {:error, GRPC.RPCError.t()}
  def info(channel, address) do
    with {:ok, %{contract_info: contract_info}} <-
           Stub.contract_info(
             channel,
             %QueryContractInfoRequest{address: address}
           ) do
      {:ok, contract_info}
    end
  end

  @spec by_code(GRPC.Channel.t(), integer()) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  def by_code(channel, code_id) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :by_code, [code_id]},
      fn ->
        by_code_page(channel, code_id)
      end
    )
  end

  defp by_code_page(channel, code_id, key \\ nil)

  defp by_code_page(channel, code_id, nil) do
    with {:ok, %{contracts: contracts, pagination: %{next_key: next_key}}} <-
           Stub.contracts_by_code(
             channel,
             %QueryContractsByCodeRequest{code_id: code_id}
           ),
         {:ok, next} <- by_code_page(channel, code_id, next_key) do
      {:ok, Enum.concat(contracts, next)}
    end
  end

  defp by_code_page(_channel, _code_id, "") do
    {:ok, []}
  end

  defp by_code_page(channel, code_id, key) do
    with {:ok, %{contracts: contracts, pagination: %{next_key: next_key}}} <-
           Stub.contracts_by_code(
             channel,
             %QueryContractsByCodeRequest{
               code_id: code_id,
               pagination: %PageRequest{key: key}
             }
           ),
         {:ok, next} <- by_code_page(channel, code_id, next_key) do
      {:ok, Enum.concat(contracts, next)}
    end
  end

  @spec by_codes(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  def by_codes(channel, code_ids) do
    Enum.reduce(code_ids, {:ok, []}, fn
      el, {:ok, agg} ->
        case by_code(channel, el) do
          {:ok, contracts} -> {:ok, agg ++ contracts}
          err -> err
        end

      _, err ->
        err
    end)
  end

  @spec get(Channel.t(), {module(), String.t()} | struct()) ::
          {:ok, struct()} | {:error, any()}
  def get(channel, {module, address}) do
    Memoize.Cache.get_or_run({__MODULE__, :get, [{module, address}]}, fn ->
      with {:ok, config} <- query_state_smart(channel, address, %{config: %{}}),
           {:ok, struct} <- module.from_config(channel, address, config) do
        {:ok, struct}
      end
    end)
  end

  def get(_channel, loaded), do: {:ok, loaded}

  @spec list(GRPC.Channel.t(), module(), list(integer())) ::
          {:ok, list(struct())} | {:error, GRPC.RPCError.t()}
  def list(channel, module, code_ids) when is_list(code_ids) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :list, [module, code_ids]},
      fn ->
        with {:ok, contracts} <- by_codes(channel, code_ids),
             {:ok, struct} <-
               contracts
               |> Task.async_stream(&get(channel, {module, &1}), timeout: 30_000)
               |> Enum.reduce({:ok, []}, fn
                 {:ok, {:ok, x}}, {:ok, xs} ->
                   {:ok, [x | xs]}

                 _, err ->
                   err
               end) do
          {:ok, struct}
        else
          err ->
            err
        end
      end
    )
  end

  @spec query_state_smart(GRPC.Channel.t(), String.t(), map()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  def query_state_smart(channel, address, query) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :query_state_smart, [address, query]},
      fn ->
        with {:ok, %{data: data}} <-
               Stub.smart_contract_state(
                 channel,
                 %QuerySmartContractStateRequest{
                   address: address,
                   query_data: Jason.encode!(query)
                 }
               ),
             {:ok, res} <- Jason.decode(data) do
          {:ok, res}
        end
      end
    )
  end

  @doc """
  Queries the full, raw contract state at an address
  """
  @spec query_state_all(GRPC.Channel.t(), String.t()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  def query_state_all(channel, address) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :query_state_all, [address]},
      fn ->
        query_state_all_page(channel, address, nil)
      end
    )
  end

  defp query_state_all_page(channel, address, page) do
    with {:ok, %{models: models, pagination: %{next_key: next_key}}} when next_key != "" <-
           Stub.all_contract_state(
             channel,
             %QueryAllContractStateRequest{address: address, pagination: page}
           ),
         {:ok, next} <-
           query_state_all_page(
             channel,
             address,
             %PageRequest{key: next_key}
           ) do
      {:ok, decode_models(models, next)}
    else
      {:ok, %{models: models, pagination: %{next_key: nil}}} ->
        {:ok, decode_models(models)}

      {:ok, %{models: models, pagination: %{next_key: ""}}} ->
        {:ok, decode_models(models)}

      err ->
        err
    end
  end

  @doc """
  Streams the current contract state
  """
  def stream_state_all(channel, address) do
    Stream.resource(
      fn ->
        Stub.all_contract_state(
          channel,
          %QueryAllContractStateRequest{address: address}
        )
      end,
      fn
        # We're on the last item and there's another page. Return that item and fetch the next page
        {:ok,
         %{
           models: [%{value: value}],
           pagination: %{next_key: next_key}
         }}
        when next_key != "" ->
          next =
            Stub.all_contract_state(
              channel,
              %QueryAllContractStateRequest{
                address: address,
                pagination: %PageRequest{key: next_key}
              }
            )

          {[Jason.decode!(value)], next}

        # Whilst we have items in the list, keep going
        {:ok, %{models: [%{value: value} | xs]} = agg} ->
          {[Jason.decode!(value)], {:ok, %{agg | models: xs}}}

        # We're done, last page
        {:ok, %{models: [], pagination: %{next_key: ""}}} = acc ->
          {:halt, acc}
      end,
      fn _ -> nil end
    )
  end

  defp decode_models(models, init \\ %{}) do
    Enum.reduce(models, init, fn %Model{} = model, agg ->
      Map.put(agg, model.key, Jason.decode!(model.value))
    end)
  end
end
