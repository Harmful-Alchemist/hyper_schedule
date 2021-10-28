defmodule HyperScheduleWeb.ScheduleController do
  use HyperScheduleWeb, :controller
  use PhoenixSwagger
  import HyperSchedule.Scheduling

  swagger_path :schedule_api do
    post("/api/v1/schedule")
    description("Create a schedule")

    parameters do
      schedule_request(:body, Schema.ref(:ScheduleRequest), "Scheduling request", required: true)
    end

    response(200, "Ok", Schema.ref(:Participants))
    response(400, "Bad request: Schema error")
  end

  def swagger_definitions do
    %{
      Date:
        swagger_schema do
          title("Date")
          description("Date in yyyy-mm-dd format")
          type(:string)
          format(:date)
        end,
      Dates:
        swagger_schema do
          title("Dates")
          description("Dates")
          type(:array)
          items(Schema.ref(:Date))

          example([
            "2020-12-25",
            "2020-12-26",
            "2020-12-27",
            "2020-12-28"
          ])
        end,
      Participant:
        swagger_schema do
          title("Participant")
          description("A participant")

          properties do
            name(:string, "Participant name", required: true)
            blocked(Schema.ref(:Dates), "Blocked dates", required: true)
            blocked(Schema.ref(:Dates), "Pre-scheduled dates", required: true)
          end

          example(%{
            "name" => "Alice",
            "blocked" => [
              "2020-12-26"
            ],
            "scheduled" => []
          })
        end,
      Participants:
        swagger_schema do
          title("Participants")
          description("A collection of participants")
          type(:array)
          items(Schema.ref(:Participant))
        end,
      ScheduleRequest:
        swagger_schema do
          title("A scheduling request")
          description("A scheduling request")

          properties do
            participants(Schema.ref(:Participants))
            dates(Schema.ref(:Dates))
          end
        end
    }
  end

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
