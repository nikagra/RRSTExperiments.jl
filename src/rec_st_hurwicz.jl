import RRSTExperiments: InputEdge

function get_first_stage_solution(x::Array{Float64}, E::Vector{InputEdge})::Vector{Tuple{Int, Int}}
    return [(e.i, e.j) for (i, e) ∈ enumerate(E) if x[i] > 0]
end

function solve_rec_st_hurwicz(n::Int,
    E::Vector{InputEdge},
    k::Int,
    λ::Float64)

    V = collect(1:n) # set of nodes
    Vminus1 = setdiff(V, [1]) # commodity nodes
    A = [(e.i, e.j) for e ∈ E] ∪ [(e.j, e.i) for e ∈ E]
    L = n-1-k

    # Model
    model = Model(CPLEX.Optimizer)
    set_silent(model)
    set_optimizer_attribute(model, "CPX_PARAM_EPINT", 1e-8)

    # Variables
    @variable(model, fx[A, Vminus1] ≥ 0)
    @variable(model, wx[A] ≥ 0)
    @variable(model, x[E] ≥ 0, Bin)

    @variable(model, fy¹[A, Vminus1] ≥ 0)
    @variable(model, wy¹[A] ≥ 0)
    @variable(model, y¹[E] ≥ 0, Bin)
    @variable(model, z¹[E] ≥ 0)

    @variable(model, fy²[A, Vminus1] ≥ 0)
    @variable(model, wy²[A] ≥ 0)
    @variable(model, y²[E] ≥ 0, Bin)
    @variable(model, z²[E] ≥ 0)

    # Objective
    @objective(model, Min, sum(e.C * x[e] for e ∈ E) + λ * sum(e.c * y¹[e] for e ∈ E) + (1-λ) * sum((e.c + e.d) * y²[e] for e ∈ E))

    #Constraints
    for k ∈ Vminus1 # sources
        @constraint(model, sum(fx[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
        sum(fx[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
        @constraint(model, sum(fy¹[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
        sum(fy¹[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
        @constraint(model, sum(fy²[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
        sum(fy²[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
    end

    for k ∈ Vminus1, i ∈ Vminus1 # balances
        if i ≠ k
            @constraint(model, sum(fx[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
            sum(fx[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
            @constraint(model, sum(fy¹[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
            sum(fy¹[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
            @constraint(model, sum(fy²[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
            sum(fy²[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
        end
    end

    for k ∈ Vminus1 # sinks
        @constraint(model, sum(fx[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
        sum(fx[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
        @constraint(model, sum(fy¹[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
        sum(fy¹[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
        @constraint(model, sum(fy²[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
        sum(fy²[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
    end

    for k ∈ Vminus1, a ∈ A # capacity
        @constraint(model, fx[a,k] ≤ wx[a])
        @constraint(model, fy¹[a,k] ≤ wy¹[a]) 
        @constraint(model, fy²[a,k] ≤ wy²[a]) 
    end

    # tree
    @constraint(model, sum(wx[a] for a ∈ A) == n - 1)
    @constraint(model, sum(wy¹[a] for a ∈ A) == n - 1)
    @constraint(model, sum(wy²[a] for a ∈ A) == n - 1)

    for e ∈ E
        @constraint(model, x[e] == wx[(e.i, e.j)] + wx[(e.j, e.i)])
        @constraint(model, y¹[e] == wy¹[(e.i, e.j)] + wy¹[(e.j, e.i)])
        @constraint(model, y²[e] == wy²[(e.i, e.j)] + wy²[(e.j, e.i)])
    end

    for e ∈ E
        @constraint(model, x[e] ≥ z¹[e])
        @constraint(model, x[e] ≥ z²[e])
   
        @constraint(model, y¹[e] ≥ z¹[e])
        @constraint(model, y²[e] ≥ z²[e])
    end

    @constraint(model, sum(z¹[e] for e ∈ E) ≥ L)
    @constraint(model, sum(z²[e] for e ∈ E) ≥ L)

    # Solve
    optimize!(model)

    status=termination_status(model)
    obj_value = objective_value(model)
    if status == MOI.OPTIMAL
        return status, obj_value, get_first_stage_solution(Array(value.(x)), E)
    else
        return status, missing, missing
    end
end

if false
    n = 6
    E = [
        InputEdge(1, 2, 0.0, 9.0, 1.0) # 1
        InputEdge(2, 3, 2.0, 5.0, 1.0) # 2
        InputEdge(3, 4, 1.0, 1.0, 1.0) # 3
        InputEdge(1, 4, 1.0, 2.0, 1.0) # 4
        InputEdge(2, 4, 5.0, 4.0, 1.0) # 5
        InputEdge(1, 5, 8.0, 3.0, 1.0) # 6
        InputEdge(4, 6, 0.0, 6.0, 1.0) # 7
        InputEdge(5, 6, 3.0, 2.0, 1.0) # 8
        InputEdge(5, 7, 5.0, 9.0, 1.0) # 9
        InputEdge(6, 7, 7.0, 2.0, 1.0) # 10
        InputEdge(1, 6, 2.0, 3.0, 1.0) # 11
    ]
    k = 1
    λ = 1.0
    status, obj_value, x, y¹, y² = solve_rec_st_hurwicz(n, E, k, λ)
end