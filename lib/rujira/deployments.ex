defmodule Rujira.Deployments do
  @moduledoc "Migrates "
  alias Rujira.Ventures
  alias Rujira.Deployments.Target
  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.MsgMigrateContract
  alias Cosmwasm.Wasm.V1.MsgInstantiateContract2
  alias Rujira.Revenue
  alias Rujira.Bow
  alias Rujira.Fin
  alias Rujira.Merge
  alias Rujira.Staking
  alias Rujira.Contracts
  use Memoize

  @path "data/deployments"
  @plan Application.compile_env(:rujira, __MODULE__, plan: "stagenet/v1")
        |> Keyword.get(:plan)

  def get_target(module, id, plan \\ @plan) do
    %{codes: codes, targets: targets} = load_config!(plan)

    targets
    |> Enum.flat_map(&parse_protocol(codes, &1))
    |> Enum.find(&(&1.module === module and &1.id == id))
  end

  def list_all_targets(plan \\ @plan) do
    %{codes: codes, targets: targets} = load_config!(plan)

    targets
    |> Enum.flat_map(&parse_protocol(codes, &1))
  end

  def list_targets(module, plan \\ @plan) do
    plan
    |> list_all_targets()
    |> Enum.filter(&(&1.module === module))
  end

  defmemo load_config!(plan \\ @plan) do
    %{"accounts" => accounts, "codes" => codes, "targets" => targets} =
      :rujira
      |> :code.priv_dir()
      |> Path.join(@path)
      |> Path.join("#{plan}.yaml")
      |> File.read!()
      |> YamlElixir.read_from_string!()

    # Do accounts first, so they're available for contract interpolation
    %{accounts: accounts} = parse_ctx(%{accounts: accounts}, %{})

    parse_ctx(
      %{accounts: accounts, codes: codes, targets: targets},
      %{accounts: accounts, codes: codes, targets: targets}
    )
  end

  defp parse_protocol(codes, {protocol, configs}) do
    Enum.map(configs, &parse_contract(codes, protocol, &1))
  end

  defp parse_contract(
         codes,
         protocol,
         %{
           "id" => id,
           "admin" => admin,
           "creator" => creator,
           "config" => config
         } = item
       ) do
    code_id = Map.get(codes, protocol)
    salt = build_address_salt(protocol, id)

    address = Map.get(item, "address", Contracts.build_address!(salt, creator, code_id))

    contract =
      case Contracts.info(address) do
        {:ok, info} -> info
        _ -> nil
      end

    %Target{
      id: id,
      address: address,
      creator: creator,
      code_id: code_id,
      salt: salt,
      admin: admin,
      protocol: protocol,
      module: to_module(protocol),
      config: config,
      contract: contract
    }
  end

  # Existing contract, no change, ignore
  def to_msg(%{code_id: target_code_id, contract: %ContractInfo{code_id: code_id}})
      when target_code_id == code_id,
      do: nil

  # Existing contract, change, migrate
  def to_msg(%{
        address: address,
        module: module,
        code_id: target_code_id,
        admin: admin,
        config: config,
        contract: %ContractInfo{code_id: code_id}
      }) do
    %MsgMigrateContract{
      sender: admin,
      code_id: to_string(target_code_id),
      contract: address,
      msg: module.migrate_msg(code_id, target_code_id, config)
    }
  end

  # No contract, no change, instantiate
  def to_msg(%{
        module: module,
        code_id: code_id,
        config: config,
        salt: salt,
        admin: admin
      }) do
    %MsgInstantiateContract2{
      sender: admin,
      admin: admin,
      code_id: to_string(code_id),
      msg: module.init_msg(config),
      # TODO: update once any of the targets need funds on init
      funds: [],
      label: module.init_label(config),
      salt: Base.encode64(Base.decode16!(salt))
    }
  end

  defp to_module("bow"), do: Bow
  defp to_module("fin"), do: Fin.Pair
  defp to_module("revenue"), do: Revenue.Converter
  defp to_module("staking"), do: Staking.Pool
  defp to_module("keiko"), do: Ventures.Keiko

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

  def parse_arg("targets:" <> id, %{targets: targets, codes: codes} = ctx) do
    [protocol, id] = String.split(id, ".")
    code_id = Map.get(codes, protocol)

    creator =
      targets
      |> Map.get(protocol)
      |> Enum.find(&(&1["id"] == id))
      |> Map.get("creator")
      |> interpolate_string(ctx)

    protocol |> build_address_salt(id) |> Contracts.build_address!(creator, code_id)
  end

  def parse_arg("accounts:" <> id, %{accounts: accounts}), do: Map.get(accounts, id)
  def parse_arg("env:" <> id, _), do: System.get_env(id)
  def parse_arg(x, _), do: x

  def build_address_salt(protocol, id), do: Base.encode16("#{protocol}:#{id}")

  def to_migrate_tx(plan \\ @plan) do
    %{codes: codes, targets: targets} = load_config!(plan)

    messages =
      targets
      |> Enum.flat_map(&parse_protocol(codes, &1))
      |> Enum.map(fn x -> Map.put(x, :msg, to_msg(x)) end)
      |> Enum.reduce([], fn
        %{msg: nil}, a ->
          a

        %{msg: %struct{} = msg}, a ->
          name = struct |> to_string() |> String.split(".") |> Enum.at(-1)

          [
            msg
            |> Map.from_struct()
            |> Map.delete(:__unknown_fields__)
            |> Map.delete(:fix_msg)
            |> Map.put("@type", "/cosmwasm.wasm.v1.#{name}")
            | a
          ]
      end)

    %{
      body: %{
        messages: messages,
        memo: "",
        timeout_height: "0",
        extension_options: [],
        non_critical_extension_options: []
      },
      auth_info: %{
        signer_infos: [],
        fee: %{amount: [], gas_limit: "1000000", payer: "", granter: ""},
        tip: nil
      },
      signatures: []
    }
    |> Jason.encode!(pretty: true)
  end
end
