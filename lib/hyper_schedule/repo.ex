defmodule HyperSchedule.Repo do
  use Ecto.Repo,
    otp_app: :hyper_schedule,
    adapter: Ecto.Adapters.Postgres
end
