defmodule HyperScheduleWeb.ScheduleTest do
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
    date_times = generate_date_time_series(DateTime.add(now, -11 * @day, :second), now)
    dates = date_times |> Enum.map(&DateTime.to_unix/1)
    {:ok, schedule} = schedule(participants, dates)

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
           |> Enum.map(&DateTime.from_unix!/1)
           |> Enum.map(&DateTime.to_date/1)
           |> Enum.sort() == date_times |> Enum.map(&DateTime.to_date/1) |> Enum.sort()

    # 12 over four should be 3 each
    assert Enum.map(schedule, &Enum.count(&1.scheduled)) == [3, 3, 3, 3]
    # Should be no blocked days in any schedule
    for participant <- schedule do
      scheduled_dates =
        participant.scheduled
        |> Enum.map(&DateTime.from_unix!/1)
        |> Enum.map(&DateTime.to_date/1)

      for blocked <- participant.blocked do
        blocked_date = DateTime.from_unix!(blocked) |> DateTime.to_date()

        refute scheduled_dates
               |> Enum.member?(blocked_date)
      end
    end

    # Should be no overlapping dates
    scheduled_dates =
      Enum.flat_map(schedule, & &1.scheduled)
      |> Enum.map(&DateTime.from_unix!/1)
      |> Enum.map(&DateTime.to_date/1)

    assert length(scheduled_dates) == length(Enum.dedup(scheduled_dates))
  end

  defp create_participant(name, blocked, scheduled) do
    %HyperSchedule.Participant{
      name: name,
      scheduled: scheduled |> Enum.map(&DateTime.to_unix/1),
      blocked: blocked |> Enum.map(&DateTime.to_unix/1)
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
