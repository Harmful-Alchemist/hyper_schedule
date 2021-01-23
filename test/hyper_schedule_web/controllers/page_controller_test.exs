defmodule HyperScheduleWeb.PageControllerTest do
  use HyperScheduleWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Hyper Schedule!"
  end

  test "GET /about", %{conn: conn} do
    conn = get(conn, "/about")
    assert html_response(conn, 200) =~ "About Hyper Schedule"
  end
end
