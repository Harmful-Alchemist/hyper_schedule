defmodule HyperScheduleWeb.CalendarLiveTest do
  use HyperScheduleWeb.LiveCase

  @not_styled "text-xs p-2 text-gray-600 border border-gray-200 bg-white hover:bg-purple-300 cursor-pointer"

  @selected "text-xs p-2 text-gray-600 border border-gray-200 bg-blue-100 cursor-pointer"

  @today "text-xs p-2 text-gray-600 border border-gray-200 bg-green-200 hover:bg-green-300 cursor-pointer"

  @today_selected "text-xs p-2 text-gray-600 border border-gray-200 bg-green-400 hover:bg-green-500 cursor-pointer"

  test "connected mount", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    assert html =~ "prev-month"
    now = Timex.now()
    now_formatted = Timex.format!(now, "%B %Y", :strftime)
    assert html =~ now_formatted
  end

  test "can move months", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    assert html =~ "prev-month"
    now = Timex.now()

    assert render_click(view, "next-month") =~
             Timex.shift(now, months: 1) |> Timex.format!("%B %Y", :strftime)

    assert render_click(view, "next-month") =~
             Timex.shift(now, months: 2) |> Timex.format!("%B %Y", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: 1) |> Timex.format!("%B %Y", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: 0) |> Timex.format!("%B %Y", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: -1) |> Timex.format!("%B %Y", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: -2) |> Timex.format!("%B %Y", :strftime)
  end

  test "can select dates", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    assert html =~ "prev-month"
    now = Timex.now()
    now_formatted = Timex.format!(now, "%Y-%m-%d", :strftime)

    in_month =
      case Timex.compare(Timex.shift(now, days: -1), now, :month) do
        0 -> Timex.shift(now, days: -1)
        _ -> Timex.shift(now, days: 1)
      end

    in_month_formatted = Timex.format!(in_month, "%Y-%m-%d", :strftime)
    assert html =~ "phx-value-date=\"#{in_month_formatted}\" class=\"#{@not_styled}\""

    assert html =~ "phx-value-date=\"#{now_formatted}\" class=\"#{@today}\""

    assert render_click(view, "pick-date", date: now_formatted) =~
             "phx-value-date=\"#{now_formatted}\" class=\"#{@today_selected}\""

    assert render_click(view, "pick-date", date: in_month_formatted) =~
             "phx-value-date=\"#{in_month_formatted}\" class=\"#{@selected}\""

    assert render_click(view, "pick-date", date: now_formatted) =~
             "phx-value-date=\"#{now_formatted}\" class=\"#{@today}\""

    assert render_click(view, "pick-date", date: in_month_formatted) =~
             "phx-value-date=\"#{in_month_formatted}\" class=\"#{@not_styled}\""

    # TODO the not in month selected and unselected
  end

  test "can add participants", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    name1 = "name1"
    name2 = "name2"

    assert view
           |> form("form#participant-form", participant: %{name: name1})
           |> render_submit =~ "<div>\n#{name1}"

    assert view
           |> form("form#participant-form", participant: %{name: name2})
           |> render_submit =~ "<div>\n#{name2}"
  end

  test "can schedule", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    names = ["name1", "name2", "name3"]

    first_day_of_month = Timex.now() |> Timex.beginning_of_month()

    for i <- 0..5 do
      formatted =
        first_day_of_month |> Timex.shift(days: i) |> Timex.format!("%Y-%m-%d", :strftime)

      render_click(view, "pick-date", date: formatted)
    end

    for name <- names do
      view
      |> form("form#participant-form", participant: %{name: name})
      |> render_submit
    end

    scheduled = render_click(view, "schedule")

    for i <- 0..5 do
      name = Enum.at(names, rem(i, length(names)))
      day = first_day_of_month |> Timex.shift(days: i) |> Timex.format!("%d", :strftime)
      assert scheduled =~ "#{day}\n  \n  <div class=\"text-bold bg-purple\">#{name}</div>"
    end

    #    TODO rescheduling with added and removed date!
  end
end
