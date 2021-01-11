defmodule HyperScheduleWeb.PageController do
  use HyperScheduleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
