
using JuMP
using GLPKMathProgInterface

function solve_model(n::Int,
                    E::Array{Tuple{Int, Int}},
                    C::Dict{Tuple{Int,Int}, Int},
                    c::Dict{Tuple{Int,Int}, Int},
                    L::Int)

  V = collect(1:n) # set of nodes
  V_k = setdiff(V, [1]) # commodity nodes
  A = E ∪ [(j, i) for (i, j) in E]

  # Model
  model = Model(solver=GLPKSolverLP())

  # Variables
  @defVar(model, fx[A, setdiff(V, [1])] ≥ 0)
  @defVar(model, wx[A] ≥ 0)
  @defVar(model, x[E] ≥ 0)

  @defVar(model, fy[A, setdiff(V, [1])] ≥ 0)
  @defVar(model, wy[A] ≥ 0)
  @defVar(model, y[E] ≥ 0)

  @defVar(model, z[E] ≥ 0)

  # Objective
  @setObjective(model, Min, sum{C[(i,j)]*x[(i,j)] + c[(i,j)]*y[(i,j)], (i,j) = E})

  #Constraints
  for k in V_k # sources
    @addConstraint(model, sum{fx[(j,i),k], (j,i) = filter(e -> e[2] == 1, A)} -
      sum{fx[(i,j),k], (i,j) = filter(e -> e[1] == 1, A)} == -1)

    @addConstraint(model, sum{fy[(j,i),k], (j,i) = filter(e -> e[2] == 1, A)} -
      sum{fy[(i,j),k], (i,j) = filter(e -> e[1] == 1, A)} == -1)
  end

  for k in V_k, i in V_k # balances
    if i ≠ k
      @addConstraint(model, sum{fx[(j,i),k], j = filter(j -> (j,i) ∈ A, V)} -
        sum{fx[(i,j),k], j = filter(j -> (i,j) ∈ A, V)} == 0)

      @addConstraint(model, sum{fy[(j,i),k], j = filter(j -> (j,i) ∈ A, V)} -
        sum{fy[(i,j),k], j = filter(j -> (i,j) ∈ A, V)} == 0)
    end
  end

  for k in V_k # sinks
    @addConstraint(model, sum{fx[(j,i),k], (j, i) = filter(e -> e[2] == k, A)} -
      sum{fx[(i,j),k], (i, j) = filter(e -> e[1] == k, A)} == 1)

    @addConstraint(model, sum{fy[(j,i),k], (j, i) = filter(e -> e[2] == k, A)} -
      sum{fy[(i,j),k], (i, j) = filter(e -> e[1] == k, A)} == 1)
  end

  for k in V_k, (i,j) in A # capacity
    @addConstraint(model, fx[(i,j),k] ≤ wx[(i,j)])
    @addConstraint(model, fy[(i,j),k] ≤ wy[(i,j)])
  end

  # tree 1
  @addConstraint(model, sum{wx[(i,j)], (i,j) = A} == n - 1)
  @addConstraint(model, sum{wy[(i,j)], (i,j) = A} == n - 1)

  for (i,j) in E # tree 2
    @addConstraint(model, x[(i,j)] == wx[(i,j)] + wx[(j,i)])
    @addConstraint(model, y[(i,j)] == wy[(i,j)] + wy[(j,i)])
  end

  for (i,j) in E
    @addConstraint(model, x[(i,j)] - z[(i,j)] ≥ 0)
    @addConstraint(model, y[(i,j)] - z[(i,j)] ≥ 0)
  end

  @addConstraint(model, sum{z[(i,j)], (i,j) = E} ≥ L)

  # Solve
  status = solve(model)

  return getObjectiveValue(model)
end

function generate_adams_graph()
  graph = Graphs.simple_graph(7, is_directed = false)

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
  srand(seed)

  V = collect(1:n) # set of vertices
  E = Tuple{Int, Int}[]
  C = Int[]
  c = Int[]

  g = Graphs.simple_graph(n, is_directed = false)
  while length(Graphs.connected_components(g)) > 1
    source = rand(V)
    target = rand(V)
    if source == target || (source, target) ∈ E || (target, source) ∈ E
      continue
    else
      push!(E, (source, target))
      Graphs.add_edge!(g, source, target)
      push!(C, rand(1:max_weight))
      push!(c, rand(1:max_weight))
    end
  end

  return (E, g, C, c)
end

function test(seed::UInt32, n::Int, i::Int)
  E, g, C, c = generate_graph(seed, n)

  for k in 0:(n - 1)
    i += 1
    result1 = solve_model(n, # number of vertices
                          E, # set of edges
                          [e => C[i] for (i, e) in enumerate(E)], # initial costs
                          [e => c[i] for (i, e) in enumerate(E)], # actual costs
                          n - k - 1)
    result2 = SpanningTreeAlgorithm.solve(k, g, C, c)
    println("(seed = ", seed, ", n = ", n, ", k = ", k, ") => ", result1, ", ", result2)
    if result1 ≠ result2
      print("Values of objective function differ (", result1, "≠", result2, ") ")
      println("with seed ", seed, ", ", n, " vertices and k = ", k)
    end
  end

  return i
end

include("algorithm.jl")

i = 0
for seed in 0x00000001:0x000000FF, n in 3:12
 i = test(seed, n, i)
end
println(i)
