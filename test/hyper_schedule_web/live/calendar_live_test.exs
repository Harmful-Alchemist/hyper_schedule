defmodule HyperScheduleWeb.CalendarLiveTest do
  use HyperScheduleWeb.LiveCase

  @not_styled "text-xs p-2 text-gray-600 border border-gray-200 bg-white hover:bg-purple-300 cursor-pointer"

  @selected "text-xs p-2 text-gray-600 border border-gray-200 bg-blue-100 cursor-pointer"

  @today "text-xs p-2 text-gray-600 border border-gray-200 bg-green-200 hover:bg-green-300 cursor-pointer"

  @today_selected "text-xs p-2 text-gray-600 border border-gray-200 bg-green-400 hover:bg-green-500 cursor-pointer"

  @weekend "text-xs p-2 text-gray-600 border border-gray-200 bg-red-100 cursor-not-allowed"

  @not_in_month "text-xs p-2 text-gray-400 border border-gray-200 bg-gray-200 hover:bg-purple-100 cursor-pointer"

  @not_in_month_selected "text-xs p-2 text-gray-400 border border-gray-200 bg-gray-300 hover:bg-purple-100 cursor-pointer"

  test "connected mount", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    assert html =~ "prev-month"
    now = Timex.now()
    now_formatted = Timex.format!(now, "%Y-%m-%d", :strftime)
    assert html =~ now_formatted
  end

  test "can move months", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    assert html =~ "prev-month"
    now = Timex.now()

    assert render_click(view, "next-month") =~
             Timex.shift(now, months: 1) |> Timex.format!("%Y-%m-%d", :strftime)

    assert render_click(view, "next-month") =~
             Timex.shift(now, months: 2) |> Timex.format!("%Y-%m-%d", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: 1) |> Timex.format!("%Y-%m-%d", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: 0) |> Timex.format!("%Y-%m-%d", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: -1) |> Timex.format!("%Y-%m-%d", :strftime)

    assert render_click(view, "prev-month") =~
             Timex.shift(now, months: -2) |> Timex.format!("%Y-%m-%d", :strftime)
  end

  test "can select dates", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    html = render_click(view, "toggle-weekend")
    assert html =~ "prev-month"
    now = Timex.now()
    now_formatted = Timex.format!(now, "%Y-%m-%d", :strftime)

    in_month = now |> Timex.beginning_of_month()

    in_month =
      case Timex.compare(now, in_month, :day) do
        0 -> Timex.shift(now, days: 1)
        _ -> in_month
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

    {:ok, days_shown} = HyperSchedule.Scheduling.week_rows(now_formatted)

    days_shown_not_month =
      days_shown
      |> Enum.filter(fn e -> !HyperSchedule.Scheduling.same_month(e, now_formatted) end)

    for day_not_in_month <- days_shown_not_month do
      assert html =~ "phx-value-date=\"#{day_not_in_month}\" class=\"#{@not_in_month}\""
    end

    [not_in_month | _] = days_shown_not_month

    assert render_click(view, "pick-date", date: not_in_month) =~
             "phx-value-date=\"#{not_in_month}\" class=\"#{@not_in_month_selected}\""
  end

  test "can add participants", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    name1 = "name1"
    name2 = "name2"

    assert view
           |> form("form#participant-form", participant: %{name: name1})
           |> render_submit =~
             "<label for=\"name\">name</label><input type=\"text\" value=\"#{name1}\" name=\"name\"/>"

    assert view
           |> form("form#participant-form", participant: %{name: name2})
           |> render_submit =~
             "<label for=\"name\">name</label><input type=\"text\" value=\"#{name2}\" name=\"name\"/>"
  end

  test "can remove participants", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    name = "name1"

    assert view
           |> form("form#participant-form", participant: %{name: name})
           |> render_submit =~
             "<label for=\"name\">name</label><input type=\"text\" value=\"#{name}\" name=\"name\"/>"

    refute render_click(view, "remove-participant", %{"name" => name}) =~
             "<label for=\"name\">name</label><input type=\"text\" value=\"#{name}\" name=\"name\"/>"
  end

  test "can schedule", %{conn: conn} do
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
      |> render_submit
    end

    scheduled = render_click(view, "schedule")

    for i <- 0..5 do
      name = Enum.at(names, rem(i, length(names)))
      day = first_day_of_month |> Timex.shift(days: i) |> Timex.format!("%d", :strftime)
      assert scheduled =~ "#{day}\n  \n  <div class=\"text-bold bg-purple\">#{name}</div>"
    end

    #    Unclick and reschedule
    formatted = first_day_of_month |> Timex.format!("%Y-%m-%d", :strftime)

    render_click(view, "pick-date", date: formatted)
    scheduled = render_click(view, "schedule")
    day1 = first_day_of_month |> Timex.format!("%d", :strftime)
    assert scheduled =~ "#{day1}\n  \n        \n</td>"

    for i <- 1..5 do
      name = Enum.at(names, rem(i, length(names)))
      day = first_day_of_month |> Timex.shift(days: i) |> Timex.format!("%d", :strftime)
      assert scheduled =~ "#{day}\n  \n  <div class=\"text-bold bg-purple\">#{name}</div>"
    end

    #    Schedule extra
    formatted6 =
      first_day_of_month |> Timex.shift(days: 6) |> Timex.format!("%Y-%m-%d", :strftime)

    render_click(view, "pick-date", date: formatted6)
    scheduled = render_click(view, "schedule")

    assert scheduled =~ "#{day1}\n  \n        \n</td>"

    for i <- 1..6 do
      name = Enum.at(names, rem(i, length(names)))
      day = first_day_of_month |> Timex.shift(days: i) |> Timex.format!("%d", :strftime)
      assert scheduled =~ "#{day}\n  \n  <div class=\"text-bold bg-purple\">#{name}</div>"
    end
  end

  test "can't  schedule on blocked dates", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    name = "name1"

    render_click(view, "toggle-weekend")

    first_day_of_month =
      Timex.now() |> Timex.beginning_of_month() |> Timex.format!("%Y-%m-%d", :strftime)

    view
    |> form("form#participant-form", participant: %{name: name})
    |> render_submit

    blocked =
      view
      |> form("form#blocked-dates#{name}", %{
        "blocked-date" => first_day_of_month,
        "name" => name,
        "repeats" => "never"
      })
      |> render_submit

    assert blocked =~
             "01\n  \n        \n  <div class=\"text-bold bg-purple\"><s>#{name}</s></div>"

    render_click(view, "pick-date", date: first_day_of_month)
    scheduled = render_click(view, "schedule")
    # Still strike through after scheduling
    assert scheduled =~
             "01\n  \n        \n  <div class=\"text-bold bg-purple\"><s>#{name}</s></div>"
  end

  test "weekends work", %{conn: conn} do
    first_saturday = Timex.now() |> Timex.beginning_of_month() |> first_saturday()
    first_sunday = Timex.shift(first_saturday, days: 1)
    next_mon = Timex.shift(first_sunday, days: 1)

    avoid_today =
      Timex.compare(Timex.now(), first_saturday, :day) == 0 ||
        Timex.compare(Timex.now(), first_sunday, :day) == 0 ||
        Timex.compare(Timex.now(), next_mon, :day) == 0

    {first_saturday, first_sunday, next_mon} =
      case avoid_today do
        true ->
          {Timex.shift(first_saturday, days: 7), Timex.shift(first_saturday, days: 8),
           Timex.shift(first_saturday, days: 9)}

        false ->
          {first_saturday, first_sunday, next_mon}
      end

    {:ok, view, html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    sat_formatted = Timex.format!(first_saturday, "%Y-%m-%d", :strftime)
    assert html =~ "phx-value-date=\"#{sat_formatted}\" class=\"#{@weekend}\""

    sun_formatted = Timex.format!(first_sunday, "%Y-%m-%d", :strftime)
    assert html =~ "phx-value-date=\"#{sun_formatted}\" class=\"#{@weekend}\""

    mon_formatted = Timex.format!(next_mon, "%Y-%m-%d", :strftime)
    assert html =~ "phx-value-date=\"#{mon_formatted}\" class=\"#{@not_styled}\""

    toggled = render_click(view, "toggle-weekend")
    assert toggled =~ "phx-value-date=\"#{sat_formatted}\" class=\"#{@not_styled}\""
    assert toggled =~ "phx-value-date=\"#{sun_formatted}\" class=\"#{@not_styled}\""
    assert toggled =~ "phx-value-date=\"#{sun_formatted}\" class=\"#{@not_styled}\""

    render_click(view, "pick-date", date: sat_formatted)
    render_click(view, "pick-date", date: sun_formatted)
    render_click(view, "pick-date", date: mon_formatted)

    name = "name"

    view
    |> form("form#participant-form", participant: %{name: name})
    |> render_submit

    scheduled = render_click(view, "schedule")

    for day <- [first_saturday, first_sunday, next_mon] do
      form = Timex.format!(day, "%d", :strftime)
      assert scheduled =~ "#{form}\n  \n  <div class=\"text-bold bg-purple\">#{name}</div>"
    end

    toggled_back = render_click(view, "toggle-weekend")

    assert toggled_back =~
             "#{Timex.format!(first_saturday, "%d", :strftime)}\n  \n        \n</td>"

    assert toggled_back =~ "#{Timex.format!(first_sunday, "%d", :strftime)}\n  \n        \n</td>"

    assert toggled_back =~
             "#{Timex.format!(next_mon, "%d", :strftime)}\n  \n  <div class=\"text-bold bg-purple\">#{
               name
             }</div>"

    assert toggled_back =~ "phx-value-date=\"#{sat_formatted}\" class=\"#{@weekend}\""
    assert toggled_back =~ "phx-value-date=\"#{sun_formatted}\" class=\"#{@weekend}\""
    assert toggled_back =~ "phx-value-date=\"#{mon_formatted}\" class=\"#{@selected}\""
  end

  test "select range of dates", %{conn: conn} do
    today = Timex.now() |> Timex.format!("%Y-%m-%d", :strftime)

    first_saturday_not_formatted =
      Timex.now()
      |> Timex.beginning_of_month()
      |> first_saturday()

    first_saturday =
      first_saturday_not_formatted
      |> Timex.format!("%Y-%m-%d", :strftime)

    two_months_later =
      first_saturday_not_formatted
      |> Timex.shift(months: 2)
      |> Timex.format!("%Y-%m-%d", :strftime)

    {:ok, view, _html} = live_isolated(conn, HyperScheduleWeb.CalendarLive)
    render_click(view, "toggle-weekend")

    scheduled =
      view
      |> form("form#select-date-range", %{
        "end-date" => two_months_later,
        "start-date" => first_saturday
      })
      |> render_submit()

    for i <- 0..20 do
      formatted =
        first_saturday_not_formatted
        |> Timex.shift(days: i)
        |> Timex.format!("%Y-%m-%d", :strftime)

      if formatted == today do
        assert scheduled =~ "phx-value-date=\"#{formatted}\" class=\"#{@today_selected}\""
      else
        assert scheduled =~ "phx-value-date=\"#{formatted}\" class=\"#{@selected}\""
      end
    end

    next_month = render_click(view, "next-month")

    first_next_month =
      first_saturday_not_formatted |> Timex.beginning_of_month() |> Timex.shift(months: 1)

    for i <- 0..27 do
      formatted = first_next_month |> Timex.shift(days: i) |> Timex.format!("%Y-%m-%d", :strftime)
      assert next_month =~ "phx-value-date=\"#{formatted}\" class=\"#{@selected}\""
    end
  end

  defp first_saturday(date) do
    case Timex.weekday(date) do
      6 -> date
      _ -> first_saturday(Timex.shift(date, days: 1))
    end
  end
end
