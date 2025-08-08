defmodule Rujira.Keiko do
  @moduledoc """
  Keiko is the orchestrator contract for the various sale types created via Ventures
  """

  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Keiko.BowConfig
  alias Rujira.Keiko.FinConfig
  alias Rujira.Keiko.PilotConfig
  alias Rujira.Keiko.Sale
  alias Rujira.Keiko.StreamsConfig
  alias Rujira.Keiko.TokenomicsConfig

  use Memoize

  defstruct [
    :id,
    :address,
    :bow,
    :fin,
    :pilot,
    :streams,
    :tokenomics
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          bow: BowConfig.t(),
          fin: FinConfig.t(),
          pilot: PilotConfig.t(),
          streams: StreamsConfig.t(),
          tokenomics: TokenomicsConfig.t()
        }

  def address, do: Deployments.get_target(__MODULE__, "keiko").address
  def load, do: Contracts.get({__MODULE__, address()})

  @spec from_config(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(
        address,
        %{
          "fin" => fin,
          "bow" => bow,
          "pilot" => pilot,
          "streams" => streams,
          "tokenomics" => tokenomics
        }
      ) do
    with {:ok, fin} <- FinConfig.from_query(fin),
         {:ok, bow} <- BowConfig.from_query(bow),
         {:ok, pilot} <- PilotConfig.from_query(pilot),
         {:ok, streams} <- StreamsConfig.from_query(streams),
         {:ok, tokenomics} <- TokenomicsConfig.from_query(tokenomics) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         fin: fin,
         bow: bow,
         pilot: pilot,
         streams: streams,
         tokenomics: tokenomics
       }}
    end
  end

  # TODO Memoize
  def query_sale(idx) do
    with {:ok, venture} <- Contracts.query_state_smart(address(), %{venture: %{idx: idx}}) do
      Sale.from_query(venture)
    end
  end

  def load_sales(owner, status) when is_nil(owner) and is_nil(status),
    do: query_sales(%{ventures: %{}})

  def load_sales(owner, status) when is_nil(owner) and not is_nil(status) do
    with {:ok, sales} <-
           Rujira.Enum.reduce_while_ok(status, &query_sales(%{ventures_by_status: %{status: &1}})) do
      sales =
        sales
        |> List.flatten()
        |> Enum.sort_by(& &1.venture.sale.opens)

      {:ok, sales}
    end
  end

  def load_sales(owner, status) when not is_nil(owner) and is_nil(status),
    do: query_sales(%{ventures_by_owner: %{owner: owner}})

  def load_sales(owner, status) when not is_nil(owner) and not is_nil(status),
    do: {:error, :invalid_filter}

  # TODO Memoize
  def query_sales(query) do
    with {:ok, ventures} <- Contracts.query_state_smart(address(), query) do
      Rujira.Enum.reduce_while_ok(ventures, [], &Sale.from_query/1)
    end
  end

  def validate_token(token) do
    Contracts.query_state_smart(address(), %{validate_token: %{token: token}})
  end

  def validate_tokenomics(token_payload, tokenomics_payload) do
    Contracts.query_state_smart(address(), %{
      validate_tokenomics: %{token: token_payload, tokenomics: tokenomics_payload}
    })
  end

  def validate_venture(venture_payload) do
    Contracts.query_state_smart(address(), %{validate_venture: %{venture: venture_payload}})
  end

  def init_msg(msg), do: msg
  def migrate_msg(_from, _to, _), do: %{}
  def init_label(_, _), do: "rujira-ventures-factory"
end
