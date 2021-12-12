# requires julia v0.4
module SpanningTreeAlgorithm

export solve

using Graphs

function opposite_node(edge::Graphs.Edge, node)
  @assert(Graphs.source(edge) == node || Graphs.target(edge) == node)
  return Graphs.source(edge) == node ? Graphs.target(edge) : Graphs.source(edge)
end

"""
    get_edge_path(tree, edge)

Finds unique path in spanning tree `tree` between endpoints of `edge`and returns
list edges on this path (if `edge ∈ tree`, then `[edge]` is returned).
"""
function get_edge_path(tree, edge)
  source = Graphs.source(edge)
  target = Graphs.target(edge)

  queue = Tuple{Int, Array{Int}}[] # Breadth-first search
  push!(queue, (source, Int[]))
  while !isempty(queue)
    node, path = shift!(queue)
    indices = find(e -> Graphs.source(e) == node || Graphs.target(e) == node, tree)
    for index in indices
      if index ∉ path
        new_source = opposite_node(tree[index], node)
        path_copy = [copy(path); index]
        if (new_source == target)
          return [tree[i] for i in path_copy]
        else
          push!(queue, (new_source, path_copy))
        end
      end
    end
  end
end

"""
    get_admissible_nodes(y, nodes, edges)

Returns a list of addmissible nodes, which are:

* each `v ∈ y` is admissible node
* each `v ∈ nodes` reachible from any node in `y` by a directed path formed
of edges `e ∈ edges` is admissible
"""
function get_admissible_nodes(y, nodes, edges)
  queue = [Graphs.edge_index(e) for e in y] # every e ∈ y is admissible

  visited = falses(length(nodes))
  for i in [Graphs.edge_index(e) for e in y]
    visited[i] = true
  end

  while !isempty(queue)
    v_1 = shift!(queue)
    indices = find(e -> Graphs.source(e) == v_1, edges)
    for i in indices
         v_2 = opposite_node(edges[i], v_1)
         if !visited[v_2]
           push!(queue, v_2)
           visited[v_2] = true
         end
    end
  end

  return filter(v -> visited[v], nodes)
end

"""
    build_admissible_graph(g, t_x, w_1, t_y, w_2)

Builds admissible graph for graph `g`, using minimum spanning trees `t_x`
(with cost vector `w_1`) and `t_y` (with cost vector `w_2`)
"""
function build_admissible_graph(graph::Graphs.AbstractGraph, t_x::Array, w_1::Array, t_y::Array, w_2::Array)
  # TODO: declare required interfaces (Graphs.@graph_requires graph edge_list)

  # First step
  vertices = Graphs.vertices(graph)
  edges = Graphs.edges(graph)

  v_0 = [Graphs.edge_index(e) for e in Graphs.edges(graph)]
  e_0 = Graphs.Edge{Int}[]
  for (e, w1_e, w2_e) in zip(edges, w_1, w_2)

    if e ∉ t_x
      for (f, w1_f) in zip(edges, w_1)
        if f ∈ get_edge_path(t_x, e) && w1_e == w1_f # && C_e^* == C_f^*
          push!(e_0, Graphs.Edge(length(e_0) + 1, Graphs.edge_index(e), Graphs.edge_index(f)))
        end
      end
    end

    if e ∉ t_y
      for (f, w2_f) in zip(edges, w_2)
        if f ∈ get_edge_path(t_y, e) && w2_e == w2_f # && \overline{c}_e^* == \overline{c}_f^*
          push!(e_0, Graphs.Edge(length(e_0) + 1, Graphs.edge_index(f), Graphs.edge_index(e)))
        end
      end
    end
  end

  # Second step
  y = setdiff(t_y, t_x)
  admissible_nodes = get_admissible_nodes(y, v_0, e_0)
  v_0 = filter(v -> v ∈ admissible_nodes, v_0)
  e_0 = filter(e -> Graphs.source(e) ∈ admissible_nodes && Graphs.target(e) ∈ admissible_nodes, e_0)

  return Graphs.graph(v_0, e_0)
end

"""
    find_δ_star(g, t_x, w_1, t_y, w_2)

Finds δ*, which is the smallest value of δ for which inequality originaly not
tight becomes tight
"""
function find_δ_star(g, t_x, w_1, t_y, w_2)
  δ = Inf;

  for (i, e) in enumerate(Graphs.edges(g))
    for (j, f) in enumerate(Graphs.edges(g))

      if e ∉ t_x && f ∈ get_edge_path(t_x, e) && 0 < w_1[i] - w_1[j] < δ
        δ = w_1[i] - w_1[j]
      end

      if f ∉ t_y && e ∈ get_edge_path(t_y, f) && 0 < w_2[j] - w_2[i] < δ
        δ = w_2[j] - w_2[i]
      end
    end
  end

  @assert(δ > 0)
  return δ
end

"""
    modify_costs_with_δ(g, v_0, δ_star, w1_star, w2_star)

Modifies vectors of costs `w1_star` and `w2_star` using value of `δ_star`according to rules:

* if some edge is in `v_0`, then w1_star(δ) = w1_star - δ, w2_star(δ) = w2_star
* if some edge is not in `v_0`, then w1_star(δ) = w1_star, w2_star(δ) = w2_star-δ
"""
function modify_costs_with_δ(g, v_0, δ_star, w1_star, w2_star)
  for (i, e) in enumerate(Graphs.edges(g))
    if Graphs.edge_index(e) ∈ v_0
      w1_star[i] -= δ_star
    else
      w2_star[i] -= δ_star
    end
  end

  return (w1_star, w2_star)
end

"""
    get_path(x, y, admissible_graph)

Finds a path from one of the edges in `y` to one of the edges in `x` using
an admissible graph `admissible_graph`
"""
function get_path(x::Array, y::Array, admissible_graph::Graphs.AbstractGraph)
  v_a = Graphs.vertices(admissible_graph) # admissible vertices
  e_a = Graphs.edges(admissible_graph) # admissible edges

  queue = Tuple{Int, Array{Int}}[]

  # Put all edges of Y to queue
  for e in y
    push!(queue, (e, [e]))
  end

  shortest_path = nothing
  while !isempty(queue)
    (v, path) = shift!(queue)
    if v ∈ v_a
      next_edges = filter(i -> Graphs.target(e_a[i]) ∉ path,
          find(x -> Graphs.source(x) == v, e_a))
      for e_n in next_edges
        v_n = opposite_node(e_a[e_n], v)
        path_copy = [copy(path); v_n]

        # path found
        if v_n ∈ x && (shortest_path === nothing || length(path_copy) < length(shortest_path))
          shortest_path = path_copy
        else
          push!(queue, (v_n, path_copy))
        end
      end
    end
  end

  return shortest_path
end

function get_adjacent_edges(g, v; directed = false)
  edges = Graphs.Edge[]
  for e_x in Graphs.edges(g) #visit neighbours
    if Graphs.source(e_x) == v || (Graphs.target(e_x) == v && !directed)
      push!(edges, e_x)
    end
  end
  return edges
end

function is_acyclic(g, t; directed = false)
  # Workaround for https://github.com/JuliaLang/Graphs.jl/issues/220
  edges = Graphs.Edge[]
  for e in t
    push!(edges, Graphs.Edge(length(edges) + 1, Graphs.source(e), Graphs.target(e)))
  end
  tree_graph = Graphs.graph(collect(Graphs.vertices(g)), edges)

  if directed # if graph is directed use Graphs library
    return !Graphs.test_cyclic_by_dfs(tree_graph)
  else # custom implementation of DFS otherwise
    visited_vertices = falses(Graphs.nv(tree_graph))
    visited_edges = falses(Graphs.ne(tree_graph))

    for v in Graphs.vertices(tree_graph)
      if visited_vertices[v]
        continue
      end

      edges_to_visit = filter(e -> !visited_edges[Graphs.edge_index(e)], get_adjacent_edges(tree_graph, v, directed=directed))
      stack = [(v, edges_to_visit)]

      while !isempty(stack)
        (v_c, edges) = pop!(stack)
        if visited_vertices[v_c]
          return false
        end

        visited_vertices[v_c] = true
        for e_c in edges
          visited_edges[Graphs.edge_index(e_c)] = true
          v_n = opposite_node(e_c, v_c)
          edges_to_visit = filter(e -> !visited_edges[Graphs.edge_index(e)], get_adjacent_edges(tree_graph, v_n, directed=directed))
          push!(stack, (v_n, edges_to_visit))
        end
      end
    end

    return true
  end
end

function update_trees(g::Graphs.AbstractGraph,
                      t_x::Array,
                      w_1::Array{Int},
                      t_y::Array,
                      w_2::Array{Int},
                      path::Array,
                      z::Array)
  path_len = length(path)
  if path_len == 2
    e = path[1] # e ∈ Y
    f = path[2] # f ∈ X
    i_e = findfirst(Graphs.edges(g), e)
    i_f = findfirst(Graphs.edges(g), f)

    can_modify_x = e ∉ t_x && f ∈ get_edge_path(t_x, e)
    can_modify_y = f ∉ t_y && e ∈ get_edge_path(t_y, f)

    if can_modify_x && (!can_modify_y || w_1[i_e] - w_1[i_f] < w_2[i_f] - w_2[i_e])
      t_x = filter(edge -> edge != f, t_x)
      push!(t_x, e)
    else
      t_y = filter(edge -> edge != e, t_y)
      push!(t_y, f)
    end

  elseif Graphs.edge_index(path[2]) ∈ z # case 2
    e_x = path[1:2:path_len-1]
    g_x = path[2:2:path_len]
    e_y = Array{Graphs.Edge}[]
    g_y = Array{Graphs.Edge}[]
    if isodd(path_len) # case (a)
      e_y = path[3:2:path_len]
      g_y = path[2:2:path_len-1]
    else # case (b)
      e_y = path[3:2:path_len-1]
      g_y = path[2:2:path_len-1]
    end

    t_x = filter(e -> e ∉ g_x, t_x)
    t_x = t_x ∪ e_x

    t_y = filter(e -> e ∉ g_y, t_y)
    t_y = t_y ∪ e_y
  else #case 3
    e_x = Array{Graphs.Edge}[]
    g_x = Array{Graphs.Edge}[]
    e_y = path[1:2:path_len-1]
    g_y = path[2:2:path_len]
    if isodd(path_len) # case (a)
      e_x = path[3:2:path_len]
      g_x = path[2:2:path_len-1]
    else # case (b)
      e_x = path[3:2:path_len-1]
      g_x = path[2:2:path_len-1]
    end

    t_x = filter(e -> e ∉ e_x, t_x)
    t_x = t_x ∪ g_x

    t_y = filter(e -> e ∉ e_y, t_y)
    t_y = t_y ∪ g_y
  end

  return t_x,t_y
end

function get_objective_value(g, t_x, w1, t_y, w2)
  sum = 0;
  edges = Graphs.edges(g)
  for (i, e) in enumerate(edges)
    if e ∈ t_x
      sum += w1[i]
    end
    if e ∈ t_y
      sum += w2[i]
    end
  end
  return sum
end

# Exported function
function solve(K::Int, g::Graphs.AbstractGraph, w1::Array{Int}, w2::Array{Int})
  L = Graphs.nv(g) - K - 1 # |V| - K - 1, K - recovery parameter

  t_x = Graphs.kruskal_mst(g, w1) # _ for anonymous variable
  t_y = Graphs.kruskal_mst(g, w2)

  w1_star, w2_star = copy(w1), copy(w2)

  while length(t_x ∩ t_y) < L
    admissible_graph = build_admissible_graph(g, t_x, w1_star, t_y, w2_star)

    y = map(e -> Graphs.edge_index(e), setdiff(t_y, t_x))
    x = map(e -> Graphs.edge_index(e), setdiff(t_x, t_y))
    z = map(e -> Graphs.edge_index(e), t_x ∩ t_y)
    w = map(e -> Graphs.edge_index(e), setdiff(setdiff(Graphs.edges(g), t_x), t_y))

    if isempty(x) && isempty(y) # no further improvements could be done
      break
    end

    # Check if X ∩ V^0 ≠ ∅
    v_0 = Graphs.vertices(admissible_graph)
    while isempty(filter(e -> e ∈ v_0, x)) # no path from Y to X
      # Find δ*
      δ_star = find_δ_star(g, t_x, w1_star, t_y, w2_star)

      # Modify costs
      w1_star, w2_star = modify_costs_with_δ(g, v_0, δ_star, w1_star, w2_star)

      # Add some new nodes to admission graph
      admissible_graph = build_admissible_graph(g, t_x, w1_star, t_y, w2_star)
      v_0 = Graphs.vertices(admissible_graph)
      # repeat until there is a path from y to x
    end

    # Theorem 4: ∃(T_X', T_Y') satysfying SSOC for θ and |Z'|=|Z|+1
    # Find path from Y to X first
    path_indices = get_path(x, y, admissible_graph)
    @assert(path_indices !== nothing)
    path = map(i -> Graphs.edges(g)[i], path_indices)

    # Next modify t_x and t_y as described in the proof of Theorem 4
    t_x, t_y = update_trees(g, t_x, w1_star, t_y, w2_star, path, z)
    @assert(is_acyclic(g, t_x) && length(t_x) == Graphs.nv(g) - 1)
    @assert(is_acyclic(g, t_y) && length(t_y) == Graphs.nv(g) - 1)

  end

  return get_objective_value(g, t_x, w1, t_y, w2)
end

end
