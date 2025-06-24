defmodule Rujira.Contracts do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts
  """
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmwasm.Wasm.V1.CodeInfoResponse
  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.Model
  alias Cosmwasm.Wasm.V1.Query.Stub
  alias Cosmwasm.Wasm.V1.QueryAllContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryBuildAddressRequest
  alias Cosmwasm.Wasm.V1.QueryCodeRequest
  alias Cosmwasm.Wasm.V1.QueryCodesRequest
  alias Cosmwasm.Wasm.V1.QueryContractInfoRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest
  alias Cosmwasm.Wasm.V1.QueryRawContractStateRequest
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Rujira.Deployments

  use Memoize
  use GenServer

  def start_link(_) do
    children = [__MODULE__.Listener]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  defstruct [:id, :address, :info]

  @type t :: %__MODULE__{id: String.t(), address: String.t(), info: ContractInfo.t()}

  def from_id(id) do
    {:ok, %__MODULE__{id: id, address: id}}
  end

  @spec code_info(non_neg_integer()) ::
          {:ok, Cosmwasm.Wasm.V1.CodeInfoResponse.t()} | {:error, GRPC.RPCError.t()}
  defmemo code_info(code_id) do
    with {:ok, %{code_info: code_info}} <-
           Thornode.query(
             &Stub.code/2,
             %QueryCodeRequest{code_id: code_id}
           ) do
      {:ok, code_info}
    end
  end

  defmemo build_address(salt, creator, id) when is_integer(id) do
    with {:ok, %{data_hash: data_hash}} <- code_info(id) do
      build_address(salt, creator, Base.encode16(data_hash))
    end
  end

  defmemo build_address(salt, creator, hash) do
    with {:ok, %{address: address}} <-
           Thornode.query(
             &Stub.build_address/2,
             %QueryBuildAddressRequest{
               code_hash: hash,
               creator_address: creator,
               salt: salt
             }
           ) do
      {:ok, address}
    end
  end

  defmemo build_address!(salt, deployer, code_id) do
    {:ok, address} = build_address(salt, deployer, code_id)
    address
  end

  @spec info(String.t()) ::
          {:ok, Cosmwasm.Wasm.V1.ContractInfo.t()} | {:error, GRPC.RPCError.t()}
  defmemo info(address) do
    with {:ok, %{contract_info: contract_info}} <-
           Thornode.query(
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
           Thornode.query(
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
           Thornode.query(
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
           Thornode.query(
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
           Thornode.query(
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

  defmemo(get({module, %__MODULE__{address: address}}), do: get({module, address}))

  defmemo get({module, address}) do
    case query_state_smart(address, %{config: %{}}) do
      {:ok, config} ->
        module.from_config(address, config)

      {:error,
       %GRPC.RPCError{
         status: 2,
         message: "codespace wasm code 22: no such contract: address " <> _
       }} ->
        from_target({module, address})

      err ->
        err
    end
  end

  def from_target({module, address}) do
    case Enum.find(Deployments.list_all_targets(), &(&1.address == address)) do
      nil -> {:error, :not_found}
      x -> module.from_target(x)
    end
  end

  defmemo(get(_channel, loaded), do: {:ok, loaded})

  @spec list(module(), list(integer())) ::
          {:ok, list(struct())} | {:error, GRPC.RPCError.t()}
  defmemo list(module, code_ids) when is_list(code_ids) do
    with {:ok, contracts} <- by_codes(code_ids),
         {:ok, struct} <-
           contracts
           |> Rujira.Enum.reduce_async_while_ok(&get({module, &1}), timeout: 30_000) do
      {:ok, struct}
    else
      err ->
        err
    end
  end

  @spec query_state_raw(String.t(), binary()) ::
          {:ok, term()} | {:error, :not_found} | {:error, GRPC.RPCError.t()}
  def query_state_raw(address, query) do
    case Thornode.query(
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
           Thornode.query(&Stub.smart_contract_state/2, %QuerySmartContractStateRequest{
             address: address,
             query_data: Jason.encode!(query)
           }) do
      Jason.decode(data)
    end
  end

  @doc """
  Queries the full, raw contract state at an address
  """
  @spec query_state_all(String.t()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  defmemo query_state_all(address) do
    query_state_all_page(address, nil)
  end

  defp query_state_all_page(address, page) do
    with {:ok, %{models: models, pagination: %{next_key: next_key}}} when next_key != "" <-
           Thornode.query(
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
        Thornode.query(
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
            Thornode.query(
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
end
