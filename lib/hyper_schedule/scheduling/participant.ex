defmodule HyperSchedule.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :name, :string, default: ""
    field :scheduled, {:array, :string}, default: []
    field :blocked, {:array, :string}, default: []
  end

  def changeset(participant, params \\ %{}) do
    participant
    #    TODO validate date format?
    |> cast(params, [:name, :scheduled, :blocked])
  end
end
