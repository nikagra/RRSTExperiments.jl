using Random, Distributions
using Graphs
using Pkg, Revise
using CSV, DataFrames
using JuMP, CPLEX
using SparseArrays

Pkg.activate(".")
using RRSTExperiments

function generate_graph(seed::UInt32, n::Int; max_weight = 10)
    Random.seed!(seed * n)

    V = collect(1:n) # set of vertices
    E = Tuple{Int64, Int64}[]
    C = Float64[]

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
        end
    end

    return (E, C)
end

function prepare_graph(seed::UInt32, n::Int, α::Float64 = 1.0, β::Float64 = 3.0)
    # Read vertices, edges and first stage costs
    E, C = generate_graph(seed, n; max_weight = 100)
  
    # Assume second stage costs are equal to first stage costs
    c = copy(C)
  
    dist = Beta(α, β)
    d = generate_uncertain_costs(dist, c)
  
    return (E, C, c, d)
  end

function solve_tree_model(n::Int, E::Vector{InputEdge})
    V = collect(1:n) # set of nodes
    Vminus1 = setdiff(V, [1]) # commodity nodes
    A = [(e.i, e.j) for e ∈ E] ∪ [(e.j, e.i) for e ∈ E]

    # Model
    model = Model(CPLEX.Optimizer)
    set_silent(model)
    set_optimizer_attribute(model, "CPX_PARAM_EPINT", 1e-8)

    # Variables
    @variable(model, y[E] ≥ 0) # yₑ=1 if e∈E belongs to the spanning tree; 0 otherwise 
    @variable(model, w[A] ≥ 0)
    @variable(model, f[A, Vminus1] ≥ 0) # flow variables

    # Objective
    @objective(model, Min, sum(E[i].C * y[e] for (i, e) ∈ enumerate(E)))

    #Constraints
    for k ∈ Vminus1 # sources
        @constraint(model, sum(f[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
        sum(f[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
    end

    for k ∈ Vminus1, i ∈ Vminus1 # balances
        if i ≠ k
            @constraint(model, sum(f[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
            sum(f[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
        end
    end

    for k ∈ Vminus1 # sinks
        @constraint(model, sum(f[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
        sum(f[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
    end

    for k ∈ Vminus1, a ∈ A # capacity
        @constraint(model, f[a,k] ≤ w[a]) 
    end

    # tree
    @constraint(model, sum(w[a] for a ∈ A) == n - 1)

    for e ∈ E
        @constraint(model, y[e] == w[(e.i, e.j)] + w[(e.j, e.i)])
    end

    # Solve
    
    optimize!(model)

    status=termination_status(model)
    if status == MOI.OPTIMAL
        obj_value = objective_value(model)
        return status, obj_value, Array(value.(y))
    else
        return status, missing, missing
    end
end

function solve_tree_kruskal(n, A)
    weight_map::Dict{Tuple{Int64, Int64}, Float64} = Dict()
    g = SimpleGraph(n)
    for e in A
      add_edge!(g, e.i, e.j)
      push!(weight_map, (e.i, e.j) => e.C)
    end
    
    w_mat = spzeros(Float64, n, n)
    for e in A
        w_mat[e.i, e.j] = e.C
        w_mat[e.j, e.i] = e.C
    end
    
    t_x = kruskal_mst(g, w_mat)

    obj_value = get_objective_value(weight_map, t_x)
    x = get_solution(t_x)
    return obj_value, x
end

function get_objective_value(w::Dict{Tuple{Int64, Int64}, Float64}, t_x::Vector{Edge{Int}})
    return sum(map(e -> haskey(w, (e.src, e.dst)) ? w[(e.src, e.dst)] : w[(e.dst, e.src)], t_x))
  end

function get_solution(t_x::Vector{Edge{Int}})
  return map(e -> (e.src, e.dst), t_x)
end


for n in 25:2500, i in 1:3
    print("n=", n, ", k = ", i, ": ")
    seed::UInt32 = n * i
    E, C, c, d = prepare_graph(seed, n)
    A = [InputEdge(a, b, C[i], c[i], d[i]) for (i, (a,b)) in enumerate(E)]
    obj₁, _ = solve_tree_kruskal(n, A)
    print("obj₁=", obj₁)
    @time begin
        _, obj₂, _ = solve_tree_model(n, A)
        println(", obj₂=", obj₂)
    end
    @assert obj₁ == obj₂
end