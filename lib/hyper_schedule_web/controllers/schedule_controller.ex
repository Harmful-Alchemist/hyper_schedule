defmodule HyperScheduleWeb.ScheduleController do
  use HyperScheduleWeb, :controller
  import HyperSchedule.Scheduling

  def schedule_api(conn, %{"dates" => dates, "participants" => participants_web}) do
    # TODO some real errors mebbe :P instead of just thinking it will work. Also now only yyyy-mm-dd formatted strings :P
    {:ok, participants} =
      participants_web
      |> Enum.map(fn participant ->
        %HyperSchedule.Participant{
          name: participant["name"],
          blocked: participant["blocked"],
          scheduled: participant["scheduled"]
        }
      end)
      |> schedule(dates)

    render(conn, "participants.json", participants: participants)
  end
end
