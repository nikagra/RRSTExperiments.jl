# https://medium.com/coffee-in-a-klein-bottle/developing-your-julia-package-682c1d309507
using Random, Graphs
using Pkg, Revise
Pkg.activate(".")
using RRSTExperiments

function generate_adams_graph()
  E = [
      (1, 2) # 1
      (1, 3) # 2
      (2, 3) # 3
      (2, 4) # 4
      (3, 4) # 5
      (3, 5) # 6
      (4, 5) # 7
      (4, 6) # 8
      (5, 6) # 9
      (6, 7) # 10
      (5, 7) # 11
    ]

    weights_1 = [2.0, 1.0, 8.0, 0.0, 1.0, 0.0, 2.0, 8.0, 3.0, 5.0, 7.0] # initial costs
    weights_2 = [5.0, 1.0, 3.0, 9.0, 2.0, 6.0, 3.0, 3.0, 2.0, 9.0, 2.0] # actual costs
  
    return E, weights_1, weights_2
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
        if abs(result1 - result2) >= 10 * eps(result1)
          println("Values of objective function differ (", result1, "≠", result2, ") for seed = \"$seed\", n = \"$n\", k = \"$k\"")
        end
    end

    return i
end

i = 0
for seed in 0x00000001:0x000000FF
  for n in 5:25
    global i = test(seed, n, i)
  end
  println("Number of completed experiments: ", i)
end