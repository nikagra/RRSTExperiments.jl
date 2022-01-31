using GraphMakie, CairoMakie, Graphs, NetworkLayout, ColorSchemes
using CSV, DataFrames, DataFramesMeta
using Statistics
using Pkg, Revise
using Random

Pkg.activate(".")
using RRSTExperiments

function get_aggregated_data(filename::String)
    df = CSV.read(filename, DataFrame)

    return @chain df begin
        groupby(:rec_param)
        @combine(:minmax_sol_cost = mean(:minmax_sol_cost), :alg_sol_cost = mean(:alg_sol_cost), :minmax_eval_cost = mean(:minmax_eval_cost), :alg_eval_cost = mean(:alg_eval_cost))
    end
end

function generate_plot(london::DataFrame)
    xs = Int[]
    min_val = floor(min(minimum(london[!, :alg_eval_cost]), minimum(london[!, :minmax_eval_cost])); sigdigits = 2)
    max_val = ceil(max(maximum(london[!, :alg_eval_cost]), maximum(london[!, :minmax_eval_cost])); sigdigits = 2)
    ys = Float64[]
    grp = Int[]
    xticks = String[]
    colors = cgrad(:Greys_3)
    for (i, r) in enumerate(eachrow(london))
        row = NamedTuple(r)
        push!(xs, i); push!(xs, i)
        push!(ys, row[:minmax_eval_cost]); push!(ys, row[:alg_eval_cost])
        push!(grp, 1); push!(grp, 2)
        push!(xticks, string(row[:rec_param]))
    end
    f = Figure()
    Axis(f[1, 1], xticks = (1:5, xticks), xlabel = "Wartość parametru naprawy", ylabel = "Wartość funkcji celu")
    barplot!(xs, ys,
            dodge = grp,
            color = colors[grp]
    )
    ylims!(min_val, max_val)
    # Legend
    labels = ["MinMax ST", "RR ST"]
    elements = [PolyElement(polycolor = colors[i]) for i in 1:length(labels)]
    title = "Legenda"

    Legend(f[1,2], elements, labels, title)

    save("output-$(randstring(4)).pdf", f)
end

london = get_aggregated_data("data/london/london_output_1.csv")
# generate_plot(london)

ryanair = get_aggregated_data("data/ryanair/ryanair_output_1.csv")
generate_plot(ryanair)
