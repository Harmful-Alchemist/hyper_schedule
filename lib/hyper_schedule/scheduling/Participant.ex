defmodule HyperScheduling.Participant do
    @type t :: %Participant{
            name: string,
            sheduled: list(Date),
            blocked: list(Date)
          }

    defstruct name: "", scheduled: [], blocked: []
  end

