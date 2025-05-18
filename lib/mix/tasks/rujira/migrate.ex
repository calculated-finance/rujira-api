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

  def run([plan]) do
    Mix.Task.run("app.start")
    %{codes: codes, contracts: contracts} = load_config!(plan)

    contracts
    |> Enum.flat_map(fn {protocol, configs} ->
      Enum.map(configs, fn %{
                             "id" => id,
                             "admin" => admin,
                             "creator" => creator,
                             "config" => config
                           } ->
        code_id = Map.get(codes, protocol)
        salt = build_address_salt(protocol, id)

        address = Contracts.build_address!(salt, creator, code_id)

        contract =
          case Contracts.info(address) do
            {:ok, info} -> info
            _ -> nil
          end

        %{
          address: address,
          creator: creator,
          code_id: code_id,
          salt: salt,
          admin: admin,
          protocol: protocol,
          config: config,
          contract: contract
        }
      end)
    end)
    |> Enum.map(fn x -> Map.put(x, :msg, to_msg(x)) end)
    |> IO.inspect()
  end

  defp load_config!(plan) do
    %{"accounts" => accounts, "codes" => codes, "contracts" => contracts} =
      :rujira
      |> :code.priv_dir()
      |> Path.join("data/plans")
      |> Path.join(plan)
      |> File.read!()
      |> YamlElixir.read_from_string!()

    # Do accounts first, so they're available for contract interpolation
    %{accounts: accounts} = parse_ctx(%{accounts: accounts}, %{})
    IO.inspect(accounts)

    parse_ctx(
      %{accounts: accounts, codes: codes, contracts: contracts},
      %{accounts: accounts, codes: codes, contracts: contracts}
    )
  end

  # Existing contract, no change, ignore
  defp to_msg(%{code_id: target_code_id, contract: %ContractInfo{code_id: code_id}})
       when target_code_id == code_id,
       do: nil

  # Existing contract, change, migrate
  defp to_msg(%{
         protocol: protocol,
         code_id: target_code_id,
         admin: admin,
         config: config,
         contract: %ContractInfo{code_id: code_id}
       }) do
    %MsgMigrateContract{
      sender: admin,
      code_id: target_code_id,
      msg: to_migrate_msg(protocol, code_id, target_code_id, config)
    }
  end

  # No contract, no change, instantiate
  defp to_msg(%{
         protocol: protocol,
         code_id: code_id,
         config: config,
         salt: salt,
         admin: admin
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

  defp to_module("bow"), do: Bow
  defp to_module("fin"), do: Fin.Pair
  defp to_module("revenue"), do: Revenue.Converter
  defp to_module("staking"), do: Staking.Pool

  defp to_init_msg(protocol, config), do: to_module(protocol).init_msg(config)

  defp to_migrate_msg(protocol, from, to, config),
    do: to_module(protocol).migrate_msg(from, to, config)

  defp to_init_label(protocol, config), do: to_module(protocol).init_label(config)

  defp parse_ctx(map, ctx) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {k, parse_ctx(v, ctx)} end)
    |> Enum.into(%{})
  end

  defp parse_ctx(v, ctx) when is_list(v), do: Enum.map(v, &parse_ctx(&1, ctx))
  defp parse_ctx(v, ctx) when is_binary(v), do: interpolate_string(v, ctx)
  defp parse_ctx(v, _), do: v

  defp interpolate_string(str, ctx) do
    case Regex.run(~r/^\${(.*)}$/, str) do
      nil -> str
      [_, x] -> parse_arg(x, ctx)
    end
  end

  def parse_arg("contracts:" <> id, %{contracts: contracts, codes: codes} = ctx) do
    [protocol, id] = String.split(id, ".")
    code_id = Map.get(codes, protocol)

    creator =
      contracts
      |> Map.get(protocol)
      |> Enum.find(&(&1["id"] == id))
      |> Map.get("creator")
      |> interpolate_string(ctx)

    protocol |> build_address_salt(id) |> Contracts.build_address!(creator, code_id)
  end

  def parse_arg("accounts:" <> id, %{accounts: accounts}) do
    Map.get(accounts, id)
  end

  def parse_arg("env:" <> id, _) do
    System.get_env(id)
  end

  def parse_arg(x, _), do: x

  def build_address_salt(protocol, id), do: Base.encode16("#{protocol}:#{id}")
end
