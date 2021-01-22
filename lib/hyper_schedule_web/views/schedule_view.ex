defmodule HyperScheduleWeb.ScheduleView do
  use HyperScheduleWeb, :view

  def render("participants.json", %{participants: participants}) do
    render_many(participants, HyperScheduleWeb.ScheduleView, "participant.json")
  end

  def render("participant.json", %{schedule: participant}) do
    %{name: participant.name, scheduled: participant.scheduled, blocked: participant.blocked}
  end
end
