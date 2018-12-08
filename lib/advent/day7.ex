defmodule Advent.Day7.Node do
  defstruct id: nil, visited: false, children: [], parents: []
end

defmodule Advent.Day7.Graph do
  alias Advent.Day7.Node

  defstruct nodes: %{}

  def all_visited?(%__MODULE__{nodes: nodes}) do
    Enum.all?(nodes, fn ({_, node}) -> node.visited end)
  end

  def all_parents_visited?(%__MODULE__{nodes: nodes}, node_id) do
    %Node{parents: parents} = Map.get(nodes, node_id)

    Enum.all?(parents, fn parent_id ->
      %{visited: true} == nodes
      |> Map.get(parent_id)
      |> Map.take([:visited])
    end)
  end

  def put(graph, node_id, parent_id) do
    graph
    |> put_child_node(node_id, parent_id)
    |> put_parent_node(node_id, parent_id)
  end

  def visit(%__MODULE__{nodes: nodes}, node_id) do
    node = Map.get(nodes, node_id)
    node = %Node{node | visited: true}
    %__MODULE__{nodes: %{nodes | node_id => node}}
  end

  defp put_child_node(%__MODULE__{nodes: nodes}, node_id, parent_id) do
    nodes = case Map.get(nodes, node_id) do
      nil ->
        child = %Node{id: node_id, parents: [parent_id]}
        Map.merge(nodes, %{node_id => child})

      %Node{parents: parents} = child ->
        parents = parents ++ [parent_id] |> Enum.dedup()
        child = %Node{child | parents: parents}
        %{nodes | node_id => child}
    end

    %__MODULE__{nodes: nodes}
  end

  defp put_parent_node(%__MODULE__{nodes: nodes}, node_id, parent_id) do
    nodes = case Map.get(nodes, parent_id) do
      nil ->
        parent = %Node{id: parent_id, children: [node_id]}
        Map.merge(nodes, %{parent_id => parent})

      %Node{children: children} = parent ->
        children = children ++ [node_id] |> Enum.dedup()
        parent = %Node{parent | children: children}
        %{nodes | parent_id => parent}
    end

    %__MODULE__{nodes: nodes}
  end
end

defmodule Advent.Day7.Worker do
  defstruct [
    id: nil,
    node_id: nil,
    start_time: nil,
    duration: nil
  ]

  def new(id), do: %__MODULE__{id: id}
end

defmodule Advent.Day7.Scheduler do
  alias Advent.Day7.Worker

  defstruct [
    inactive: [],
    working: []
  ]

  def new(worker_count) do
    %__MODULE__{
      inactive: Enum.map(1..worker_count, &Worker.new/1)
    }
  end

  def all_inactive?(%__MODULE__{working: working}), do: Enum.empty?(working)

  def spawn_workers(scheduler, [], _), do: {scheduler, []}
  def spawn_workers(scheduler, [node_id | rest] = queue, iteration) do
    case can_start_worker?(scheduler) do
      false -> {scheduler, queue}
      true ->
        start_worker(scheduler, node_id, iteration)
        |> spawn_workers(rest, iteration)
    end
  end

  defp can_start_worker?(%__MODULE__{inactive: []}), do: false
  defp can_start_worker?(_), do: true

  defp start_worker(%__MODULE__{inactive: inactive, working: working}, node_id, time) do
    params = %{node_id: node_id, duration: get_duration_for_node(node_id), start_time: time}
    worker = inactive
    |> Enum.at(0)
    |> Map.merge(params)

    %__MODULE__{
      inactive: Enum.drop(inactive, 1),
      working: working ++ [worker]
    }
  end

  def receive(%__MODULE__{inactive: inactive, working: working}, time) do
    {next_working, next_inactive, node_ids} = Enum.reduce(working, {[], [], []}, fn (%Worker{duration: duration, start_time: start_time, node_id: node_id} = worker, {next_working, next_inactive, node_ids}) ->
      case time - start_time == duration do
        true ->
          worker = Map.merge(worker, %{node_id: nil, duration: nil, start_time: nil})
          {next_working, next_inactive ++ [worker], node_ids ++ [node_id]}
        false ->
          {next_working ++ [worker], next_inactive, node_ids}
      end
    end)

    {
      %__MODULE__{working: next_working, inactive: inactive ++ next_inactive},
      node_ids
    }
  end

  defp get_duration_for_node(<<node_value>>), do: node_value - 4
end

defmodule Advent.Day7 do
  alias Advent.Day7.{Graph, Node, Scheduler}

  @instructions "files/day7.txt"
  @pattern ~r/\s(\w{1})\s/

  ## Part Two ##

  def part_one() do
    graph = read_instructions()
    |> build_graph()

    keys = graph
    |> start_node_keys()
    |> sort_node_keys()

    traverse_graph(graph, keys)
  end

  defp traverse_graph(graph, queue, result \\ "")
  defp traverse_graph(_, [], result), do: result
  defp traverse_graph(%Graph{nodes: nodes} = graph, [node_id | queue], result) do
    graph = Graph.visit(graph, node_id)

    case Map.get(nodes, node_id) do
      %Node{visited: true} ->
        node_id <> traverse_graph(graph, queue, result)

      %Node{children: children} ->
        children = Enum.filter(children, &Graph.all_parents_visited?(graph, &1))
        queue = queue ++ children
        |> Enum.dedup()
        |> sort_node_keys()

        node_id <> traverse_graph(graph, queue, result)
    end
  end

  ## Part Two ##

  def part_two() do
    graph = read_instructions()
    |> build_graph()

    keys = graph
    |> start_node_keys()
    |> sort_node_keys()

    scheduler = Scheduler.new(5)

    concurrently_traverse_graph(graph, scheduler, keys)
  end

  defp concurrently_traverse_graph(graph, scheduler, queue, iteration \\ 0) do
    {scheduler, node_ids} = Scheduler.receive(scheduler, iteration)
    graph = visit_nodes(graph, node_ids)
    queue = enqueue_valid_children(graph, node_ids, queue)
    {scheduler, queue} = Scheduler.spawn_workers(scheduler, queue, iteration)

    case completed_concurrent_traversal?(graph, scheduler) do
      true -> iteration
      false -> concurrently_traverse_graph(graph, scheduler, queue, iteration + 1)
    end
  end

  defp visit_nodes(graph, []), do: graph
  defp visit_nodes(graph, [node_id | rest]) do
    graph
    |> Graph.visit(node_id)
    |> visit_nodes(rest)
  end

  defp enqueue_valid_children(_, [], queue), do: queue
  defp enqueue_valid_children(%Graph{nodes: nodes} = graph, [node_id | rest], queue) do
    %Node{children: children} = Map.get(nodes, node_id)
    children = Enum.filter(children, &Graph.all_parents_visited?(graph, &1))
    queue = queue ++ children
    |> Enum.dedup()
    |> sort_node_keys()

    enqueue_valid_children(graph, rest, queue)
  end

  defp completed_concurrent_traversal?(graph, scheduler) do
    Graph.all_visited?(graph) && Scheduler.all_inactive?(scheduler)
  end

  ## Shared ##

  defp build_graph(pairs, graph \\ %Graph{})
  defp build_graph([], graph), do: graph
  defp build_graph([{parent, child} | rest], graph) do
    build_graph(rest, Graph.put(graph, child, parent))
  end

  defp start_node_keys(%Graph{nodes: nodes}) do
    Enum.reduce(nodes, Map.keys(nodes), fn ({_, %Node{children: children}}, keys) ->
      Enum.filter(keys, &(!(&1 in children)))
    end)
  end

  defp sort_node_keys(keys), do: Enum.sort(keys)

  ## Shared ##

  defp read_instructions() do
    File.stream!(@instructions)
    |> Enum.map(fn str ->
      str = str
      |> String.replace("\n", "")
      |> String.trim()

      [[_, parent], [_, child]] = Regex.scan(@pattern, str)

      {parent, child}
    end)
  end
end
