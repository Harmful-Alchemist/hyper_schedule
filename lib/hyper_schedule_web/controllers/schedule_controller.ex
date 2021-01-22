defmodule HyperScheduleWeb.ScheduleController do
  use HyperScheduleWeb, :controller
  import HyperSchedule.Scheduling

  def schedule_api(conn, %{"dates" => dates, "participants" => participants_web}) do
    timestamps = to_timestamps(dates)
    #    TODO some real errors mebbe :P instead of just thinking it will work.
    {:ok, participants} = participants_web |> add_timestamps() |> schedule(timestamps)
    participants = add_dates(participants)
    render(conn, "participants.json", participants: participants)
  end

  defp add_dates(participants) do
    #    Don't need errors cause we trust {:ok, participants from schedule func}
    participants
    |> Enum.map(fn participant ->
      participant
      |> Map.put(:blocked, participant.blocked |> Enum.map(&timestamps_to_dates/1))
      |> Map.put(:scheduled, participant.scheduled |> Enum.map(&timestamps_to_dates/1))
    end)
  end

  defp timestamps_to_dates(stamps) when is_list(stamps) do
    stamps |> Enum.map(&DateTime.from_unix!/1)
  end

  defp timestamps_to_dates(stamp) do
    DateTime.from_unix!(stamp)
  end

  defp add_timestamps(participants) do
    #    TODO proper errors :P
    participants
    |> Enum.map(fn participant ->
      %HyperSchedule.Participant{
        name: participant["name"],
        blocked: Enum.map(participant["blocked"], &to_timestamps/1),
        scheduled: Enum.map(participant["scheduled"], &to_timestamps/1)
      }
    end)
  end

  defp to_timestamps(dates) when is_list(dates) do
    dates
    |> Enum.map(&DateTime.from_iso8601/1)
    |> Enum.map(fn {:ok, ok, _} -> DateTime.to_unix(ok) end)
  end

  defp to_timestamps(date) do
    with {:ok, datetime, _} <- DateTime.from_iso8601(date) do
      DateTime.to_unix(datetime)
    end
  end
end
