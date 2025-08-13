defmodule Rujira.Ghost.Vault do
  @moduledoc """
  Defines the structure of a Ghost lending vault
  """
  alias Rujira.Deployments.Target
  alias Rujira.Assets

  defmodule Interest do
    @moduledoc """
    Defines structure of the interest model applies to vault deposits and borrows
    """
    defstruct [:target_utilization, :base_rate, :step1, :step2]

    @type t :: %__MODULE__{
            target_utilization: Decimal.t(),
            base_rate: Decimal.t(),
            step1: Decimal.t(),
            step2: Decimal.t()
          }

    def from_query(%{
          "base_rate" => base_rate,
          "step1" => step1,
          "step2" => step2,
          "target_utilization" => target_utilization
        }) do
      with {base_rate, ""} <- Decimal.parse(base_rate),
           {step1, ""} <- Decimal.parse(step1),
           {step2, ""} <- Decimal.parse(step2),
           {target_utilization, ""} <- Decimal.parse(target_utilization) do
        {:ok,
         %__MODULE__{
           base_rate: base_rate,
           step1: step1,
           step2: step2,
           target_utilization: target_utilization
         }}
      end
    end
  end

  defmodule Status do
    @moduledoc """
    Defines structure of a lending vault status
    """
    defmodule Pool do
      @moduledoc """
      Defines structure of a lending vault share pool
      """
      defstruct [:size, :shares, :ratio]

      @type t :: %__MODULE__{
              size: non_neg_integer(),
              shares: non_neg_integer(),
              ratio: Decimal.t()
            }

      def from_query(%{"ratio" => ratio, "shares" => shares, "size" => size}) do
        with {ratio, ""} <- Decimal.parse(ratio),
             {shares, ""} <- Integer.parse(shares),
             {size, ""} <- Integer.parse(size) do
          {:ok, %__MODULE__{ratio: ratio, shares: shares, size: size}}
        end
      end
    end

    defstruct [
      :last_updated,
      :utilization_ratio,
      :debt_rate,
      :lend_rate,
      :debt_pool,
      :deposit_pool
    ]

    @type t :: %__MODULE__{
            last_updated: DateTime.t(),
            utilization_ratio: Decimal.t(),
            debt_rate: Decimal.t(),
            lend_rate: Decimal.t(),
            debt_pool: Pool.t(),
            deposit_pool: Pool.t()
          }

    def from_query(%{
          "debt_pool" => debt_pool,
          "debt_rate" => debt_rate,
          "deposit_pool" => deposit_pool,
          "last_updated" => last_updated,
          "lend_rate" => lend_rate,
          "utilization_ratio" => utilization_ratio
        }) do
      with {:ok, debt_pool} <- Pool.from_query(debt_pool),
           {debt_rate, ""} <- Decimal.parse(debt_rate),
           {:ok, deposit_pool} <- Pool.from_query(deposit_pool),
           {last_updated, ""} <- Integer.parse(last_updated),
           {:ok, last_updated} <- DateTime.from_unix(last_updated, :nanosecond),
           {lend_rate, ""} <- Decimal.parse(lend_rate),
           {utilization_ratio, ""} <- Decimal.parse(utilization_ratio) do
        {:ok,
         %__MODULE__{
           debt_pool: debt_pool,
           debt_rate: debt_rate,
           deposit_pool: deposit_pool,
           last_updated: last_updated,
           lend_rate: lend_rate,
           utilization_ratio: utilization_ratio
         }}
      end
    end
  end

  defstruct [:id, :address, :denom, :interest, :status, :deployment_status]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          denom: String.t(),
          interest: Interest.t(),
          status: Status.t() | :not_loaded,
          deployment_status: Target.status()
        }

  def from_config(address, %{
        "denom" => denom,
        "interest" => interest
      }) do
    with {:ok, interest} <- Interest.from_query(interest) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         denom: denom,
         interest: interest
       }}
    end
  end

  def from_target(%{
        address: address,
        status: deployment_status,
        config: %{"denom" => denom}
      }) do
    with {:ok, vault} <-
           from_config(address, %{
             "denom" => denom,
             "interest" => %{
               "target_utilization" => "0.8",
               "base_rate" => "0.03",
               "step1" => "0.1",
               "step2" => "2"
             }
           }) do
      {:ok, %{vault | deployment_status: deployment_status}}
    end
  end

  def init_msg(%{"denom" => denom}) do
    {:ok, asset} = Assets.from_denom(denom)

    %{
      denom: denom,
      interest: %{
        target_utilization: "0.8",
        base_rate: "0.03",
        step1: "0.1",
        step2: "2"
      },
      receipt: %{
        description:
          "Transferable shares issued when depositing funds into the Rujira #{Assets.short_id(asset)} lending pool",
        display: "x/ghost-vault/#{denom}",
        name: "#{Assets.short_id(asset)} Lend Shares",
        symbol: "LEND-#{Assets.short_id(asset)}"
      }
    }
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(_, %{"denom" => denom}), do: "rujira-ghost-vault:#{denom}"
end
