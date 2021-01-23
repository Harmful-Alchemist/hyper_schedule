defmodule HyperSchedule.Scheduling do
  use Rustler, otp_app: :hyper_schedule, crate: "scheduling"

  #  @spec schedule(list(HyperScheduling.Participant), list(integer)) :: list(HyperScheduling.Participant)
  def schedule(_participants, _slots), do: :erlang.nif_error(:nif_not_loaded)
end
