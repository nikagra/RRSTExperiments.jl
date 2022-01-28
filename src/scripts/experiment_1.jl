# https://medium.com/coffee-in-a-klein-bottle/developing-your-julia-package-682c1d309507
using Random, Distributions
using Graphs
using Pkg, Revise
using CSV, DataFrames

Pkg.activate(".")
using RRSTExperiments
  
function prepare_graph(filename::String, α::Float64 = 1.0, β::Float64 = 3.0)
  # Read vertices, edges and first stage costs
  n, E, C = parse_graph_data(filename)

  # Assume second stage costs are equal to first stage costs
  c = copy(C)

  dist = Beta(α, β)
  d = generate_uncertain_costs(dist, c)

  return (n, E, C, c, d)
end
  
function experiment(seed::UInt32)
  # Generate uncertain costs
  Random.seed!(seed)

  # Prepare graph
  n, E, C, c, d = prepare_graph("../data/london/london.gr")
  m = length(E)

  A = [InputEdge(a, b, C[i], c[i], d[i]) for (i, (a,b)) in enumerate(E)]
  ns = []; ks = []; cs = []; ms = []; nums = []; c1s = []; c2s = []
  for k in [0, floor(Int64, 0.05 * m), floor(Int64, 0.1 * m), floor(Int64, 0.25 * m), floor(Int64, 0.5 * m)]
    print("n=$n, k=$k: ")
    result1, x₁ = RRSTExperiments.solve_rec_st_with_algorithm(n, copy(A), k)
    print("RRST = $result1, ")

    result2, x₂ = RRSTExperiments.solve_minmax_st(n, A)
    println("MM = $result2.")

    for i in 1:25
      S = generate_scenario(Uniform(), A) # Generating actual scenario
      println("i=", i)
      # _, c₁, _ = RRSTExperiments.solve_inc_st_with_model(n, S, A, x₁, k) # Recovery action for RRST
      c₁, _ = RRSTExperiments.solve_inc_st_with_algorithm(n, S, copy(A), x₁, k) # Recovery action for RRST
      println(c₁)

      push!(ns, n)
      push!(ks, k)
      push!(cs, result1)
      push!(ms, result2)
      push!(nums, i)
      push!(c1s, calculate_cost(A, x₁, c₁))
      push!(c2s, calculate_cost(A, x₂, S))
    end
  end

  # Write results
 open("../data/london/london_output.csv", "w")
 
  df = DataFrame("num_vertices"=>ns, "rec_param"=>ks, "alg_sol_cost"=>cs, "minmax_sol_cost"=>ms, "experiment_num"=>nums, "alg_eval_cost"=>c1s, "minmax_eval_cost"=>c2s)
  println(df)
                
  CSV.write("../data/london/london_output.csv", df)
end

for seed in 0x00000001:0x00000001
  experiment(seed)
end