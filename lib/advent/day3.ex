defmodule Advent.Day3 do
  @instructions "files/day3.txt"
  @pattern ~r/#(?<id>[^\s]+)\s@\s(?<x>\d+),(?<y>\d+):\s(?<w>\d+)x(?<h>\d+)/

  def run() do
    entries = parse_instructions()
    {shared_area, intact_ids} = part_one_and_two(entries)
    IO.puts("Part One: #{shared_area}")
    IO.puts("Part Two: #{intact_ids |> MapSet.to_list() |> Enum.at(0)}")
  end

  ## Part 1 ##

  defp part_one_and_two(entries) do
    calculate_shared_area(entries, {0, MapSet.new(), %{}})
  end

  defp calculate_shared_area([], {shared_area, intact_ids, _}), do: {shared_area, intact_ids}
  defp calculate_shared_area([entry | rest], memo) do
    memo = entry
    |> parse_entry()
    |> handle_entry(memo)

    calculate_shared_area(rest, memo)
  end

  defp parse_entry(entry) do
    %{"id" => id, "x" => x, "y" => y, "h" => h, "w" => w} = @pattern |> Regex.named_captures(entry)
    {id, String.to_integer(x), String.to_integer(y), String.to_integer(w), String.to_integer(h)}
  end

  defp handle_entry({id, x, y, width, height}, {shared_area, intact_ids, matrix}) do
    x_range = Range.new(x, x + width - 1)
    y_range = Range.new(y, y + height - 1)
    {shared_area, intact_ids, matrix, all_intact} = do_entry_loop(id, x_range, y_range, shared_area, intact_ids, matrix)

    case all_intact do
      true ->
        {shared_area, intact_ids |> MapSet.put(id), matrix}
      false -> {shared_area, intact_ids, matrix}
    end
  end

  defp do_entry_loop(id, x_range, y_range, shared_area, intact_ids, matrix) do
    x_range |> Enum.reduce({shared_area, intact_ids, matrix, true}, fn (x_coord, x_acc) ->
      y_range |> Enum.reduce(x_acc, fn (y_coord, y_acc) ->
        key_name = "#{x_coord}x#{y_coord}"
        y_acc
        |> update_matrix_for_entry(id, key_name)
        |> update_area_for_entry(key_name)
      end)
    end)
  end

  defp update_matrix_for_entry({shared_area, intact_ids, matrix, all_intact}, id, key_name) do
    case matrix |> Map.get(key_name) do
      nil ->
        {shared_area, intact_ids, matrix |> Map.put(key_name, {1, id}), all_intact}
      {count, last_id} ->
        {shared_area, intact_ids |> MapSet.delete(last_id), %{matrix | key_name => {count + 1, id}}, false}
    end
  end

  defp update_area_for_entry({shared_area, intact_ids, matrix, all_intact}, key_name) do
    {count, _} = Map.get(matrix, key_name)
    case count == 2 do
      true -> {shared_area + 1, intact_ids, matrix, all_intact}
      false -> {shared_area, intact_ids, matrix, all_intact}
    end
  end

  ## Shared ##

  defp parse_instructions() do
    File.stream!(@instructions)
    |> Enum.map(fn str ->
      str
      |> String.replace("\n", "")
      |> String.trim()
    end)
  end
end
