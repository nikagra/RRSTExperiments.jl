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
  ns = []; ks = []; cs = []; ms = []; nums = []; c1s = []; c2s = []; λs = []
  for k in [0, floor(Int64, 0.05 * m)]
    println("n=$n, k=$k: ")
    result1, x₁ = RRSTExperiments.solve_rec_st_with_algorithm(n, copy(A), k)

    for λ in [0.25, 0.75]
      print("    RRST = $result1, ")
      _, result2, x₂ = RRSTExperiments.solve_rec_st_hurwicz(n, copy(A), k, λ)
      println("Hurwicz = $result2.")

      println("    |symdiff(x₁, x₂)| = $(length(symdiff(x₁, x₂)))")
      println("    ∑Cx₁ = $(sum([e.C for e ∈ A if (e.i, e.j) in x₁ || (e.j, e.i) in x₁]))")
      println("    ∑Cx₂ = $(sum([e.C for e ∈ A if (e.i, e.j) in x₂ || (e.j, e.i) in x₂]))")

      for i in 1:5
        S = generate_scenario(Uniform(), A) # Generating actual scenario
        println("i=", i)
        _, c₁, _ = RRSTExperiments.solve_inc_st_with_model(n, S, A, x₁, k) # Recovery action for RRST
        _, c₂ , _ = RRSTExperiments.solve_inc_st_with_model(n, S, A, x₂, k) # Recovery action for Hurwicz

        println("    c₁=$c₁, c₂=$c₂")
        c1 = calculate_cost(A, x₁, c₁)
        c2 = calculate_cost(A, x₂, c₂)
        
        push!(ns, n)
        push!(ks, k)
        push!(cs, result1)
        push!(ms, result2)
        push!(λs, λ)
        push!(nums, i)
        push!(c1s, c1)
        push!(c2s, c2)
        println("$n,$k,$λ,$result1,$result2,$i,$c1,$c2")
      end
    end
  end

  # Write results
  filename = "data/london/london_output_$(randstring(4))_hur.csv"
  open(filename, "w")
 
  df = DataFrame("num_vertices"=>ns, "rec_param"=>ks, "λ"=>λs, "alg_sol_cost"=>cs, "hurwicz_sol_cost"=>ms, "experiment_num"=>nums, "alg_eval_cost"=>c1s, "hurwicz_eval_cost"=>c2s)
  println(df)
                
  CSV.write(filename, df)
end

experiment(0x00000001)