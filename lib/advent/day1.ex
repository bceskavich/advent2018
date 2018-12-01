defmodule Advent.Day1 do
  @instructions "files/day1.txt"

  def run() do
    with {:ok, strs} <- File.read(@instructions) do
      IO.puts("Part One: #{part_one(strs)}")
      IO.puts("Part Two: #{part_two(strs)}")
    end
  end

  ## Part 1 ##

  defp part_one(strs) do
    strs
    |> String.split("\n")
    |> get_frequency()
  end

  # Reduce list of frequency instructions down to a final value, starting with 0
  defp get_frequency(strs, freq \\ 0)
  defp get_frequency([], freq), do: freq
  defp get_frequency([""], freq), do: freq
  defp get_frequency([str | rest], freq) do
    next_freq = freq |> update_frequency(str)
    get_frequency(rest, next_freq)
  end

  ## Part 2 ##

  defp part_two(strs) do
    strs
    |> String.split("\n")
    |> get_first_repeated_frequency()
  end

  # Repeatedly reduce instructions down to a frequency value until a repeated one
  # is found
  defp get_first_repeated_frequency(strs, freq \\ 0, found_freqs \\ %{0 => true}) do
    case find_first_repeated_frequency(strs, freq, found_freqs) do
      {:found, freq} -> freq
      {:unknown, freq, found_freqs} -> get_first_repeated_frequency(strs, freq, found_freqs)
    end
  end

  # Reduce instructions down to a frequency value, but also look for a repeated frequency value
  defp find_first_repeated_frequency([], freq, found_freqs),
    do: {:unknown, freq, found_freqs}
  defp find_first_repeated_frequency([""], freq, found_freqs),
    do: {:unknown, freq, found_freqs}
  defp find_first_repeated_frequency([str | rest], freq, found_freqs) do
    next_freq = freq |> update_frequency(str)
    case found_freqs |> Map.get(next_freq) do
      true -> {:found, next_freq}
      nil ->
        next_found_freqs = found_freqs |> Map.put(next_freq, true)
        find_first_repeated_frequency(rest, next_freq, next_found_freqs)
    end
  end

  ## Shared ##

  defp update_frequency(freq, str) do
    {operator, num} = parse_string(str)
    case operator do
      "+" -> freq + num
      "-" -> freq - num
    end
  end

  defp parse_string(str) do
    operator = str |> String.at(0)
    num = str
    |> String.slice(1..-1)
    |> String.to_integer()

    {operator, num}
  end
end
