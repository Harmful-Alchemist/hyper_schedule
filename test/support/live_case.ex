defmodule HyperScheduleWeb.LiveCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with live
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest

      # The default endpoint for testing
      @endpoint HyperScheduleWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HyperSchedule.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HyperSchedule.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
