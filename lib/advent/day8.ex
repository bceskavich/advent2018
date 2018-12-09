defmodule Advent.Day8 do
  @instructions "files/day8.txt"

  def run() do
    IO.puts("Part One — metadata sum = #{part_one()}")
    IO.puts("Part Two — root node sum = #{part_two()}")
  end

  ## Part 1 ##

  defp part_one() do
    {_, sum} = read_instructions()
    |> sum_metadata(0)

    sum
  end

  defp sum_metadata([], sum), do: {[], sum}
  defp sum_metadata([num_nodes | [num_metadata | rest]], sum) do
    {metadata, sum} = case num_nodes do
      0 -> {rest, sum}

      _ ->
        Range.new(1, num_nodes)
        |> Enum.reduce({rest, sum}, fn (_, {children, acc}) ->
          sum_metadata(children, acc)
        end)
    end

    remainder = metadata |> Enum.drop(num_metadata)
    metadata_sum = metadata
    |> Enum.take(num_metadata)
    |> Enum.sum()

    {remainder, metadata_sum + sum}
  end

  ## Part 2 ##

  defp part_two() do
    {_, sum} = read_instructions()
    |> sum_nodes()

    sum
  end

  defp sum_nodes([num_nodes | [num_metadata | rest]]) do
    case num_nodes do
      0 ->
        {metadata, remainder} = Enum.split(rest, num_metadata)
        {remainder, Enum.sum(metadata)}

      _ ->
        {rest, sums} = Range.new(1, num_nodes)
        |> Enum.reduce({rest, []}, fn (_, {children, sums}) ->
          {children, sum} = sum_nodes(children)
          {children, sums ++ [sum]}
        end)

        {metadata, remainder} = Enum.split(rest, num_metadata)
        sum = Enum.reduce(metadata, 0, fn (node_index, sum) ->
          node_value = Enum.at(sums, node_index - 1) || 0
          sum + node_value
        end)

        {remainder, sum}
    end
  end

  ## Shared ##

  defp read_instructions() do
    File.stream!(@instructions)
    |> Enum.reduce([], fn (str, acc) ->
      acc ++ str
      |> String.replace("\n", "")
      |> String.trim()
      |> String.split(" ")
      |> Enum.map(&String.to_integer/1)
    end)
  end
end
