defmodule HyperSchedule.Participant do
    @type t :: %HyperSchedule.Participant{
            name: String.t(),
            # Timestamp
            scheduled: list(integer),
            blocked: list(integer)
          }

    defstruct name: "", scheduled: [], blocked: []
  end

