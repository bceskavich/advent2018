defmodule Advent.Day2 do
  @instructions "files/day2.txt"

  def run() do
    ids = parse_instructions()
    IO.puts("Part One: #{get_checksum(ids)}")
    IO.puts("Part Two: #{get_common_id_chars(ids)}")
    IO.puts("Part Two (improved): #{find_close_id_chars(ids)}")
  end

  ## Part 1 ##

  defp get_checksum(ids) do
    ids
    |> Enum.reduce(%{2 => 0, 3 => 0}, &parse_id/2)
    |> calculate_checksum()
  end

  defp calculate_checksum(checksum_counts) do
    Map.get(checksum_counts, 2) * Map.get(checksum_counts, 3)
  end

  defp parse_id(id, checksum_counts) do
    id
    |> count_occurences()
    |> update_checksum_counts(checksum_counts)
  end

  defp count_occurences(str) do
    str
    |> String.graphemes()
    |> Enum.reduce(%{}, fn (char, acc) ->
      case Map.get(acc, char) do
        nil -> Map.put(acc, char, 1)
        count -> %{acc | char => count + 1}
      end
    end)
  end

  defp update_checksum_counts(char_counts, %{2 => two_count, 3 => three_count}) do
    %{
      2 => next_checksum_count(char_counts, 2, two_count),
      3 => next_checksum_count(char_counts, 3, three_count)
    }
  end

  defp next_checksum_count(char_counts, checksum_num, current_count) do
    case has_char_count?(char_counts, checksum_num) do
      true -> current_count + 1
      false -> current_count
    end
  end

  defp has_char_count?(char_counts, num) do
    char_counts
    |> Map.values()
    |> Enum.member?(num)
  end

  ## Part 2 ##

  defp get_common_id_chars(ids) do
    ids
    |> find_similar_id_chars()
  end

  defp find_similar_id_chars([target | rest]) do
    case find_similar_id_chars(target, rest) do
      "" -> find_similar_id_chars(rest)
      common_chars -> common_chars
    end
  end

  defp find_similar_id_chars(_, []), do: ""
  defp find_similar_id_chars(id, [next_id | rest]) do
    case ids_are_similar?(id, next_id) do
      {true, common_chars} -> common_chars
      {false, _} -> find_similar_id_chars(id, rest)
    end
  end

  defp ids_are_similar?(first, second) do
    {_, result, common_chars} = first
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce({0, true, ""}, &compare_string_chars(&1, &2, second))

    {result, common_chars}
  end

  defp compare_string_chars({char, index}, {1, true, common_chars}, other_string) do
    case char == String.at(other_string, index) do
      true -> {1, true, common_chars <> char}
      false -> {2, false, common_chars}
    end
  end
  defp compare_string_chars({char, index}, {0, true, common_chars}, other_string) do
    case char == String.at(other_string, index) do
      true -> {0, true, common_chars <> char}
      false -> {1, true, common_chars}
    end
  end
  defp compare_string_chars(_, {2, false, _} = acc, _), do: acc

  ## Part 2, but cleaner and simpler ##

  defp find_close_id_chars([id | rest], dict \\ %{}) do
    case search_id_permutations(id, dict) do
      {:found, chars} -> chars
      {:cont, prev_dict, new_dict} ->
        find_close_id_chars(rest, Map.merge(prev_dict, new_dict))
    end
  end

  defp search_id_permutations(id, dict) do
    Range.new(0, String.length(id) - 1)
    |> Enum.reduce_while({:cont, dict, %{}}, &collect_permutation(&1, &2, id))
  end

  defp collect_permutation(index, {_, prev_dict, new_dict}, id) do
    head = id |> String.slice(0, index)
    tail = id |> String.slice(index + 1, String.length(id))

    permutation = head <> tail
    case Map.get(prev_dict, permutation) do
      true -> {:halt, {:found, permutation}}
      nil -> {:cont, {:cont, prev_dict, new_dict |> Map.put(permutation, true)}}
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
