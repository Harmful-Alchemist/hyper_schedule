defmodule HyperSchedule.Scheduling do
  use Rustler, otp_app: :hyper_schedule, crate: "scheduling"

  @spec schedule(list(HyperScheduling.Participant), list(String.t())) ::
          {:ok, list(HyperScheduling.Participant)} | {:error, String.t()}
  def schedule(_participants, _slots), do: :erlang.nif_error(:nif_not_loaded)

  @spec shift(String.t(), integer, :day | :month) :: {:ok | :error, String.t()}
  def shift(date, amount, unit \\ :day) do
    case unit do
      :day -> shift_day(date, amount)
      :month -> shift_month(date, amount)
      _ -> {:error, "incorrect type"}
    end
  end

  def shift_day(_date, _days), do: :erlang.nif_error(:nif_not_loaded)

  def shift_month(_date, _months), do: :erlang.nif_error(:nif_not_loaded)

  def same_date(_date1, _date2), do: :erlang.nif_error(:nif_not_loaded)

  def weekly(_date), do: :erlang.nif_error(:nif_not_loaded)

  def monthly(_date), do: :erlang.nif_error(:nif_not_loaded)

  def weekend(_date), do: :erlang.nif_error(:nif_not_loaded)

  def same_month(_date, _date2), do: :erlang.nif_error(:nif_not_loaded)

  def today(_date), do: :erlang.nif_error(:nif_not_loaded)

  def week_rows(_date), do: :erlang.nif_error(:nif_not_loaded)

  def current_date(), do: :erlang.nif_error(:nif_not_loaded)

  def day_range(_start_date, _end_date), do: :erlang.nif_error(:nif_not_loaded)
end
