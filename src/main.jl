# https://medium.com/coffee-in-a-klein-bottle/developing-your-julia-package-682c1d309507
using Random, Distributions
using Graphs
using Pkg, Revise
using CSV, DataFrames

Pkg.activate(".")
using RRSTExperiments
  
function prepare_graph(filename::String, seed::UInt32, α::Float64 = 1.0, β::Float64 = 4.0)
  # Read vertices, edges and first stage costs
  n, E, C = parse_graph_data(filename)

  # Assume second stage costs are equal to first stage costs
  c = copy(C)

  # Generate uncertain costs
  Random.seed!(seed)
  dist = Beta(α, β)
  d = generate_uncertain_costs(dist, c)

  return (n, E, C, c, d)
end
  
function experiment(seed::UInt32)
  n, E, C, c, d = prepare_graph("res/rome99.gr", seed)

  A = [InputEdge(a, b, C[i], c[i], d[i]) for (i, (a,b)) in enumerate(E)]
  ns = []
  ks = []
  λs = []
  cs = []
  hs = []
  for k in 0:0, λ in 0.0:0.1:0.5
      result1 = RRSTExperiments.solve_rec_st_with_algorithm(n, A, k)
      println("n=$n, k=$k, λ=$λ: RRST = $result1")

      _, result2, _, _, _ = RRSTExperiments.solve_rec_st_hurwicz(n, A, k, λ)
      println("n=$n, k=$k, λ=$λ: Hurwicz = $result2")

      push!(ns, n)
      push!(ks, k)
      push!(λs, λ)
      push!(cs, result1)
      push!(hs, result2)
  end

  # Write results
  touch("rome99.csv")
  f = open("rome99.csv", "w")
 
  df = DataFrame(n = ns, k = ks, λ = λs, Combinatorial = cs, Hurwicz = hs)
                
  CSV.write("rome99.csv", df)
end

for seed in 0x00000001:0x00000001
  experiment(seed)
end