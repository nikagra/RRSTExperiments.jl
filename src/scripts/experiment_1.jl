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
  n, E, C, c, d = prepare_graph("data/london/london.gr")
  m = length(E)

  A = [InputEdge(a, b, C[i], c[i], d[i]) for (i, (a,b)) in enumerate(E)]
  ns = []; ks = []; cs = []; ms = []; nums = []; c1s = []; c2s = []

  result_mm, x₂ = RRSTExperiments.solve_minmax_st(n, A)

  for k in [floor(Int64, 0.05 * m), floor(Int64, 0.1 * m), floor(Int64, 0.25 * m)]
    print("n=$n, k=$k: ")
    result_rr, x₁ = RRSTExperiments.solve_rec_st_with_algorithm(n, copy(A), k)
    println("RRST = $result_rr, MM = $result_mm.")

    for i in 1:5
      S = generate_scenario(Uniform(), A) # Generating actual scenario
      println("i=", i)
      _, c₁, _ = RRSTExperiments.solve_inc_st_with_model(n, S, A, x₁, k) # Recovery action for RRST

      c1 = calculate_cost(A, x₁, c₁)
      c2 = calculate_cost(A, x₂, S)
      push!(ns, n)
      push!(ks, k)
      push!(cs, result_rr)
      push!(ms, result_mm)
      push!(nums, i)
      push!(c1s, c1)
      push!(c2s, c2)
      println("$n,$k,$result_rr,$result_mm,$i,$c1,$c2")
    end
  end

  # Write results
  filename = "data/london/london_output_exp1-$(randstring(4)).csv"
  open(filename, "w")
 
  df = DataFrame("num_vertices"=>ns, "rec_param"=>ks, "alg_sol_cost"=>cs, "minmax_sol_cost"=>ms, "experiment_num"=>nums, "alg_eval_cost"=>c1s, "minmax_eval_cost"=>c2s)
  println(df)
                
  CSV.write(filename, df)
end

experiment(0x00000001)