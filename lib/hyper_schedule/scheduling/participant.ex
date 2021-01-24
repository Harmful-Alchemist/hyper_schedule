defmodule HyperSchedule.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :name, :string, default: ""
    field :scheduled, {:array, :integer}, default: []
    field :blocked, {:array, :integer}, default: []
  end

  def changeset(participant, params \\ %{}) do
    participant
    |> cast(params, [:name, :scheduled, :blocked])
  end
end
