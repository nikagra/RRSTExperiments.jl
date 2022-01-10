import RRSTExperiments: InputEdge

"""
    solve_inc_st(n::Int, E::Vector{InputEdge}, x::Vector{Tuple{Int, Int}}, k::Int)

The incremental minimum spanning tree problem
"""
function solve_inc_st(n::Int, S::Vector{Float64}, E::Vector{InputEdge}, x::Vector{Tuple{Int, Int}}, k::Int)
    @assert length(S) == length(E)
    V = collect(1:n) # set of nodes
    Vminus1 = setdiff(V, [1]) # commodity nodes
    A = [(e.i, e.j) for e ∈ E] ∪ [(e.j, e.i) for e ∈ E]
    X = Dict([(e.i, e.j) => ((e.i, e.j) ∈ x || (e.j, e.i) ∈ x ? 1 : 0) for e ∈ E])
    L = n-1-k

    # Model
    model = Model(CPLEX.Optimizer)
    set_optimizer_attribute(model, "CPX_PARAM_EPINT", 1e-8)

    # Variables
    @variable(model, y[E] ≥ 0) # yₑ=1 if e∈E belongs to the spanning tree; 0 otherwise 
    @variable(model, w[A] ≥ 0)
    @variable(model, f[A, Vminus1] ≥ 0) # flow variables

    # Objective
    @objective(model, Min, sum(S[i] * y[e] for (i, e) ∈ enumerate(E)))

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

    @constraint(model, sum(y[e] * X[(e.i, e.j)] for e ∈ E) ≥ L)

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
