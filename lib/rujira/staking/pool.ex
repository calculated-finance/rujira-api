defmodule Rujira.Staking.Pool do
  defmodule Status do
    defstruct [
      :id,
      :account_bond,
      :account_revenue,
      :liquid_bond_shares,
      :liquid_bond_size,
      :pending_revenue
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            account_bond: integer(),
            account_revenue: integer(),
            liquid_bond_shares: integer(),
            liquid_bond_size: integer(),
            pending_revenue: integer()
          }

    @spec from_query(String.t(), map()) :: {:ok, __MODULE__.t()} | {:error, :parse_error}
    def from_query(address, %{
          "account_bond" => account_bond,
          "assigned_revenue" => account_revenue,
          "liquid_bond_shares" => liquid_bond_shares,
          "liquid_bond_size" => liquid_bond_size,
          "undistributed_revenue" => pending_revenue
        }) do
      with {account_bond, ""} <- Integer.parse(account_bond),
           {account_revenue, ""} <- Integer.parse(account_revenue),
           {liquid_bond_shares, ""} <- Integer.parse(liquid_bond_shares),
           {liquid_bond_size, ""} <- Integer.parse(liquid_bond_size),
           {pending_revenue, ""} <- Integer.parse(pending_revenue) do
        {:ok,
         %__MODULE__{
           id: address,
           account_bond: account_bond,
           account_revenue: account_revenue,
           liquid_bond_shares: liquid_bond_shares,
           liquid_bond_size: liquid_bond_size,
           pending_revenue: pending_revenue
         }}
      else
        _ -> {:error, :parse_error}
      end
    end
  end

  defstruct [
    :id,
    :address,
    :bond_denom,
    :revenue_denom,
    :revenue_converter,
    :status
  ]

  @type revenue_converter_t :: {String.t(), binary(), integer()}

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          bond_denom: String.t(),
          revenue_denom: String.t(),
          revenue_converter: revenue_converter_t(),
          status: :not_loaded | Status.t()
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()}
  def from_config(address, %{
        "bond_denom" => bond_denom,
        "revenue_denom" => revenue_denom,
        "revenue_converter" => revenue_converter
      }) do
    {:ok,
     %__MODULE__{
       id: address,
       address: address,
       bond_denom: bond_denom,
       revenue_denom: revenue_denom,
       revenue_converter: revenue_converter,
       status: :not_loaded
     }}
  end
end
