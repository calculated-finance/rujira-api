defmodule Rujira.DataMocks.Merge do
  use Rujira.DataMocks

  alias Cosmwasm.Wasm.V1.QuerySmartContractStateResponse
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest

  def request(%QuerySmartContractStateRequest{
        address: "contract-merge",
        query_data: "{\"config\":{}}"
      }) do
    {:ok, :config_response}
  end

  def request(_), do: :error

  def response(:config_response) do
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

  def response(_), do: {:error, "No response defined"}
end
