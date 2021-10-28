defmodule HyperScheduleWeb.Router do
  use HyperScheduleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HyperScheduleWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/about", PageController, :about
    post "/schedule.csv", DownloadController, :csv
  end

  # Other scopes may use custom stacks.
  scope "/api/v1", HyperScheduleWeb do
    pipe_through :api

    post "/schedule", ScheduleController, :schedule_api
  end

  def swagger_info do
    %{
      schemes: ["http", "https"],
      info: %{
        version: "1",
        title: "Hyper Schedule",
        description: "Generate a schedule from participants and dates"
      },
      consumes: "application/json",
      produces: "application/json",
      tags: [
        %{name: "Schedule", description: "Scheduling of dates"}
      ]
    }
  end

  scope "/api/v1/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :hyper_schedule,
      swagger_file: "swagger.json"
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: HyperScheduleWeb.Telemetry
    end
  end
end
