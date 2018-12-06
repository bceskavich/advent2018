defmodule Advent.Day4 do
  @instructions "files/day4.txt"
  @date_pattern ~r/\[(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2}) (?<hour>\d{2}):(?<minute>\d{2})\]/
  @log_pattern ~r/#(?<id>\d+)\sbegins/

  def run() do
    result = parse_and_sort_instructions()
    |> read_logs({nil, nil}, %{})

    IO.puts("Part One: #{find_sleepiest_guard_checksum(result)}")
    IO.puts("Part Two: #{find_sleepiest_guard_minute(result)}")
  end

  defp read_logs([], _, totals), do: totals
  defp read_logs([entry | rest], {current_id, last_sleep_start}, totals) do
    cond do
      Regex.match?(@log_pattern, entry) && current_id == nil ->
        %{"id" => next_id} = Regex.named_captures(@log_pattern, entry)
        read_logs(rest, {next_id, nil}, Map.put(totals, next_id, {0, %{}}))

      Regex.match?(@log_pattern, entry) ->
        %{"id" => next_id} = Regex.named_captures(@log_pattern, entry)
        case last_sleep_start do
          nil -> read_logs(rest, {next_id, nil}, Map.put_new(totals, next_id, {0, %{}}))
          _ ->
            totals = totals
            |> update_sleep_tracking(current_id, entry, last_sleep_start)
            |> Map.put_new(next_id, {0, %{}})

            read_logs(rest, {next_id, nil}, totals)
        end

      String.contains?(entry, "falls asleep") ->
        {_, {_, current_minute}} = to_erl(entry)
        read_logs(rest, {current_id, current_minute}, totals)

      String.contains?(entry, "wakes up") ->
        read_logs(rest, {current_id, nil}, update_sleep_tracking(totals, current_id, entry, last_sleep_start))
    end
  end

  defp update_sleep_tracking(totals, id, entry, last_sleep_start) do
    {sleep_count, tracked_minutes} = Map.get(totals, id)
    {_, {_, current_minute}} = to_erl(entry)

    Map.put(totals, id, {
      sleep_count + current_minute - last_sleep_start,
      update_tracked_minutes(tracked_minutes, current_minute, last_sleep_start)
    })
  end

  defp update_tracked_minutes(tracked_minutes, current_minute, last_sleep_start) do
    Range.new(current_minute - 1, last_sleep_start) |> Enum.reduce(tracked_minutes, fn (min, tracked) ->
      case Map.get(tracked, min) do
        nil -> Map.put(tracked, min, 1)
        seen -> Map.put(tracked, min, seen + 1)
      end
    end)
  end

  defp find_sleepiest_guard_checksum(totals) do
    {id, {_, tracked_minutes}} = Enum.max_by(totals, fn ({_, {count, _}}) -> count end)
    {minute, _ } = Enum.max_by(tracked_minutes, fn ({_, value}) -> value end)
    String.to_integer(id) * minute
  end

  defp find_sleepiest_guard_minute(totals) do
    {id, minute, _} = Enum.reduce(totals, {nil, nil, 0}, fn ({id, {_, tracked_minutes}}, {_, _, max_frequency} = acc) ->
      case Enum.empty?(tracked_minutes) do
        true -> acc
        false ->
          {minute, frequency} = Enum.max_by(tracked_minutes, fn ({_, value}) -> value end)
          case frequency > max_frequency do
            true -> {id, minute, frequency}
            false -> acc
          end
      end
    end)

    String.to_integer(id) * minute
  end

  ## Parsing & Sorting ##

  def parse_and_sort_instructions() do
    read_instructions()
    |> Enum.sort_by(&to_erl/1)
  end

  defp read_instructions() do
    File.stream!(@instructions)
    |> Enum.map(fn str ->
      str
      |> String.replace("\n", "")
      |> String.trim()
    end)
  end

  defp to_erl(str) do
    %{
      "year"    => year,
      "month"   => month,
      "day"     => day,
      "hour"    => hour,
      "minute"  => minute
    } = Regex.named_captures(@date_pattern, str)

    {
      {String.to_integer(year), String.to_integer(month), String.to_integer(day)},
      {String.to_integer(hour), String.to_integer(minute)}
    }
  end
end
