defmodule HyperSchedule.CalendarDayComponent do
  use Phoenix.LiveComponent
  use Timex

  @impl true
  def render(assigns) do
    assigns = Map.put(assigns, :day_class, day_class(assigns))

    ~L"""
    <td phx-click="pick-date" phx-value-date="<%= Timex.format!(@day, "%Y-%m-%d", :strftime) %>" class="<%= @day_class %>">
      <%= Timex.format!(@day, "%d", :strftime) %>
    </td>
    """
  end

  defp day_class(assigns) do
    cond do
      today?(assigns) && selected_date?(assigns) ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-green-400 hover:bg-green-500 cursor-pointer"

      today?(assigns) ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-green-200 hover:bg-green-300 cursor-pointer"

      selected_date?(assigns) ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-blue-100 cursor-pointer"

      other_month?(assigns) && selected_date?(assigns) ->
        "text-xs p-2 text-gray-400 border border-gray-200 bg-gray-200 bg-gray-100 hover:bg-purple-100 cursor-pointer"

      other_month?(assigns) ->
        "text-xs p-2 text-gray-400 border border-gray-200 bg-gray-200 bg-gray-100 hover:bg-purple-100 cursor-pointer"

      true ->
        "text-xs p-2 text-gray-600 border border-gray-200 bg-white hover:bg-purple-300 cursor-pointer"
    end
  end

  defp selected_date?(assigns) do
    Enum.any?(assigns.selected_dates, &(Timex.compare(&1, assigns.day, :day) == 0))
  end

  defp today?(assigns) do
    Map.take(assigns.day, [:year, :month, :day]) == Map.take(Timex.now(), [:year, :month, :day])
  end

  defp other_month?(assigns) do
    Map.take(assigns.day, [:year, :month]) != Map.take(assigns.current_date, [:year, :month])
  end
end
