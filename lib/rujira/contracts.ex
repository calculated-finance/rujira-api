defmodule Rujira.Contracts do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts
  """
  alias Cosmwasm.Wasm.V1.QueryRawContractStateRequest
  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.CodeInfoResponse
  alias Cosmwasm.Wasm.V1.QueryCodesRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmwasm.Wasm.V1.Query.Stub
  alias Cosmwasm.Wasm.V1.QueryAllContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryContractInfoRequest
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest
  alias Cosmwasm.Wasm.V1.Model
  alias Rujira.Contracts.Contract
  alias Rujira.Repo
  import Ecto.Query
  use Memoize

  defstruct [:id, :address, :info]

  @type t :: %__MODULE__{id: String.t(), address: String.t(), info: ContractInfo.t()}

  def from_id(id) do
    {:ok, %__MODULE__{id: id, address: id}}
  end

  @spec info(String.t()) ::
          {:ok, Cosmwasm.Wasm.V1.ContractInfo.t()} | {:error, GRPC.RPCError.t()}
  defmemo info(address) do
    with {:ok, %{contract_info: contract_info}} <-
           Thorchain.Node.stub(
             &Stub.contract_info/2,
             %QueryContractInfoRequest{address: address}
           ) do
      {:ok, contract_info}
    end
  end

  @spec codes() :: {:ok, list(CodeInfoResponse.t())} | {:error, GRPC.RPCError.t()}
  defmemo codes() do
    codes_page()
  end

  defp codes_page(key \\ nil)

  defp codes_page(nil) do
    with {:ok, %{code_infos: code_infos, pagination: %{next_key: next_key}}} <-
           Thorchain.Node.stub(
             &Stub.codes/2,
             %QueryCodesRequest{}
           ),
         {:ok, next} <- codes_page(next_key) do
      {:ok, Enum.concat(code_infos, next)}
    end
  end

  defp codes_page("") do
    {:ok, []}
  end

  defp codes_page(key) do
    with {:ok, %{code_infos: code_infos, pagination: %{next_key: next_key}}} <-
           Thorchain.Node.stub(
             &Stub.codes/2,
             %QueryCodesRequest{pagination: %PageRequest{key: key}}
           ),
         {:ok, next} <- codes_page(next_key) do
      {:ok, Enum.concat(code_infos, next)}
    end
  end

  @spec by_code(integer()) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  defmemo by_code(code_id) do
    with {:ok, contracts} <- by_code_page(code_id) do
      {:ok, Enum.map(contracts, &%__MODULE__{id: &1, address: &1})}
    end
  end

  defp by_code_page(code_id, key \\ nil)

  defp by_code_page(code_id, nil) do
    with {:ok, %{contracts: contracts, pagination: %{next_key: next_key}}} <-
           Thorchain.Node.stub(
             &Stub.contracts_by_code/2,
             %QueryContractsByCodeRequest{code_id: code_id}
           ),
         {:ok, next} <- by_code_page(code_id, next_key) do
      {:ok, Enum.concat(contracts, next)}
    end
  end

  defp by_code_page(_code_id, "") do
    {:ok, []}
  end

  defp by_code_page(code_id, key) do
    with {:ok, %{contracts: contracts, pagination: %{next_key: next_key}}} <-
           Thorchain.Node.stub(
             &Stub.contracts_by_code/2,
             %QueryContractsByCodeRequest{
               code_id: code_id,
               pagination: %PageRequest{key: key}
             }
           ),
         {:ok, next} <- by_code_page(code_id, next_key) do
      {:ok, Enum.concat(contracts, next)}
    end
  end

  @spec by_codes(list(integer())) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  def by_codes(code_ids) do
    Enum.reduce(code_ids, {:ok, []}, fn
      el, {:ok, agg} ->
        case by_code(el) do
          {:ok, contracts} -> {:ok, agg ++ contracts}
          err -> err
        end

      _, err ->
        err
    end)
  end

  @spec get({module(), String.t() | __MODULE__.t()} | struct()) ::
          {:ok, struct()} | {:error, any()}

  def get({module, %__MODULE__{address: address}}), do: get({module, address})

  def get({module, address}) do
    Memoize.Cache.get_or_run({__MODULE__, :get, [{module, address}]}, fn ->
      with {:ok, config} <- query_state_smart(address, %{config: %{}}),
           {:ok, struct} <- module.from_config(address, config) do
        {:ok, struct}
      end
    end)
  end

  def get(_channel, loaded), do: {:ok, loaded}

  @spec list(module(), list(integer())) ::
          {:ok, list(struct())} | {:error, GRPC.RPCError.t()}
  def list(module, code_ids) when is_list(code_ids) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :list, [module, code_ids]},
      fn ->
        with {:ok, contracts} <- by_codes(code_ids),
             {:ok, struct} <-
               contracts
               |> Task.async_stream(&get({module, &1}), timeout: 30_000)
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

  @spec query_state_raw(String.t(), binary()) ::
          {:ok, term()} | {:error, :not_found} | {:error, GRPC.RPCError.t()}
  def query_state_raw(address, query) do
    case Thorchain.Node.stub(
           &Stub.raw_contract_state/2,
           %QueryRawContractStateRequest{
             address: address,
             query_data: query
           }
         ) do
      {:ok, %{data: ""}} -> {:error, :not_found}
      {:ok, %{data: data}} -> Jason.decode(data)
    end
  end

  @spec query_state_smart(String.t(), map()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  def query_state_smart(address, query) do
    with {:ok, %{data: data}} <-
           Thorchain.Node.stub(
             &Stub.smart_contract_state/2,
             %QuerySmartContractStateRequest{
               address: address,
               query_data: Jason.encode!(query)
             }
           ),
         {:ok, res} <- Jason.decode(data) do
      {:ok, res}
    end
  end

  @doc """
  Queries the full, raw contract state at an address
  """
  @spec query_state_all(String.t()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  def query_state_all(address) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :query_state_all, [address]},
      fn ->
        query_state_all_page(address, nil)
      end
    )
  end

  defp query_state_all_page(address, page) do
    with {:ok, %{models: models, pagination: %{next_key: next_key}}} when next_key != "" <-
           Thorchain.Node.stub(
             &Stub.all_contract_state/2,
             %QueryAllContractStateRequest{address: address, pagination: page}
           ),
         {:ok, next} <-
           query_state_all_page(
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
  def stream_state_all(address) do
    Stream.resource(
      fn ->
        Thorchain.Node.stub(
          &Stub.all_contract_state/2,
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
            Thorchain.Node.stub(
              &Stub.all_contract_state/2,
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

  @spec insert(%Contract{}) :: {:ok, %Contract{}} | {:error, Ecto.Changeset.t()}
  def insert(%Contract{} = contract), do: Repo.insert(contract)

  def insert_all(contracts),
    do: Repo.insert_all(Contract, contracts, on_conflict: :nothing, returning: true)

  @spec by_module(module()) :: list(%Contract{})
  def by_module(module) do
    Contract
    |> where([c], c.module == ^module)
    |> Repo.all()
  end

  @spec by_id(String.t()) :: %Contract{} | nil
  def by_id(id) do
    Contract
    |> where([c], c.id == ^id)
    |> Repo.one()
  end

  @spec list() :: list(%Contract{})
  def list() do
    Contract
    |> Repo.all()
  end

  def insert_info_all(contract_infos) do
    Repo.insert_all("contract_infos", contract_infos, on_conflict: :nothing, returning: true)
  end
end
