defmodule Rujira.Calc do
  @moduledoc """
  Module for managing automated trading strategies.

  Provides functions to list, retrieve, and load strategy configurations
  from blockchain smart contracts.
  """

  alias Rujira.Calc.Account
  alias Rujira.Calc.Strategy
  alias Rujira.Contracts
  alias Rujira.Deployments

  @doc "Returns the address of the strategy manager contract"
  @spec manager_address() :: String.t()
  def manager_address, do: Deployments.get_target(__MODULE__.Manager, "calc-manager").address

  @doc "Returns the address of the strategy scheduler contract"
  @spec scheduler_address() :: String.t()
  def scheduler_address,
    do: Deployments.get_target(__MODULE__.Scheduler, "calc-scheduler").address

  @doc "Loads a single account with its calc strategies"
  def load_account(address) do
    with {:ok, strategies} <- list_strategies(address) do
      {:ok, %Account{address: address, strategies: strategies}}
    end
  end

  @doc """
  Lists strategies filtered by owner or status.
  """
  @spec list_strategies(String.t() | nil, atom() | nil, pos_integer(), pos_integer() | nil) ::
          {:ok, [Strategy.t()]} | {:error, any()}
  def list_strategies(owner \\ nil, status \\ nil, limit \\ 100, offset \\ nil)

  def list_strategies(owner, nil, limit, offset) when not is_nil(owner) do
    do_list_strategies(%{owner: owner, limit: limit, offset: offset})
  end

  def list_strategies(nil, status, limit, offset) when not is_nil(status) do
    do_list_strategies(%{status: status, limit: limit, offset: offset})
  end

  defp do_list_strategies(params) do
    with {:ok, strategies} <- query_strategies(%{strategies: params}) do
      load_strategies(strategies)
    end
  end

  @doc """
  Retrieves a single strategy by address with its configuration.
  """
  @spec get_strategy(String.t()) :: {:ok, Strategy.t()} | {:error, any()}
  def get_strategy(address) do
    with {:ok, strategy_data} <- query_strategy(address),
         {:ok, strategy} <- Strategy.from_query(strategy_data) do
      query_strategy_config(strategy)
    end
  end

  defp load_strategies(strategies) do
    Rujira.Enum.reduce_while_ok(strategies, [], &load_strategy/1)
  end

  defp load_strategy(strategy_data) do
    with {:ok, strategy} <- Strategy.from_query(strategy_data) do
      query_strategy_config(strategy)
    end
  end

  # Contract queries
  defp query_strategies(query) do
    Contracts.query_state_smart(manager_address(), query)
  end

  defp query_strategy(address) do
    Contracts.query_state_smart(manager_address(), %{strategy: %{address: address}})
  end

  defp query_strategy_config(%Strategy{address: address} = strategy) do
    with {:ok, config} <- Contracts.query_state_smart(address, %{config: %{}}) do
      Strategy.Config.from_config(strategy, config)
    end
  end
end
