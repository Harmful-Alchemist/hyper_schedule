defmodule HyperSchedule.Participant do
    @type t :: %HyperSchedule.Participant{
            name: String.t(),
            scheduled: list(Date),
            blocked: list(Date)
          }

    defstruct name: "", scheduled: [], blocked: []
  end

