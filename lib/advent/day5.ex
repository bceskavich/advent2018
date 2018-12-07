defmodule Advent.Day5 do
  @polymer "files/day5.txt"
  @alphabet ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  @test_string "dabAcCaCBAcCcaDA"

  def run() do
    # IO.puts("Part One: #{scan_polymer()}")

    {letter, size} = part_two()
    IO.puts("Part Two: #{letter}:#{size}")
  end

  ## Part 1 ##

  defp scan_polymer() do
    read_polymer()
    |> scan_polymer({:static, ""})
    |> String.length()
  end

  defp scan_polymer("", {:static, scanned}), do: scanned
  defp scan_polymer(<<char>>, {status, scanned}) do
    scan_polymer("", {status, scanned <> <<char>>})
  end
  defp scan_polymer(rest, {:mutated, scanned}) do
    IO.puts("Found reaction, scanning before:#{String.length(scanned)} after:#{String.length(rest)}")

    scan_polymer(scanned, {:static, ""}) <> scan_polymer(rest, {:static, ""})
    |> scan_polymer({:static, ""})
  end
  defp scan_polymer(<<first_unit, second_unit, rest :: binary>>, {_, scanned}) do
    case units_match?(<<first_unit>>, <<second_unit>>) do
      true -> scan_polymer(rest, {:mutated, scanned})
      false -> scan_polymer(<<second_unit>> <> rest, {:static, scanned <> <<first_unit>>})
    end
  end

  defp units_match?(first, second) do
    first != second && (String.upcase(first) == second || first == String.upcase(second))
  end

  ## Part 2 ##
  # Ugh there's definitely a way to make this more efficient and stop running the
  # search based on which char is most stripped. Whatever, will refactor later (maybe...)

  defp part_two() do
    read_polymer() |> remove_and_scan_for_types()
  end

  defp remove_and_scan_for_types(polymer) do
    @alphabet
    |> Task.async_stream(__MODULE__, :do_remove_and_scan_for_type, [polymer], max_concurrency: 26, timeout: 20_400_000)
    |> Enum.reduce({"", nil}, fn ({:ok, {letter, size}}, {_, current_size} = current) ->
      IO.puts("Task finished with #{letter}:#{size}")
      cond do
        current_size == nil -> {letter, size}
        current_size > size -> {letter, size}
        true -> current
      end
    end)
  end

  def do_remove_and_scan_for_type(letter, polymer) do
    IO.puts("Starting task for #{letter}")
    {letter, remove_and_scan_for_type(polymer, letter)}
  end

  defp remove_and_scan_for_type(polymer, type) do
    polymer
    |> remove_units_of_type("", type)
    |> scan_polymer({:static, ""})
    |> String.length()
  end

  defp remove_units_of_type("", result, _), do: result
  defp remove_units_of_type(<<unit, rest :: binary>>, result, type) do
    case String.downcase(<<unit>>) == type do
      true -> remove_units_of_type(rest, result, type)
      false -> remove_units_of_type(rest, result <> <<unit>>, type)
    end
  end

  ## Shared ##

  def read_polymer() do
    File.stream!(@polymer)
    |> Enum.map(fn str ->
      str
      |> String.replace("\n", "")
      |> String.trim()
    end)
    |> Enum.join("")
  end
end
