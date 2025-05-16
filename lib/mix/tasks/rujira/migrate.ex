defmodule Mix.Tasks.Rujira.Migrate do
  @moduledoc "Migrates "
  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.MsgMigrateContract
  alias Cosmwasm.Wasm.V1.MsgInstantiateContract2
  alias Rujira.Revenue
  alias Rujira.Bow
  alias Rujira.Fin
  alias Rujira.Staking
  alias Rujira.Contracts
  use Mix.Task

  @deployer "sthor1a3xfqx4yt4yhymhm22m36huuh3eklf49umhj6v"

  def run([plan]) do
    Mix.Task.run("app.start")
    %{"codes" => codes, "contracts" => contracts} = load_config!(plan)

    contracts
    |> Enum.flat_map(fn {protocol, configs} ->
      Enum.map(configs, fn %{"id" => id} = v ->
        code_id = Map.get(codes, protocol)

        %{
          code_id: code_id,
          protocol: protocol,
          config: v,
          contract: contract(protocol, @deployer, code_id, id)
        }
      end)
    end)
    |> Enum.reduce([], fn e, a ->
      case to_msg(e) do
        nil -> a
        msg -> [msg | a]
      end
    end)
    |> IO.inspect()
  end

  defp load_config!(plan) do
    :rujira
    |> :code.priv_dir()
    |> Path.join("data/plans")
    |> Path.join(plan)
    |> File.read!()
    |> YamlElixir.read_from_string!()
  end

  defp contract(protocol, deployer, code_id, id) do
    salt = Base.encode16("#{protocol}:#{id}")
    address = contract_address!(code_id, deployer, salt)

    case Contracts.info(address) do
      {:ok, contract} -> contract
      _ -> %{address: address, salt: salt}
    end
  end

  defp contract_address!(code_id, deployer, salt) do
    {:ok, address} =
      Contracts.build_address(code_id, deployer, salt)

    address
  end

  defp to_msg(%{code_id: target_code_id, contract: %ContractInfo{code_id: code_id}})
       when target_code_id == code_id,
       do: nil

  defp to_msg(%{
         protocol: protocol,
         code_id: target_code_id,
         config: %{"admin" => admin} = config,
         contract: %ContractInfo{code_id: code_id}
       }) do
    %MsgMigrateContract{
      sender: admin,
      code_id: target_code_id,
      msg: to_migrate_msg(protocol, code_id, target_code_id, config)
    }
  end

  defp to_msg(%{
         protocol: protocol,
         code_id: code_id,
         config: %{"admin" => admin} = config,
         contract: %{salt: salt}
       }) do
    %MsgInstantiateContract2{
      sender: admin,
      admin: admin,
      code_id: code_id,
      msg: to_init_msg(protocol, config),
      # TODO: update once any of the contracts need funds on init
      funds: [],
      label: to_init_label(protocol, config),
      salt: salt
    }
  end

  defp to_init_msg("bow", config), do: Bow.init_msg(config)
  defp to_init_msg("fin", config), do: Fin.Pair.init_msg(config)
  defp to_init_msg("revenue", config), do: Revenue.Converter.init_msg(config)
  defp to_init_msg("staking", config), do: Staking.Pool.init_msg(config)

  defp to_migrate_msg("bow", from, to, config), do: Bow.migrate_msg(from, to, config)
  defp to_migrate_msg("fin", from, to, config), do: Fin.Pair.migrate_msg(from, to, config)

  defp to_migrate_msg("revenue", from, to, config),
    do: Revenue.Converter.migrate_msg(from, to, config)

  defp to_migrate_msg("staking", from, to, config), do: Staking.Pool.migrate_msg(from, to, config)

  defp to_init_label("bow", config), do: Bow.init_label(config)
  defp to_init_label("fin", config), do: Fin.Pair.init_label(config)
  defp to_init_label("revenue", config), do: Revenue.Converter.init_label(config)
  defp to_init_label("staking", config), do: Staking.Pool.init_label(config)
end
