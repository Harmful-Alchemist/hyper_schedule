defmodule HyperSchedule.Participants do
  def participant(params \\ %{}) do
    HyperSchedule.Participant.changeset(%HyperSchedule.Participant{}, params)
  end

  #  TODO fine for now cause no validation in the changeset but won't be fine always
  def struct(params \\ %{}) do
    Ecto.Changeset.apply_changes(participant(params))
  end
end
