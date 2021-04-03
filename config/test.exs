use Mix.Config

config :hyper_schedule, :children, [
  # Start the Ecto repository
  HyperSchedule.Repo,
  # Start the Telemetry supervisor
  HyperScheduleWeb.Telemetry,
  # Start the PubSub system

  {Phoenix.PubSub, name: HyperSchedule.PubSub},
  # Start the Endpoint (http/https)
  HyperScheduleWeb.Endpoint
  # Start a worker by calling: HyperSchedule.Worker.start_link(arg)
  # {HyperSchedule.Worker, arg}
]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :hyper_schedule, HyperSchedule.Repo,
  username: "postgres",
  password: "postgres",
  database: "hyper_schedule_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  #  Thanks WSL2, back to v1
  #    System.get_env("DATABASE_HOST_TEST") ||
  #      System.cmd("awk", ["'/nameserver/ { print $2 }'", "/etc/resolv.conf"]),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hyper_schedule, HyperScheduleWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
