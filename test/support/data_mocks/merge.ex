defmodule Rujira.DataMocks.Merge do
  use Rujira.DataMocks

  alias Cosmwasm.Wasm.V1.QuerySmartContractStateResponse
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeResponse

  def request(%QueryContractsByCodeRequest{
        code_id: 31
      }) do
    {:ok, :contract_by_code}
  end

  def request(%QuerySmartContractStateRequest{
        address: "contract-merge-1",
        query_data: "{\"config\":{}}"
      }) do
    {:ok, :config_response_1}
  end

  def request(%QuerySmartContractStateRequest{
        address: "contract-merge-2",
        query_data: "{\"config\":{}}"
      }) do
    {:ok, :config_response_2}
  end

  def request(%QuerySmartContractStateRequest{
        address: "contract-merge-1",
        query_data: "{\"status\":{}}"
      }) do
    {:ok, :status_response_1}
  end

  def request(%QuerySmartContractStateRequest{
        address: "contract-merge-2",
        query_data: "{\"status\":{}}"
      }) do
    {:ok, :status_response_2}
  end

  def request(_), do: :error

  def response(:contract_by_code) do
    {:ok,
     %QueryContractsByCodeResponse{
       contracts: ["contract-merge-1", "contract-merge-2"],
       pagination: %Cosmos.Base.Query.V1beta1.PageResponse{
         next_key: "",
         total: 2
       }
     }}
  end

  def response(:config_response_1) do
    {:ok,
     %QuerySmartContractStateResponse{
       data:
         Jason.encode!(%{
           merge_denom: "gaia-kuji",
           merge_supply: "1000000000",
           ruji_denom: "rune",
           ruji_allocation: "10000000000",
           decay_starts_at: "1733424430000000000",
           decay_ends_at: "1764874030000000000"
         })
     }}
  end

  def response(:config_response_2) do
    {:ok,
     %QuerySmartContractStateResponse{
       data:
         Jason.encode!(%{
           merge_denom: "gaia-kuji",
           merge_supply: "2000000000",
           ruji_denom: "ruji",
           ruji_allocation: "30000000000",
           decay_starts_at: "1733424430000000000",
           decay_ends_at: "1764874030000000000"
         })
     }}
  end

  def response(:status_response_1) do
    {:ok,
     %QuerySmartContractStateResponse{
       data:
         Jason.encode!(%{
           merged: "1",
           shares: "1",
           size: "2"
         })
     }}
  end

  def response(:status_response_2) do
    {:ok,
     %QuerySmartContractStateResponse{
       data:
         Jason.encode!(%{
           merged: "2",
           shares: "3",
           size: "4"
         })
     }}
  end

  def response(_), do: {:error, "No response defined"}
end
