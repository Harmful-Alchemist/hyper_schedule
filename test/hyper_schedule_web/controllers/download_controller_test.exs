defmodule HyperScheduleWeb.DownloadControllerTest do
  use HyperScheduleWeb.LiveCase

  test "Can download the CSV", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    names = ["name1", "name2", "name3"]

    render_click(view, "toggle-weekend")
    first_day_of_month = Timex.now() |> Timex.beginning_of_month()

    for i <- 0..5 do
      formatted =
        first_day_of_month |> Timex.shift(days: i) |> Timex.format!("%Y-%m-%d", :strftime)

      render_click(view, "pick-date", date: formatted)
    end

    for name <- names do
      view
      |> form("form#participant-form", participant: %{name: name})
      |> render_submit()
    end

    {:ok, scheduled} = Floki.parse_document(render_click(view, "schedule"))

    {"form", _, form_data} = scheduled |> Floki.find("form#csv_form") |> hd()

    inputs =
      form_data
      |> Enum.filter(fn {name, _, _} -> name == "input" end)
      |> Enum.map(fn {"input", values, _} ->
        name =
          values
          |> Enum.filter(fn {key, _} -> key == "name" end)
          |> Enum.map(fn {"name", val} -> val end)

        value =
          values
          |> Enum.filter(fn {key, _} -> key == "value" end)
          |> Enum.map(fn {"value", val} -> val end)

        {
          hd(name),
          hd(value)
        }
      end)

    conn = post(conn, "/schedule.csv", inputs)

    assert conn.resp_body ==
             "Date,Scheduled
#{first_day_of_month |> Timex.shift(days: 0) |> Timex.format!("%Y-%m-%d", :strftime)},name1
#{first_day_of_month |> Timex.shift(days: 1) |> Timex.format!("%Y-%m-%d", :strftime)},name2
#{first_day_of_month |> Timex.shift(days: 2) |> Timex.format!("%Y-%m-%d", :strftime)},name3
#{first_day_of_month |> Timex.shift(days: 3) |> Timex.format!("%Y-%m-%d", :strftime)},name1
#{first_day_of_month |> Timex.shift(days: 4) |> Timex.format!("%Y-%m-%d", :strftime)},name2
#{first_day_of_month |> Timex.shift(days: 5) |> Timex.format!("%Y-%m-%d", :strftime)},name3"

    #    csv = view |> form("form#csv_form") |> render_submit()
    #
    #    IO.inspect(csv)
  end
end
