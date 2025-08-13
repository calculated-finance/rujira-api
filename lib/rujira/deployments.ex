defmodule Rujira.Deployments do
  @moduledoc "Migrates "
  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.MsgInstantiateContract2
  alias Cosmwasm.Wasm.V1.MsgMigrateContract
  alias Rujira.Bow
  alias Rujira.Contracts
  alias Rujira.Deployments.Target
  alias Rujira.Deployments.Target
  alias Rujira.Fin
  alias Rujira.Ghost
  alias Rujira.Index
  alias Rujira.Keiko
  alias Rujira.Perps
  alias Rujira.Revenue
  alias Rujira.Staking
  alias Rujira.Vestings

  use GenServer
  use Memoize

  @path "data/deployments"

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    list_all_targets()
    {:ok, state}
  end

  def network, do: Application.get_env(:rujira, :network, "stagenet")

  defmemo get_target(module, id, network \\ network()) do
    list_all_targets(network)
    |> Enum.find(&(&1.module === module and &1.id == id))
  end

  defmemo list_all_targets(network \\ network()) do
    %{codes: codes, targets: targets} = load_config!(network)

    with {:ok, result} <-
           Rujira.Enum.reduce_async_while_ok(
             targets,
             &parse_protocol(codes, &1)
           ) do
      List.flatten(result)
    end
  end

  @doc """
  List all targets for a given module
  """
  defmemo list_targets(module, network \\ network()) do
    network
    |> list_all_targets()
    |> Enum.filter(&(&1.module === module))
  end

  defmemo load_config!(network \\ network()) do
    deploy_dir =
      :rujira
      |> :code.priv_dir()
      |> Path.join(@path)
      |> Path.join(network)

    yaml_files =
      deploy_dir
      |> Path.join("contracts")
      |> File.ls!()

    {codes, targets} =
      Enum.reduce(yaml_files, {%{}, %{}}, fn file, {codes_acc, targets_acc} ->
        key = String.replace_suffix(file, ".yaml", "")
        full_path = deploy_dir |> Path.join("contracts") |> Path.join(file)

        %{"code" => code_id, "targets" => targets_list} = YamlElixir.read_from_file!(full_path)
        {Map.put(codes_acc, key, code_id), Map.put(targets_acc, key, targets_list)}
      end)

    # Load accounts.yaml separately
    accounts =
      deploy_dir
      |> Path.join("accounts.yaml")
      |> YamlElixir.read_from_file!()
      |> Map.fetch!("accounts")

    # Do accounts first, so they're available for contract interpolation
    %{accounts: parsed_accounts} = parse_ctx(%{accounts: accounts}, %{})

    parse_ctx(
      %{accounts: parsed_accounts, codes: codes, targets: targets},
      %{accounts: parsed_accounts, codes: codes, targets: targets}
    )
  end

  defp parse_protocol(codes, {protocol, configs}) do
    with {:ok, result} <-
           Rujira.Enum.reduce_async_while_ok(
             configs,
             &parse_contract(codes, protocol, &1)
           ) do
      result
    end
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
      contract: contract,
      status:
        case contract do
          nil -> :preview
          _ -> :live
        end
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
        id: id,
        module: module,
        code_id: code_id,
        config: config,
        salt: salt,
        admin: admin,
        creator: creator
      }) do
    %MsgInstantiateContract2{
      sender: creator,
      admin: admin,
      code_id: to_string(code_id),
      msg: module.init_msg(config),
      funds: [],
      label: module.init_label(id, config),
      salt: Base.encode64(Base.decode16!(salt))
    }
  end

  defp to_module("rujira-bow"), do: Bow
  defp to_module("rujira-fin"), do: Fin.Pair
  defp to_module("rujira-revenue"), do: Revenue.Converter
  defp to_module("rujira-staking"), do: Staking.Pool
  defp to_module("rujira-ghost-vault"), do: Ghost.Vault
  defp to_module("rujira-keiko"), do: Keiko
  defp to_module("nami-index-nav"), do: Index.Nav
  defp to_module("nami-index-fixed"), do: Index.Fixed
  defp to_module("nami-index-entry-adpter"), do: Index.EntryAdapter
  defp to_module("rujira-perps"), do: Perps.Pool
  defp to_module("daodao-payroll-factory"), do: Vestings

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

  # Deployment straucture was updated, retain old format for backwards compatibility
  def build_address_salt("rujira-" <> protocol, id), do: Base.encode16("#{protocol}:#{id}")
  def build_address_salt("nami-" <> protocol, id), do: Base.encode16("#{protocol}:#{id}")
  def build_address_salt(protocol, id), do: Base.encode16("#{protocol}:#{id}")

  def to_migrate_tx(network \\ network()) do
    %{codes: codes, targets: targets} = load_config!(network)

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
