defmodule HyperScheduleWeb.CalendarLive do
  use Phoenix.LiveView
  alias HyperSchedule.{Participants, Scheduling}

  @impl true
  def mount(_params, _session, socket) do
    current_date = Scheduling.current_date()

    assigns = [
      current_date: current_date,
      day_names: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      week_rows: week_rows(current_date),
      selected_dates: [],
      participants: [],
      toggle_weekend: true,
      changeset: Participants.participant(),
      start_date: "mm/dd/yyyy",
      end_date: "mm/dd/yyyy"
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    HyperScheduleWeb.PageView.render("calendar.html", assigns)
  end

  @impl true
  def handle_event(
        "select-date-range",
        %{"end-date" => end_date, "start-date" => start_date},
        socket
      ) do
    case {start_date, end_date} do
      {"", _} ->
        {:noreply, assign(socket, end_date: end_date)}

      {_, ""} ->
        {:noreply, assign(socket, start_date: start_date)}

      {_, _} ->
        assigns = [
          selected_dates:
            select_date_range(
              socket.assigns.selected_dates,
              socket.assigns.toggle_weekend,
              start_date,
              end_date
            ),
          start_date: start_date,
          end_date: end_date
        ]

        {:noreply, assign(socket, assigns)}
    end
  end

  @impl true
  def handle_event(
        "blocked-dates",
        %{"blocked-date" => blocked_date, "name" => name, "repeats" => repeats},
        socket
      ) do
    #    TODO removing displaying in calendar! Adding multiple dates! Don't lose input once done and tests and repeating dates!
    {:ok, blocked_dates} =
      case repeats do
        "never" -> {:ok, [blocked_date]}
        "weekly" -> Scheduling.weekly(blocked_date)
        "monthly" -> Scheduling.monthly(blocked_date)
      end

    participants =
      socket.assigns.participants
      |> Enum.map(fn participant ->
        case blocked_date != "" and participant.name == name do
          true ->
            participant
            |> Map.update!(:blocked, &Enum.concat(&1, blocked_dates))

          _ ->
            participant
        end
      end)

    assigns = [participants: participants]
    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("remove-participant", %{"name" => name}, socket) do
    participants =
      socket.assigns.participants
      |> Enum.filter(fn %{name: filter_name} -> filter_name != name end)

    assigns = [
      participants: participants
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("toggle-weekend", _, socket) do
    selected_dates =
      socket.assigns.selected_dates
      |> Enum.filter(&(!Scheduling.weekend(&1)))

    participants =
      socket.assigns.participants
      |> Enum.map(fn participant ->
        participant
        |> Map.update!(:scheduled, fn scheduled ->
          scheduled
          |> Enum.filter(&(!Scheduling.weekend(&1)))
        end)
      end)

    assigns = [
      toggle_weekend: !socket.assigns.toggle_weekend,
      selected_dates: selected_dates,
      participants: participants
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("pick-date", %{"date" => date}, socket) do
    selected_dates = socket.assigns.selected_dates

    assigns =
      case Enum.member?(selected_dates, date) do
        true -> [selected_dates: List.delete(selected_dates, date)]
        false -> [selected_dates: [date | selected_dates]]
      end

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("schedule", _, socket) do
    slots = socket.assigns.selected_dates

    timestamped_participants =
      socket.assigns.participants
      |> Enum.map(fn participant ->
        Map.update!(participant, :scheduled, fn scheduled ->
          Enum.filter(scheduled, fn date ->
            Enum.member?(socket.assigns.selected_dates, date)
          end)
        end)
      end)

    # TODO error handling
    {:ok, schedule} = Scheduling.schedule(timestamped_participants, slots)

    assigns = [participants: schedule]
    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("add_participant", %{"participant" => %{"name" => name} = params}, socket) do
    assigns =
      cond do
        name == "" -> []
        socket.assigns.participants |> Enum.any?(&(&1.name == name)) -> []
        true -> [participants: [Participants.struct(params) | socket.assigns.participants]]
      end

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("prev-month", _, socket) do
    {:ok, current_date} =
      Scheduling.shift(
        socket.assigns.current_date,
        -1,
        :month
      )

    assigns = [
      current_date: current_date,
      week_rows: week_rows(current_date)
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("next-month", _, socket) do
    {:ok, current_date} =
      Scheduling.shift(
        socket.assigns.current_date,
        1,
        :month
      )

    assigns = [
      current_date: current_date,
      week_rows: week_rows(current_date)
    ]

    {:noreply, assign(socket, assigns)}
  end

  defp week_rows(current_date) do
    {:ok, days} = Scheduling.week_rows(current_date)
    days |> Enum.chunk_every(7)
  end

  defp select_date_range(selected_dates, toggle_weekend, start_date, end_date) do
    #    TODO parse errors and start > end will be error now
    {:ok, new_dates} = Scheduling.day_range(start_date, end_date)

    new_dates =
      case toggle_weekend do
        true ->
          new_dates
          |> Enum.filter(&(!Scheduling.weekend(&1)))

        false ->
          new_dates
      end

    new_dates
    |> Enum.concat(selected_dates)
    |> Enum.dedup()
  end
end
