defmodule HyperSchedule.CalendarDayComponent do
  use Phoenix.LiveComponent
  use Timex
  alias HyperSchedule.Scheduling

  @impl true
  def render(assigns) do
    assigns = Map.put(assigns, :day_class, day_class(assigns))

    scheduled_on_day =
      assigns.participants
      |> Enum.find(fn participant ->
        Enum.any?(participant.scheduled, fn x ->
          assigns.day == x
        end)
      end)

    blocked_on_day =
      assigns.participants
      |> Enum.filter(fn participant ->
        Enum.any?(participant.blocked, fn x -> assigns.day == x end)
      end)
      |> Enum.map(& &1.name)

    ~L"""
    <td phx-click="pick-date" phx-value-date="<%= @day %>" class="<%= @day_class %>">
      <%= String.slice(@day, 8..100) %>
      <%= if !is_nil(scheduled_on_day) do %>
      <div class="text-bold bg-purple"><%= scheduled_on_day.name %></div>
      <% end %>
            <%= for blocked <- blocked_on_day do %>
      <div class="text-bold bg-purple"><s><%= blocked %></s></div>
      <% end %>
    </td>
    """
  end

  defp day_class(assigns) do
    cond do
      #      today?(assigns) && weekend?(assigns) ->
      #        "text-xs p-2 text-gray-600 border border-gray-200 bg-green-100 cursor-not-allowed"

      assigns.toggle_weekend && Scheduling.weekend?(assigns.day) ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-red-100 cursor-not-allowed"

      Scheduling.today?(assigns.day) && selected_date?(assigns) ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-green-400 hover:bg-green-500 cursor-pointer"

      Scheduling.today?(assigns.day) ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-green-200 hover:bg-green-300 cursor-pointer"

      selected_date?(assigns) ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-blue-100 cursor-pointer"

      !Scheduling.same_month?(assigns.day) && selected_date?(assigns) ->
        "text-xs p-2 text-gray-400 border border-gray-200 bg-gray-200 bg-gray-100 hover:bg-purple-100 cursor-pointer"

      !Scheduling.same_month?(assigns.day) ->
        "text-xs p-2 text-gray-400 border border-gray-200 bg-gray-200 bg-gray-100 hover:bg-purple-100 cursor-pointer"

      true ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-white hover:bg-purple-300 cursor-pointer"
    end
  end

  defp selected_date?(assigns) do
    Enum.any?(assigns.selected_dates, &(assigns.day == &1))
  end

end
