# https://medium.com/coffee-in-a-klein-bottle/developing-your-julia-package-682c1d309507
using Random, Graphs
using Pkg, Revise
Pkg.activate(".")
using RRSTExperiments

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
    E = Tuple{Int64, Int64}[]
    C = Float64[]
    c = Float64[]
  
    g = Graphs.SimpleGraph(n)
    while length(Graphs.connected_components(g)) > 1
      source = rand(V)
      target = rand(V)
      if source == target || (source, target) ∈ E || (target, source) ∈ E
        continue
      else
        Graphs.add_edge!(g, source, target)
        push!(E, (source, target))
        push!(C, rand(1:max_weight))
        push!(c, rand(1:max_weight))
      end
    end
  
    return (E, C, c)
  end
  
function test(seed::UInt32, n::Int, i::Int)
    E, C, c = generate_graph(seed, n)

    A = [InputEdge(a, b, C[i], c[i]) for (i, (a,b)) in enumerate(E)]
    for k in 0:(n - 1)
        i += 1
        result1 = RRSTExperiments.solve_rec_st_with_LP(n, A, k)
        result2 = RRSTExperiments.solve_rec_st_with_algorithm(n, A, k)
        println("(seed = ", seed, ", n = ", n, ", k = ", k, ") => ", result1, ", ", result2)
        if result1 ≠ result2
        print("Values of objective function differ (", result1, "≠", result2, ") ")
        println("with seed ", seed, ", ", n, " vertices and k = ", k)
        end
    end

    return i
end

i = 0
for seed in 0x00000001:0x000000FF, n in 3:12
global i = test(seed, n, i)
end
println(i)