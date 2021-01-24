defmodule HyperSchedule.Participants do
  def participant(params \\ %{}) do
    HyperSchedule.Participant.changeset(%HyperSchedule.Participant{}, params)
  end

  #  TODO fine for now cause no validation in the changeset but won't be fine always
  def struct(params \\ %{}) do
    Ecto.Changeset.apply_changes(participant(params))
  end

  def naive_to_timestamps(participants) when is_list(participants) do
    participants |> Enum.map(&naive_to_timestamps/1)
  end

  def naive_to_timestamps(participant) do
    participant |> naive_to_timestamps(:blocked) |> naive_to_timestamps(:scheduled)
  end

  defp naive_to_timestamps(participant, key) do
    Map.update!(participant, key, fn value ->
      value
      |> Enum.map(&DateTime.from_naive!(&1, "Etc/UTC"))
      |> Enum.map(&DateTime.to_unix/1)
    end)
  end

  def timestamps_to_naive(participants) when is_list(participants) do
    participants |> Enum.map(&timestamps_to_naive/1)
  end

  def timestamps_to_naive(participant) do
    participant |> timestamps_to_naive(:blocked) |> timestamps_to_naive(:scheduled)
  end

  defp timestamps_to_naive(participant, key) do
    Map.update!(participant, key, fn value ->
      value
      |> Enum.map(&DateTime.from_unix!/1)
      |> Enum.map(&DateTime.to_naive/1)
    end)
  end
end
