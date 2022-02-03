using GraphMakie, CairoMakie, Graphs, NetworkLayout, ColorSchemes
using CSV, DataFrames, DataFramesMeta
using Statistics
using Pkg, Revise
using Random

Pkg.activate(".")
using RRSTExperiments

function get_aggregated_data(filename::String, k::Int64)
    df = CSV.read(filename, DataFrame)

    return @chain df begin
        @rsubset :rec_param == k
        groupby(:λ)
        @combine(:hurwicz_sol_cost = mean(:hurwicz_sol_cost), :alg_sol_cost = mean(:alg_sol_cost), :hurwicz_eval_cost = mean(:hurwicz_eval_cost), :alg_eval_cost = mean(:alg_eval_cost))
    end
end

function generate_plot(london::DataFrame, k::Int64)
    xs = Int[]
    min_val = floor(min(minimum(london[!, :alg_eval_cost]), minimum(london[!, :hurwicz_eval_cost])); sigdigits = 3)
    max_val = ceil(max(maximum(london[!, :alg_eval_cost]), maximum(london[!, :hurwicz_eval_cost])); sigdigits = 3)
    ys = Float64[]
    grp = Int[]
    xticks = String[]
    colors = cgrad(:Greys_3)
    for (i, r) in enumerate(eachrow(london))
        row = NamedTuple(r)
        push!(xs, i); push!(xs, i)
        push!(ys, row[:hurwicz_eval_cost]); push!(ys, row[:alg_eval_cost])
        push!(grp, 1); push!(grp, 2)
        push!(xticks, string(row[:λ]))
    end
    f = Figure()
    Axis(f[1, 1], xticks = (1:5, xticks), xlabel = "Wartość λ", ylabel = "Wartość funkcji celu")
    barplot!(xs, ys,
            dodge = grp,
            color = colors[grp]
    )
    ylims!(min_val, max_val)
    # Legend
    labels = ["Hurwicz ST(S)", "RR ST(S)"]
    elements = [PolyElement(polycolor = colors[i]) for i in 1:length(labels)]
    title = "Legenda"

    Legend(f[1,2], elements, labels, title)

    save("data/london/london_output_exp2-$k-$(randstring(4)).pdf", f)
end

for k in [0, 16, 32]
    data = get_aggregated_data("data/london/london_output_exp2.csv", k)
    println(data)
    generate_plot(data, k)
end
