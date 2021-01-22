defmodule HyperSchedule.Scheduling do
  use Rustler, otp_app: :hyper_schedule, crate: "scheduling"

  # When your NIF is loaded, it will override this function.
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  #  @spec schedule(list(HyperScheduling.Participant), list(integer)) :: list(HyperScheduling.Participant)
  def schedule(_participants, _slots), do: :erlang.nif_error(:nif_not_loaded)
end
