defmodule Rujira.Ventures.Pilot do
  defmodule Bow do
    defstruct []

    def from_config(nil), do: {:ok, nil}

    def from_confiig(_) do
      {:ok, %__MODULE__{}}
    end
  end

  defmodule Fin do
    defstruct []

    def from_config(nil), do: {:ok, nil}

    def from_confiig(_) do
      {:ok, %__MODULE__{}}
    end
  end

  defmodule Sale do
    defstruct [
      :beneficiary,
      :bid_denom,
      :bid_pools_snapshot,
      :bid_threshold,
      :closes,
      :contract_address,
      :deposit,
      :description,
      :fee_amount,
      :max_premium,
      :opens,
      :pilot,
      :price,
      :raise_amount,
      :title,
      :url,
      :waiting_period
    ]

    @type t :: %__MODULE__{
            beneficiary: String.t(),
            bid_denom: String.t(),
            bid_pools_snapshot: list(String.t()),
            bid_threshold: non_neg_integer(),
            closes: DateTime.t(),
            contract_address: String.t(),
            deposit: non_neg_integer(),
            description: String.t(),
            fee_amount: non_neg_integer(),
            max_premium: non_neg_integer(),
            opens: DateTime.t(),
            price: Decimal.t(),
            raise_amount: non_neg_integer(),
            title: String.t(),
            url: String.t(),
            waiting_period: non_neg_integer()
          }

    def from_query(%{
          "bid_pools_snapshot" => streams,
          "contract_address" => contract_address,
          "deposit" => deposit,
          "fee_amount" => fee_amount,
          "pilot" => %{
            "beneficiary" => beneficiary,
            "bid_denom" => bid_denom,
            "bid_threshold" => bid_threshold,
            "closes" => closes,
            "description" => description,
            "max_premium" => max_premium,
            "opens" => opens,
            "price" => price,
            "title" => title,
            "url" => url,
            "waiting_period" => waiting_period
          },
          "raise_amount" => raise_amount
        }) do
      with {bid_threshold, ""} <- Integer.parse(bid_threshold),
           {fee_amount, ""} <-
             if(is_nil(fee_amount), do: {nil, ""}, else: Integer.parse(fee_amount)),
           {deposit, ""} <- if(is_nil(deposit), do: {nil, ""}, else: Integer.parse(deposit)),
           {price, ""} <- Decimal.parse(price),
           {raise_amount, ""} <-
             if(is_nil(raise_amount), do: {nil, ""}, else: Integer.parse(raise_amount)),
           {opens, ""} <- Integer.parse(opens),
           {:ok, opens} <- DateTime.from_unix(opens, :nanosecond),
           {closes, ""} <- Integer.parse(closes),
           {:ok, closes} <- DateTime.from_unix(closes, :nanosecond) do
        {:ok,
         %__MODULE__{
           beneficiary: beneficiary,
           bid_denom: bid_denom,
           bid_pools_snapshot: streams,
           bid_threshold: bid_threshold,
           closes: closes,
           contract_address: contract_address,
           deposit: deposit,
           description: description,
           fee_amount: fee_amount,
           max_premium: max_premium,
           opens: opens,
           price: price,
           raise_amount: raise_amount,
           title: title,
           url: url,
           waiting_period: waiting_period
         }}
      end
    end
  end

  defmodule Token do
    defstruct [
      :type,
      :admin,
      :description,
      :display,
      :name,
      :png_url,
      :svg_url,
      :symbol,
      :uri,
      :uri_hash
    ]

    @type t :: %__MODULE__{
            type: :create,
            admin: String.t() | nil,
            description: String.t(),
            display: String.t(),
            name: String.t(),
            png_url: String.t(),
            svg_url: String.t(),
            symbol: String.t(),
            uri: String.t() | nil,
            uri_hash: String.t() | nil
          }

    def from_query(%{
          "create" => %{
            "denom_admin" => denom_admin,
            "description" => description,
            "display" => display,
            "name" => name,
            "png_url" => png_url,
            "svg_url" => svg_url,
            "symbol" => symbol,
            "uri" => uri,
            "uri_hash" => uri_hash
          }
        }) do
      {:ok,
       %__MODULE__{
         type: :create,
         admin: denom_admin,
         description: description,
         display: display,
         name: name,
         png_url: png_url,
         svg_url: svg_url,
         symbol: symbol,
         uri: uri,
         uri_hash: uri_hash
       }}
    end
  end

  defmodule Tokenomics do
    defmodule Category do
      defmodule Recipient do
        defstruct [:type, :address, :amount]

        @type t :: %__MODULE__{
                type: :send | :set,
                address: String.t() | nil,
                amount: non_neg_integer()
              }

        def from_query(%{
              "send" => %{
                "address" => address,
                "amount" => amount
              }
            }) do
          with {amount, ""} <- Integer.parse(amount) do
            {:ok, %__MODULE__{type: :send, address: address, amount: amount}}
          end
        end

        def from_query(%{
              "set" => %{
                "amount" => amount
              }
            }) do
          with {amount, ""} <- Integer.parse(amount) do
            {:ok, %__MODULE__{type: :set, amount: amount}}
          end
        end
      end

      defstruct [:type, :label, :recipients]

      @type t :: %__MODULE__{
              type: :standard,
              label: String.t(),
              recipients: list()
            }

      def from_query(%{
            "category_type" => type,
            "label" => label,
            "recipients" => recipients
          }) do
        with {:ok, recipients} <- Rujira.Enum.reduce_while_ok(recipients, &Recipient.from_query/1) do
          {:ok,
           %__MODULE__{
             type: String.to_existing_atom(type),
             label: label,
             recipients: recipients
           }}
        end
      end
    end

    defstruct [:categories]

    @type t :: %__MODULE__{
            categories: list(Category.t())
          }

    def from_query(%{
          "categories" => categories
        }) do
      with {:ok, categories} <-
             Rujira.Enum.reduce_while_ok(categories, [], &Category.from_query/1) do
        {:ok, %__MODULE__{categories: categories}}
      end
    end
  end

  defstruct [
    :owner,
    :status,
    :fin,
    :bow,
    :sale,
    :token,
    :tokenomics,
    :streams,
    :terms_conditions_accepted
  ]

  @type t :: %__MODULE__{
          owner: String.t(),
          status:
            :configured
            | :scheduled
            | :in_progress
            | :executed
            | :retracted
            | :completed,
          fin: String.t(),
          bow: String.t(),
          sale: Sale.t(),
          token: Token.t(),
          tokenomics: Tokenomics.t(),
          streams: list(String.t()),
          terms_conditions_accepted: boolean()
        }

  def from_query(owner, status, %{
        "bow" => bow,
        "fin" => fin,
        "pilot" => pilot,
        "streams" => streams,
        "terms_conditions_accepted" => terms_conditions_accepted,
        "token" => token,
        "tokenomics" => tokenomics
      }) do
    with {:ok, bow} <- Bow.from_config(bow),
         {:ok, fin} <- Fin.from_config(fin),
         {:ok, sale} <- Sale.from_query(pilot),
         {:ok, token} <- Token.from_query(token),
         {:ok, tokenomics} <- Tokenomics.from_query(tokenomics) do
      {:ok,
       %__MODULE__{
         owner: owner,
         status: status,
         fin: fin,
         bow: bow,
         streams: streams,
         sale: sale,
         token: token,
         tokenomics: tokenomics,
         terms_conditions_accepted: terms_conditions_accepted
       }}
    else
      _ -> {:error, :invalid_data}
    end
  end
end
