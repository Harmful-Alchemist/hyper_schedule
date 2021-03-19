defmodule HyperSchedule.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = Application.get_env(:hyper_schedule, :children)
    #    children = [
    #      # Start the Ecto repository
    #      #      HyperSchedule.Repo,
    #      # Start the Telemetry supervisor
    #      HyperScheduleWeb.Telemetry,
    #      # Start the PubSub system
    #
    #      {Phoenix.PubSub, name: HyperSchedule.PubSub},
    #      # Start the Endpoint (http/https)
    #      HyperScheduleWeb.Endpoint
    #      # Start a worker by calling: HyperSchedule.Worker.start_link(arg)
    #      # {HyperSchedule.Worker, arg}
    #    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HyperSchedule.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HyperScheduleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
