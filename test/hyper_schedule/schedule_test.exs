defmodule HyperSchedule.ScheduleTest do
  use ExUnit.Case
  import HyperSchedule.Scheduling

  @day 86400

  setup do
    now = DateTime.utc_now()

    p1 =
      create_participant(
        "p1n",
        generate_date_time_series(
          DateTime.add(now, -4 * @day, :second),
          DateTime.add(now, -4 * @day, :second)
        ),
        []
      )

    p2 =
      create_participant(
        "p2n",
        generate_date_time_series(
          DateTime.add(now, -4 * @day, :second),
          DateTime.add(now, -4 * @day, :second)
        ),
        []
      )

    p3 =
      create_participant(
        "p3n",
        generate_date_time_series(
          DateTime.add(now, -3 * @day, :second),
          DateTime.add(now, -3 * @day, :second)
        ),
        []
      )

    p4 =
      create_participant(
        "p4n",
        [],
        []
      )

    %{p1: p1, p2: p2, p3: p3, p4: p4}
  end

  test "Can generate a schedule", %{p1: p1, p2: p2, p3: p3, p4: p4} do
    now = DateTime.utc_now()
    participants = [p1, p2, p3, p4]

    date_times =
      generate_date_time_series(DateTime.add(now, -11 * @day, :second), now)
      |> Enum.map(&DateTime.to_naive/1)
      |> Enum.map(&NaiveDateTime.to_date/1)

    dates = date_times |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))
    {:ok, schedule} = schedule!(participants, dates)

    # All names in the schedule
    assert Enum.map(schedule, & &1.name) == Enum.map(participants, & &1.name)
    # Blocked days should remain consistent
    assert Enum.map(schedule, & &1.blocked) == Enum.map(participants, & &1.blocked)
    # Scheduled days should be added
    assert Enum.map(schedule, & &1.scheduled) != Enum.map(participants, & &1.scheduled)
    # 12 scheduled days
    assert Enum.flat_map(schedule, & &1.scheduled) |> Enum.count() == 12

    # We lose the time info, for now and see all dates we gave to schedule are scheduled, if no blocked dates interfere
    assert Enum.flat_map(schedule, & &1.scheduled)
           |> Enum.map(&Timex.parse!(&1, "{YYYY}-{0M}-{0D}"))
           |> Enum.map(&NaiveDateTime.to_date/1)
           |> Enum.sort() == date_times |> Enum.sort()

    # 12 over four should be 3 each
    assert Enum.map(schedule, &Enum.count(&1.scheduled)) == [3, 3, 3, 3]
    # Should be no blocked days in any schedule
    for participant <- schedule do
      scheduled_dates =
        participant.scheduled
        |> Enum.map(&Timex.parse!(&1, "{YYYY}-{0M}-{0D}"))
        |> Enum.map(&NaiveDateTime.to_date/1)

      for blocked <- participant.blocked do
        refute scheduled_dates
               |> Enum.member?(blocked)
      end
    end

    # Should be no overlapping dates
    scheduled_dates =
      Enum.flat_map(schedule, & &1.scheduled)
      |> Enum.map(&Timex.parse!(&1, "{YYYY}-{0M}-{0D}"))
      |> Enum.map(&NaiveDateTime.to_date/1)

    assert length(scheduled_dates) == length(Enum.dedup(scheduled_dates))
  end

  test "Know it's a weekend" do
    a_week_starting_monday = [
      "2021-03-15",
      "2021-03-16",
      "2021-03-17",
      "2021-03-18",
      "2021-03-19",
      "2021-03-20",
      "2021-03-21"
    ]

    weekend? = a_week_starting_monday |> Enum.map(&weekend?/1)
    assert [false, false, false, false, false, true, true] = weekend?
  end

  defp create_participant(name, blocked, scheduled) do
    %HyperSchedule.Participant{
      name: name,
      scheduled: scheduled |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime)),
      blocked: blocked |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))
    }
  end

  defp generate_date_time_series(from, to, acc \\ []) do
    case DateTime.compare(from, to) do
      :gt -> [from | acc]
      :eq -> [from | acc]
      :lt -> generate_date_time_series(DateTime.add(from, @day, :second), to, [from | acc])
    end
  end
end
