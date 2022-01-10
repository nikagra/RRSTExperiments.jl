module RRSTExperiments

using JuMP, CPLEX
using Random, Distributions
using Graphs
using SparseArrays

export InputEdge,
    solve_rec_st_with_algorithm, solve_rec_st_model, solve_minmax_st, solve_rec_st_hurwicz, solve_inc_st,

    parse_graph_data, generate_uncertain_costs, generate_scenario,

    calculate_cost

struct InputEdge
    i::Int64
    j::Int64
    C::Float64
    c::Float64
    d::Float64

    InputEdge(i::Int, j::Int, C::Float64) = new(i, j, C, 0.0, 0.0)
    InputEdge(i::Int, j::Int, C::Float64, c::Float64) = new(i, j, C, c, 0.0)
    InputEdge(i::Int, j::Int, C::Float64, c::Float64, d::Float64) = new(i, j, C, c, d)
end

include("./utils.jl")

include("./inc_st.jl")
include("./rec_st_combinatorial.jl")
include("./rec_st_model.jl")
include("./rob_st_model.jl")
include("./rec_st_hurwicz.jl")

end
