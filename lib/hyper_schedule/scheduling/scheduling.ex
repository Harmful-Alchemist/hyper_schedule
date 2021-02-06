defmodule HyperSchedule.Scheduling do
  use Rustler, otp_app: :hyper_schedule, crate: "scheduling"

  @spec schedule!(list(HyperScheduling.Participant), list(integer)) ::
          list(HyperScheduling.Participant)
  def schedule!(_participants, _slots), do: :erlang.nif_error(:nif_not_loaded)

  @spec shift(String.t(), integer, atom) :: {:ok | :error, String.t()}
  def shift(date, amount, unit \\ :day) do
    case unit do
      :day -> shift_day(date, amount)
      :month -> shift_month(date, amount)
      _ -> {:error, "incorrect type"}
    end
  end

  def shift_day(_date, _days), do: :erlang.nif_error(:nif_not_loaded)

  def shift_month(_date, _months), do: :erlang.nif_error(:nif_not_loaded)

  def same_date?(_date1, _date2), do: :erlang.nif_error(:nif_not_loaded)

  def weekly(_date), do: :erlang.nif_error(:nif_not_loaded)

  def monthly(_date), do: :erlang.nif_error(:nif_not_loaded)
end
