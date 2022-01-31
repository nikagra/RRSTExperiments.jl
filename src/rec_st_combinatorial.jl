import RRSTExperiments: InputEdge

function opposite_node(edge::Edge, node)
  @assert(Graphs.src(edge) == node || Graphs.dst(edge) == node)
  return Graphs.src(edge) == node ? Graphs.dst(edge) : Graphs.src(edge)
end

"""
    get_edge_path(tree, edge)

Finds unique path in spanning tree `tree` between endpoints of `edge`and returns
list edges on this path (if `edge ∈ tree`, then `[edge]` is returned).
"""
function get_edge_path(tree::Array{Edge{Int64}}, edge::Edge{Int64})
  source = Graphs.src(edge)
  target = Graphs.dst(edge)

  queue = Tuple{Int, Array{Int}}[] # Breadth-first search
  push!(queue, (source, Int[]))
  while !isempty(queue)
    node, path = pop!(queue)
    indices = findall(e -> Graphs.src(e) == node || Graphs.dst(e) == node, tree)
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
function get_admissible_nodes(m::Int64, y::Array{Int64}, nodes::Array{Int64}, edges::Array{Edge{Int64}})
  queue = copy(y) # every e ∈ y is admissible

  visited = falses(length(nodes))
  for i in y
    visited[i] = true
  end

  while !isempty(queue)
    v_1 = pop!(queue)
    indices = findall(e -> Graphs.src(e) == v_1, edges)
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
function build_admissible_graph(edge_indices::Dict{Edge{Int64}, Int64}, t_x::Array{Edge{Int64}}, w_1::Array{Float64}, t_y::Array{Edge{Int64}}, w_2::Array{Float64})
  # First step
  v_0 = values(edge_indices) |> collect
  e_0 = Edge{Int64}[]
  indices = [(e, w_1[edge_indices[e]], w_2[edge_indices[e]]) for e in keys(edge_indices)]
  for (e, w1_e, w2_e) in indices

    if e ∉ t_x
      for (f, w1_f, _) in indices
        if f ∈ get_edge_path(t_x, e) && w1_e == w1_f # && C_e^* == C_f^*
          push!(e_0, Edge(edge_indices[e], edge_indices[f]))
        end
      end
    end

    if e ∉ t_y
      for (f, _, w2_f) in indices
        if f ∈ get_edge_path(t_y, e) && w2_e == w2_f # && \overline{c}_e^* == \overline{c}_f^*
          push!(e_0, Edge(edge_indices[f], edge_indices[e]))
        end
      end
    end
  end

  # Second step
  y = [edge_indices[e] for e in setdiff(t_y, t_x)]
  admissible_nodes = get_admissible_nodes(length(edge_indices), y, v_0, e_0)
  v_0 = filter(v -> v ∈ admissible_nodes, v_0)
  e_0 = filter(e -> Graphs.src(e) ∈ admissible_nodes && Graphs.dst(e) ∈ admissible_nodes, e_0)

  return (v_0, e_0)
end

"""
    find_δ_star(g, t_x, w_1, t_y, w_2)

Finds δ*, which is the smallest value of δ for which inequality originaly not
tight becomes tight
"""
function find_δ_star(edge_indices::Dict{Edge{Int64}, Int64}, t_x, w_1, t_y, w_2)
  δ = Inf;

  edges = keys(edge_indices)
  for e₁ in edges
    for e₂ in edges

      if e₁ ∉ t_x && e₂ ∈ get_edge_path(t_x, e₁) && 0 < w_1[edge_indices[e₁]] - w_1[edge_indices[e₂]] < δ
        δ = w_1[edge_indices[e₁]] - w_1[edge_indices[e₂]]
      end

      if e₂ ∉ t_y && e₁ ∈ get_edge_path(t_y, e₂) && 0 < w_2[edge_indices[e₂]] - w_2[edge_indices[e₁]] < δ
        δ = w_2[edge_indices[e₂]] - w_2[edge_indices[e₁]]
      end
    end
  end

  @assert(δ > 0)
  return δ
end

"""
    modify_costs_with_δ!(edge_indices, v_0, δ_star, w1_star, w2_star)

Modifies vectors of costs `w1_star` and `w2_star` using value of `δ_star`according to rules:

* if some edge is in `v_0`, then w1_star(δ) = w1_star - δ, w2_star(δ) = w2_star
* if some edge is not in `v_0`, then w1_star(δ) = w1_star, w2_star(δ) = w2_star-δ
"""
function modify_costs_with_δ!(edge_indices::Dict{Edge{Int64}, Int64}, v_0, δ_star, w1_star, w2_star)
  for e in keys(edge_indices)
    i = edge_indices[e]
    if i ∈ v_0
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
function get_path(x::Array, y::Array, v_a::Array{Int64}, e_a::Array{Edge{Int64}})
  queue = Tuple{Int, Array{Int}}[]

  # Put all edges of Y to queue
  for e in y
    push!(queue, (e, [e]))
  end

  shortest_path = nothing
  while !isempty(queue)
    (v, path) = pop!(queue)
    if v ∈ v_a
      next_edges = filter(i -> Graphs.dst(e_a[i]) ∉ path,
          findall(x -> Graphs.src(x) == v, e_a))
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
    if Graphs.src(e_x) == v || (Graphs.dst(e_x) == v && !directed)
      push!(edges, e_x)
    end
  end
  return edges
end

function is_acyclic(g, t; directed = false)
  # Workaround for https://github.com/JuliaLang/Graphs.jl/issues/220
  edges = Graphs.Edge[]
  for e in t
    push!(edges, Graphs.Edge(Graphs.src(e), Graphs.dst(e)))
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

function update_trees(edge_indices::Dict{Edge{Int64}, Int64},
                      t_x::Array{Edge{Int64}},
                      w_1::Array{Float64},
                      t_y::Array{Edge{Int64}},
                      w_2::Array{Float64},
                      path::Array{Edge{Int64}},
                      z::Array{Int64})
  path_len = length(path)
  if path_len == 2
    e = path[1] # e ∈ Y
    f = path[2] # f ∈ X
    i_e = edge_indices[e]
    i_f = edge_indices[f]

    can_modify_x = e ∉ t_x && f ∈ get_edge_path(t_x, e)
    can_modify_y = f ∉ t_y && e ∈ get_edge_path(t_y, f)

    if can_modify_x && (!can_modify_y || w_1[i_e] - w_1[i_f] < w_2[i_f] - w_2[i_e])
      t_x = filter(edge -> edge != f, t_x)
      push!(t_x, e)
    else
      t_y = filter(edge -> edge != e, t_y)
      push!(t_y, f)
    end

  elseif edge_indices[path[2]] ∈ z # case 2
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

  return t_x, t_y
end

function get_objective_value(edge_indices::Dict{Edge{Int64}, Int64},
                            t_x::Array{Edge{Int64}},
                            w_1::Array{Float64},
                            t_y::Array{Edge{Int64}},
                            w_2::Array{Float64})
  sum = 0;
  for (e, i) in edge_indices
    if e ∈ t_x
      sum += w_1[i]
    end
    if e ∈ t_y
      sum += w_2[i]
    end
  end
  return sum
end

function get_initial_trees(n::Int, A::Array{InputEdge})
  g = SimpleGraph(n)
  for e in A
    add_edge!(g, e.i, e.j)
  end

  w1_mat = spzeros(Float64, n, n)
  w2_mat = spzeros(Float64, n, n)
  for e in A
    w1_mat[e.i, e.j] = e.C
    w1_mat[e.j, e.i] = e.C

    w2_mat[e.i, e.j] = e.c + e.d
    w2_mat[e.j, e.i] = e.c + e.d
  end

  t_x = kruskal_mst(g, w1_mat)
  t_y = kruskal_mst(g, w2_mat)

  return t_x, t_y
end

function get_first_stage_solution(t_x::Array{Edge{Int64}})::Vector{Tuple{Int, Int}}
  return [(e.src, e.dst) for e ∈ t_x]
end

# Exported function
function solve_rec_st_with_algorithm(n::Int, A::Array{InputEdge}, k::Int)
  L = n - k - 1 # |V| - K - 1, K - recovery parameter

  w1 = [e.C for e in A]
  w2 = [e.c + e.d for e in A]

  t_x, t_y = get_initial_trees(n, A)

  edges = [e.i < e.j ? Edge(e.i, e.j) : Edge(e.j, e.i) for e in A]
  edge_indices = Dict([e => i for (i, e) in enumerate(edges)])

  w1_star, w2_star = copy(w1), copy(w2)

  while length(t_x ∩ t_y) < L
    y = map(e -> edge_indices[e], setdiff(t_y, t_x))
    x = map(e -> edge_indices[e], setdiff(t_x, t_y))
    z = map(e -> edge_indices[e], t_x ∩ t_y)
    w = map(e -> edge_indices[e], setdiff(setdiff(edges, t_x), t_y))

    if isempty(x) && isempty(y) # no further improvements could be done
      break
    end

    # Check if X ∩ V^0 ≠ ∅
    v_0, e_0 = build_admissible_graph(edge_indices, t_x, w1_star, t_y, w2_star)
    while isempty(filter(e -> e ∈ v_0, x)) # no path from Y to X
      # Find δ*
      δ_star = find_δ_star(edge_indices, t_x, w1_star, t_y, w2_star)

      # Modify costs
      w1_star, w2_star = modify_costs_with_δ!(edge_indices, v_0, δ_star, w1_star, w2_star)

      # Add some new nodes to admission graph
      v_0, e_0 = build_admissible_graph(edge_indices, t_x, w1_star, t_y, w2_star)
      # repeat until there is a path from y to x
    end

    # Theorem 4: ∃(T_X', T_Y') satysfying SSOC for θ and |Z'|=|Z|+1
    # Find path from Y to X first
    path_indices = get_path(x, y, v_0, e_0)
    @assert(path_indices !== nothing)
    path = [findfirst(x -> x == i, edge_indices) for i ∈ path_indices]

    # Next modify t_x and t_y as described in the proof of Theorem 4
    t_x, t_y = update_trees(edge_indices, t_x, w1_star, t_y, w2_star, path, z)
  end

  objective_value = get_objective_value(edge_indices, t_x, w1, t_y, w2)
  tree = get_first_stage_solution(t_x)
  return objective_value, tree
end
