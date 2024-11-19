defmodule Rujira.Repo do
  use Ecto.Repo,
    otp_app: :rujira,
    adapter: Ecto.Adapters.Postgres
end
