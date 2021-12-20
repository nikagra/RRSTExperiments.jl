
import RRSTExperiments: InputEdge

function solve_rec_st_with_LP(n::Int, E::Vector{InputEdge}, k::Int)

  V = collect(1:n) # set of nodes
  Vminus1 = setdiff(V, [1]) # commodity nodes
  A = [(e.i, e.j) for e ∈ E] ∪ [(e.j, e.i) for e ∈ E]
  L = n-1-k

  # Model
  model = Model(GLPK.Optimizer)
  set_optimizer_attribute(model, "msg_lev", 0)

  # Variables
  @variable(model, fx[A, Vminus1] ≥ 0)
  @variable(model, wx[A] ≥ 0)
  @variable(model, x[E] ≥ 0)

  @variable(model, fy[A, Vminus1] ≥ 0)
  @variable(model, wy[A] ≥ 0)
  @variable(model, y[E] ≥ 0)
  @variable(model, z[E] ≥ 0)


  # Objective
  @objective(model, Min, sum(e.C * x[e] for e ∈ E) + sum(e.c * y[e] for e ∈ E))

  #Constraints
  #Constraints
  for k ∈ Vminus1 # sources
      @constraint(model, sum(fx[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
      sum(fx[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
      @constraint(model, sum(fy[(j,1),k] for j ∈ filter(j -> (j,1) ∈ A, V)) -
      sum(fy[(1,j),k] for j ∈ filter(j -> (1,j) ∈ A,V)) == -1)
  end

  for k ∈ Vminus1, i ∈ Vminus1 # balances
      if i ≠ k
          @constraint(model, sum(fx[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
          sum(fx[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
          @constraint(model, sum(fy[(j,i),k] for j ∈ filter(j -> (j,i) ∈ A, V)) -
          sum(fy[(i,j),k] for j ∈ filter(j -> (i,j) ∈ A, V)) == 0)
      end
  end

  for k ∈ Vminus1 # sinks
      @constraint(model, sum(fx[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
      sum(fx[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
      @constraint(model, sum(fy[(j,k),k] for j ∈ filter(j -> (j,k) ∈ A,V)) -
      sum(fy[(k,j),k] for j ∈ filter(j -> (k,j) ∈ A,V)) == 1)
  end

  for k ∈ Vminus1, a ∈ A # capacity
      @constraint(model, fx[a,k] ≤ wx[a])
      @constraint(model, fy[a,k] ≤ wy[a])
  end

  # tree
  @constraint(model, sum(wx[a] for a ∈ A) == n - 1)
  @constraint(model, sum(wy[a] for a ∈ A) == n - 1)

  for e ∈ E
      @constraint(model, x[e] == wx[(e.i, e.j)] + wx[(e.j, e.i)])
      @constraint(model, y[e] == wy[(e.i, e.j)] + wy[(e.j, e.i)])
  end

  for e ∈ E
      @constraint(model, x[e] ≥ z[e])
      @constraint(model, y[e] ≥ z[e])
  end

  @constraint(model, sum(z[e] for e ∈ E) ≥ L)

  # Solve
  optimize!(model)

  return objective_value(model)
end
