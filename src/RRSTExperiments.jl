module RRSTExperiments

using JuMP
using GLPK
using Random, Distributions
using Graphs

export InputEdge,
    solve_rec_st_with_algorithm, solve_rec_st_with_LP, solve_rec_st_hurwicz, solve_inc_st

struct InputEdge
    i::Int64
    j::Int64
    C::Float64
    c::Float64
    d::Float64

    InputEdge(i::Int, j::Int, C::Float64) = new(i, j, C, 0.0, 0.0)
    InputEdge(i::Int, j::Int, C::Float64, c::Float64) = new(i, j, C, c, 0.0)
end

include("./data_input.jl")

include("./inc_st.jl")
include("./rec_st_combinatorial.jl")
include("./rec_st_lp.jl")
include("./rec_st_hurwicz.jl")

end
