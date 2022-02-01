import RRSTExperiments: InputEdge

function get_objective_value(w::Dict{Tuple{Int64, Int64}, Float64}, t_x::Vector{Edge{Int}})
    return sum(map(e -> haskey(w, (e.src, e.dst)) ? w[(e.src, e.dst)] : 0, t_x))
  end

  function get_solution(t_x::Vector{Edge{Int}})
    return map(e -> (e.src, e.dst), t_x)
  end

function solve_minmax_st(n::Int64, A::Vector{InputEdge})
    weight_map::Dict{Tuple{Int64, Int64}, Float64} = Dict()
    g = SimpleGraph(n)
    for e in A
      add_edge!(g, e.i, e.j)
      push!(weight_map, minmax(e.i, e.j) => (e.C + e.c + e.d))
    end
  
    w_mat = spzeros(Float64, n, n)
    for e in A
      w_mat[e.i, e.j] = e.C + e.c + e.d
    end
  
    t_x = kruskal_mst(g, w_mat)
  
    obj_value = get_objective_value(weight_map, t_x)
    x = get_solution(t_x)
    return obj_value, x
end
