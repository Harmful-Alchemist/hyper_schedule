defmodule HyperScheduleWeb.CalendarLive do
  use Phoenix.LiveView
  use Timex
  alias HyperSchedule.{Participants, Scheduling}

  @week_start_at :mon

  @impl true
  def mount(_params, _session, socket) do
    current_date = Timex.now()

    assigns = [
      conn: socket,
      current_date: current_date,
      day_names: day_names(@week_start_at),
      week_rows: week_rows(current_date),
      selected_dates: [],
      participants: [],
      changeset: Participants.participant()
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    HyperScheduleWeb.PageView.render("calendar.html", assigns)
  end

  @impl true
  def handle_event("pick-date", %{"date" => date}, socket) do
    selected_dates = socket.assigns.selected_dates
    picked_date = Timex.parse!(date, "{YYYY}-{0M}-{D}") |> NaiveDateTime.add(0, :millisecond)

    assigns =
      case Enum.member?(selected_dates, picked_date) do
        true -> [selected_dates: List.delete(selected_dates, picked_date)]
        false -> [selected_dates: [picked_date | selected_dates]]
      end

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("schedule", _, socket) do
    slots =
      socket.assigns.selected_dates
      |> Enum.map(&DateTime.from_naive!(&1, "Etc/UTC"))
      |> Enum.map(&DateTime.to_unix/1)

    timestamped_participants =
      socket.assigns.participants
      |> Enum.map(fn participant ->
        Map.update!(participant, :scheduled, fn scheduled ->
          Enum.filter(scheduled, fn date -> Enum.member?(socket.assigns.selected_dates, date) end)
        end)
      end)
      |> Participants.naive_to_timestamps()

    # TODO error handling
    {:ok, schedule} = Scheduling.schedule(timestamped_participants, slots)

    schedule = Participants.timestamps_to_naive(schedule)

    assigns = [participants: schedule]
    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("add_participant", %{"participant" => params}, socket) do
    assigns = [participants: [Participants.struct(params) | socket.assigns.participants]]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("prev-month", _, socket) do
    current_date = Timex.shift(socket.assigns.current_date, months: -1)

    assigns = [
      current_date: current_date,
      week_rows: week_rows(current_date)
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("next-month", _, socket) do
    current_date = Timex.shift(socket.assigns.current_date, months: 1)

    assigns = [
      current_date: current_date,
      week_rows: week_rows(current_date)
    ]

    {:noreply, assign(socket, assigns)}
  end

  defp day_names(:sun), do: [7, 1, 2, 3, 4, 5, 6] |> Enum.map(&Timex.day_shortname/1)
  defp day_names(_), do: [1, 2, 3, 4, 5, 6, 7] |> Enum.map(&Timex.day_shortname/1)

  defp week_rows(current_date) do
    first =
      current_date
      |> Timex.beginning_of_month()
      |> Timex.beginning_of_week(@week_start_at)

    last =
      current_date
      |> Timex.end_of_month()
      |> Timex.end_of_week(@week_start_at)

    Interval.new(from: first, until: last)
    |> Enum.map(& &1)
    |> Enum.chunk_every(7)
  end
end
