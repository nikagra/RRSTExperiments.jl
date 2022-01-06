import RRSTExperiments: InputEdge

"""
    solve_inc_st(n::Int, E::Vector{InputEdge}, x::Vector{Tuple{Int, Int}}, k::Int)

The incremental minimum spanning tree problem
"""
function solve_inc_st(n::Int, E::Vector{InputEdge}, x::Vector{Tuple{Int, Int}}, k::Int)
    V = collect(1:n) # set of nodes
    Vminus1 = setdiff(V, [1]) # commodity nodes
    A = [(e.i, e.j) for e ∈ E] ∪ [(e.j, e.i) for e ∈ E]
    X = Dict([(e.i, e.j) => ((e.i, e.j) ∈ x ? 1 : 0) for e ∈ E])
    L = n-1-k

    # Model
    model = Model(Cbc.Optimizer)
    set_optimizer_attribute(model, "logLevel", 1)

    # Variables
    @variable(model, y[E] ≥ 0) # yₑ=1 if e∈E belongs to the spanning tree; 0 otherwise 
    @variable(model, w[A] ≥ 0)
    @variable(model, f[A, Vminus1] ≥ 0) # flow variables

    # Objective
    @objective(model, Min, sum(e.c * y[e] for e ∈ E))

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
    obj_value = objective_value(model)
    if status == MOI.OPTIMAL
        return status, obj_value, value.(y)
    else
        return status, missing, missing
    end
end

if false
    n = 6
    E = [InputEdge(1,2,2.0), InputEdge(1,3,6.0), InputEdge(2,4,4.0), InputEdge(2,5,7.0), InputEdge(3,4,2.0), InputEdge(4,6,10.0), InputEdge(5,6,9.0)]
    x = [(1,2), (2,5), (5,6), (4,6), (3,4)]
    k = 1
    status, obj_value, y = solve_inc_st(n, E, x, k)
    if status == MOI.OPTIMAL
        println("the total cost: ", obj_value)
        for e in E
            println("(",e.i,",",e.j,"): ",y[e]) # a spanning tree
        end
    else
    println("Status: ", status)
    end
end