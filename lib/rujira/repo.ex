defmodule Rujira.Repo do
  use Appsignal.Ecto.Repo,
    otp_app: :rujira,
    adapter: Ecto.Adapters.Postgres
end
