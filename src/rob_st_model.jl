import RRSTExperiments: InputEdge

function get_first_stage_solution(E::Vector{InputEdge}, x::Vector{Float64})::Vector{Tuple{Int, Int}}
    @assert length(E) == length(x)
    return [(e.i, e.j) for (i, e) ∈ enumerate(E) if x[i] > 0]
  end

function solve_rob_st_model(n::Int, E::Vector{InputEdge}, k::Int)

  V = collect(1:n) # set of nodes
  Vminus1 = setdiff(V, [1]) # commodity nodes
  A = [(e.i, e.j) for e ∈ E] ∪ [(e.j, e.i) for e ∈ E]

  # Model
  model = Model(Cbc.Optimizer)
  set_optimizer_attribute(model, "logLevel", 1)

  # Variables
  @variable(model, fx[A, Vminus1] ≥ 0)
  @variable(model, wx[A] ≥ 0)
  @variable(model, x[E] ≥ 0)

  # Objective
  @objective(model, Min, sum((e.C + e.c +e.d) * x[e] for e ∈ E))

  #Constraints
  #Constraints
  for k ∈ Vminus1 # sources
      @constraint(model, sum(fx[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
      sum(fx[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
  end

  for k ∈ Vminus1, i ∈ Vminus1 # balances
      if i ≠ k
          @constraint(model, sum(fx[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
          sum(fx[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
      end
  end

  for k ∈ Vminus1 # sinks
      @constraint(model, sum(fx[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
      sum(fx[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
  end

  for k ∈ Vminus1, a ∈ A # capacity
      @constraint(model, fx[a,k] ≤ wx[a])
  end

  # tree
  @constraint(model, sum(wx[a] for a ∈ A) == n - 1)

  for e ∈ E
      @constraint(model, x[e] == wx[(e.i, e.j)] + wx[(e.j, e.i)])
  end

  # Solve
  optimize!(model)

  status=termination_status(model)
  if status == MOI.OPTIMAL
    solution = Array(value.(x))
    println("Solution: ", typeof(solution))
    return status, objective_value(model), get_first_stage_solution(E, solution)
else
    return status, missing, missing
end
end
