
using JuMP
using GLPK
using Graphs
using Random

struct Edge
	i::Int       # edge {i,j}
	j::Int
  C::Float64
	c::Float64   # cij  the cost of edge {i,j}
end

function solve_rec_st_with_LP(n::Int, E::Vector{Edge}, k::Int)

  V = collect(1:n) # set of nodes
  Vminus1 = setdiff(V, [1]) # commodity nodes
  A = [(e.i, e.j) for e ∈ E] ∪ [(e.j, e.i) for e ∈ E]
  L = n-1-k

  # Model
  model = Model(GLPK.Optimizer)
  set_optimizer_attribute(model, "msg_lev", 0)

  # Variables
  @variable(model, fx[A, Vminus1] ≥ 0)
  @variable(model, wx[A] ≥ 0)
  @variable(model, x[E] ≥ 0)

  @variable(model, fy[A, Vminus1] ≥ 0)
  @variable(model, wy[A] ≥ 0)
  @variable(model, y[E] ≥ 0)
  @variable(model, z[E] ≥ 0)


  # Objective
  @objective(model, Min, sum(e.C * x[e] for e ∈ E) + sum(e.c * y[e] for e ∈ E))

  #Constraints
  #Constraints
  for k ∈ Vminus1 # sources
      @constraint(model, sum(fx[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
      sum(fx[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
      @constraint(model, sum(fy[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
      sum(fy[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
  end

  for k ∈ Vminus1, i ∈ Vminus1 # balances
      if i ≠ k
          @constraint(model, sum(f[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
          sum(f[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
          @constraint(model, sum(fy[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
          sum(fy[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
      end
  end

  for k ∈ Vminus1 # sinks
      @constraint(model, sum(f[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
      sum(f[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
      @constraint(model, sum(fy[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
      sum(fy[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
  end

  for k ∈ Vminus1, a ∈ A # capacity
      @constraint(model, fx[a,k] ≤ wx[a])
      @constraint(model, fy[a,k] ≤ wy[a])
  end

  # tree
  @constraint(model, sum(wx[a] for a ∈ A) == n - 1)
  @constraint(model, sum(wy[a] for a ∈ A) == n - 1)

  for e ∈ E
      @constraint(model, x[e] == wx[(e.i, e.j)] + wx[(e.j, e.i)])
      @constraint(model, y[e] == wy[(e.i, e.j)] + wy[(e.j, e.i)])
  end

  for e ∈ E
      @constraint(model, x[e] ≥ z[e])
      @constraint(model, y[e] ≥ z[e])
  end

  @constraint(model, sum(z[e] for e ∈ E) ≥ L)

  # Solve
  optimize!(model)

  return objective_value(model)
end

function generate_adams_graph()
  graph = Graphs.SimpleGraph(7)

  Graphs.add_edge!(graph, 1, 2) # 1
  Graphs.add_edge!(graph, 2, 3) # 2
  Graphs.add_edge!(graph, 3, 4) # 3
  Graphs.add_edge!(graph, 1, 4) # 4
  Graphs.add_edge!(graph, 2, 4) # 5
  Graphs.add_edge!(graph, 1, 5) # 6
  Graphs.add_edge!(graph, 4, 6) # 7
  Graphs.add_edge!(graph, 5, 6) # 8
  Graphs.add_edge!(graph, 5, 7) # 9
  Graphs.add_edge!(graph, 6, 7) # 10
  Graphs.add_edge!(graph, 1, 6) # 11

  weights_1 = [0, 2, 1, 1, 5, 8, 0, 3, 5, 7, 2] # initial costs
  weights_2 = [9, 5, 1, 2, 4, 3, 6, 2, 9, 2, 3] # actual costs

  return graph, weights_1, weights_2
end

function generate_graph(seed::UInt32, n::Int; max_weight = 10)
  Random.seed!(seed)

  V = collect(1:n) # set of vertices
  E = Tuple{Int, Int}[]
  C = zeros(Int64, n, n)
  c = zeros(Int64, n, n)

  g = Graphs.SimpleGraph(n)
  while length(Graphs.connected_components(g)) > 1
    source = rand(V)
    target = rand(V)
    if source == target || (source, target) ∈ E || (target, source) ∈ E
      continue
    else
      push!(E, (source, target))
      Graphs.add_edge!(g, source, target)
      C[source, target] = rand(1:max_weight)
      c[source, target] = rand(1:max_weight)
    end
  end

  return (E, g, C, c)
end

function test(seed::UInt32, n::Int, i::Int)
  E, g, C, c = generate_graph(seed, n)

  A = [Edge(a, b, C[i], c[i]) for (i, (a,b)) in enumerate(E)]
  for k in 0:(n - 1)
    i += 1
    result1 = solve_rec_st_with_LP(n, A, k)
    result2 = SpanningTreeAlgorithm.solve(k, g, C, c)
    println("(seed = ", seed, ", n = ", n, ", k = ", k, ") => ", result1, ", ", result2)
    if result1 ≠ result2
      print("Values of objective function differ (", result1, "≠", result2, ") ")
      println("with seed ", seed, ", ", n, " vertices and k = ", k)
    end
  end

  return i
end

include("rec_st_combinatorial.jl")

i = 0
for seed in 0x00000001:0x000000FF, n in 3:12
 global i = test(seed, n, i)
end
println(i)
