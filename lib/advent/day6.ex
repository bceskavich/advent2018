# Holds cell distance state
defmodule Cell do
  defstruct [
    id: nil,
    dist: nil,
    closest: nil
  ]

  def new(), do: %__MODULE__{id: :rand.uniform(123456789)}

  def update_dist(%__MODULE__{dist: dist} = cell, new_dist, id) do
    cond do
      dist == nil -> %__MODULE__{cell | dist: new_dist, closest: id}
      new_dist < dist -> %__MODULE__{cell | dist: new_dist, closest: id}
      dist == new_dist -> %__MODULE__{cell | dist: new_dist, closest: :multiple}
      true -> cell
    end
  end
end

# Owns large matrix
defmodule Graph do
  defstruct cells: [[]]

  def new(%{max: {max_x, max_y}, min: {min_x, min_y}}) do
    %__MODULE__{
      cells: for _ <- min_y..max_y do
        for _ <- min_x..max_x do
          Cell.new()
        end
      end
    }
  end

  def get_upper_bounds(%__MODULE__{cells: cells}) do
    {
      (cells |> Enum.at(0) |> length()) - 1,
      length(cells) - 1,
    }
  end

  def get_cell(%__MODULE__{cells: cells}, {x, y}) do
    cells
    |> Enum.at(y)
    |> Enum.at(x)
  end

  def set_cell(%__MODULE__{cells: cells} = graph, {x, y}, cell) do
    row = Enum.at(cells, y)
    next_cells = List.replace_at(cells, y, List.replace_at(row, x, cell))

    %__MODULE__{graph | cells: next_cells}
  end
end

defmodule Advent.Day6 do
  @instructions "files/day6.txt"

  def run() do
    IO.puts("Part One: #{part_one()}")
    IO.puts("Part Two: #{part_two()}")
  end

  ## Part One ##

  defp part_one() do
    coords = read_instructions()
    bounds = find_bounds(coords)
    graph = Graph.new(bounds)

    traverse_graph(graph, bounds, coords)
    |> find_largest_area()
  end

  defp find_largest_area(%Graph{cells: cells} = graph) do
    upper_bounds = Graph.get_upper_bounds(graph)

    Enum.reduce(Enum.with_index(cells), %{}, fn ({row, y}, acc) ->
      Enum.reduce(Enum.with_index(row), acc, fn ({cell, x}, areas) ->
        update_areas(areas, cell, {x, y}, upper_bounds)
      end)
    end)
    |> Map.values()
    |> Enum.reduce(0, fn (area, acc) ->
      cond do
        area == :infinite -> acc
        area <= acc -> acc
        true -> area
      end
    end)
  end

  defp update_areas(
    areas,
    %Cell{closest: closest},
    {x, y},
    {max_x, max_y}
  ) when x == 0 or y == 0 or x == max_x or y == max_y do
    case Map.get(areas, closest) do
      nil -> Map.put(areas, closest, :infinite)
      _ -> %{areas | closest => :infinite}
    end
  end
  defp update_areas(areas, %Cell{closest: :multiple}, _, _), do: areas
  defp update_areas(areas, %Cell{closest: closest}, _, _) do
    case Map.get(areas, closest) do
      nil -> Map.put(areas, closest, 1)
      :infinite -> areas
      area -> %{areas | closest => area + 1}
    end
  end

  defp traverse_graph(graph, _, []), do: graph
  defp traverse_graph(graph, bounds, [coords | rest]) do
    coords = translate_coords(coords, bounds)
    graph
    |> traverse_graph_for_coords(coords)
    |> traverse_graph(bounds, rest)
  end

  defp traverse_graph_for_coords(graph, node_coords) do
    {max_x, max_y} = Graph.get_upper_bounds(graph)
    x_range = Range.new(0, max_x)
    y_range = Range.new(0, max_y)

    Enum.reduce(y_range, graph, fn (at_y, acc) ->
      Enum.reduce(x_range, acc, fn (at_x, current_graph) ->
        update_cell_dist(current_graph, {at_x, at_y}, node_coords)
      end)
    end)
  end

  defp update_cell_dist(graph, current_coords, node_coords) do
    dist = get_distance(current_coords, node_coords)
    cell = Graph.get_cell(graph, current_coords)
    node = Graph.get_cell(graph, node_coords)

    Graph.set_cell(graph, current_coords, Cell.update_dist(cell, dist, node.id))
  end

  ## Part 2 ##

  defp part_two() do
    coords = read_instructions()
    %{min: {min_x, min_y}, max: {max_x, max_y}} = find_bounds(coords)

    x_range = Range.new(min_x, max_x)
    y_range = Range.new(min_y, max_y)

    Enum.reduce(y_range, 0, fn (y, acc) ->
      Enum.reduce(x_range, acc, fn (x, total) ->
        case sum_dists_from_point({x, y}, coords) < 10000 do
          true -> total + 1
          false -> total
        end
      end)
    end)
  end

  defp sum_dists_from_point(from, coords) do
    Enum.reduce(coords, 0, &(get_distance(from, &1) + &2))
  end

  ## Shared ##

  defp get_distance({x, y}, {start_x, start_y}), do: abs(x - start_x) + abs(y - start_y)

  defp translate_coords({x, y}, %{min: {min_x, min_y}}), do: {x - min_x, y - min_y}

  defp find_bounds(coords) do
    %{
      max: Enum.reduce(coords, {nil, nil}, &find_max_bounds/2),
      min: Enum.reduce(coords, {nil, nil}, &find_min_bounds/2)
    }
  end

  defp find_max_bounds({x, y}, {nil, nil}), do: {x, y}
  defp find_max_bounds({x, y}, {prev_x, prev_y}) when x > prev_x and y > prev_y, do: {x, y}
  defp find_max_bounds({x, _}, {prev_x, prev_y}) when x > prev_x, do: {x, prev_y}
  defp find_max_bounds({_, y}, {prev_x, prev_y}) when y > prev_y, do: {prev_x, y}
  defp find_max_bounds(_, acc), do: acc

  defp find_min_bounds({x, y}, {nil, nil}), do: {x, y}
  defp find_min_bounds({x, y}, {prev_x, prev_y}) when x < prev_x and y < prev_y, do: {x, y}
  defp find_min_bounds({x, _}, {prev_x, prev_y}) when x < prev_x, do: {x, prev_y}
  defp find_min_bounds({_, y}, {prev_x, prev_y}) when y < prev_y, do: {prev_x, y}
  defp find_min_bounds(_, acc), do: acc

  defp read_instructions() do
    File.stream!(@instructions)
    |> Enum.map(fn str ->
      [x, y] = str
      |> String.replace("\n", "")
      |> String.trim()
      |> String.split(",")

      {
        String.to_integer(x),
        y |> String.trim() |> String.to_integer()
      }
    end)
  end
end
