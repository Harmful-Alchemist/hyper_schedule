defmodule HyperScheduleWeb.DownloadController do
  use HyperScheduleWeb, :controller
  #  import HyperSchedule.Scheduling

  def csv(conn, participants) do
    header = "Date,Scheduled"
    # TODO create the csv make sure the assigns stay in the socket after download also test!
    lines =
      participants
      |> Map.to_list()
      |> Enum.filter(&(Kernel.elem(&1, 0) |> String.contains?(">>")))
      |> Enum.group_by(&(Kernel.elem(&1, 0) |> String.split(">>") |> List.last()))
      |> Enum.map(fn {_key, value_tuples} ->
        %{
          name:
            value_tuples
            |> Enum.filter(&(Kernel.elem(&1, 0) |> String.contains?("name")))
            |> Enum.map(fn {_name_key, name} -> name end)
            |> List.first(),
          scheduled_dates:
            value_tuples
            |> Enum.filter(&(Kernel.elem(&1, 0) |> String.contains?("scheduled")))
            |> Enum.flat_map(fn {_date_key, dates} -> dates |> String.split(",") end)
        }
      end)
      |> Enum.flat_map(fn participant ->
        participant.scheduled_dates |> Enum.map(fn date -> "#{date},#{participant.name}" end)
      end)
      |> Enum.sort()

    csv = Enum.join([header | lines], "\n")
    send_download(conn, {:binary, csv}, filename: "schedule.csv")
  end
end
