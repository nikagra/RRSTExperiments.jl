using GraphMakie, CairoMakie, Graphs, NetworkLayout
using Pkg, Revise
using CSV, DataFrames

Pkg.activate(".")
using RRSTExperiments

n, E, C = parse_graph_data("../data/london/london.gr")
g = SimpleGraph(n)
for e in E
  add_edge!(g, e[1], e[2])
end


# df = CSV.read("../data/london/london_output.csv", DataFrame)

layout = Stress(Ptype=Float32)
f, ax, p = graphplot(g, layout=layout)
hidedecorations!(ax); hidespines!(ax); ax.aspect = DataAspect(); f
# save("figure.pdf", f, pt_per_unit = 1)

n, E, C = parse_graph_data("../data/ryanair/ryanair.gr")
node_limit = ceil(Int, n / 4)
println(node_limit)
g = SimpleGraph(node_limit)
for e in E
  if (e[1] ≤ node_limit && e[2] ≤ node_limit)
    add_edge!(g, e[1], e[2])
  end
end

layout = Shell(nlist=[floor(Int, node_limit/2):node_limit,])
f, ax, p = graphplot(g, layout=layout)
hidedecorations!(ax); hidespines!(ax); ax.aspect = DataAspect();
# save("ryanair.pdf", f, pt_per_unit = 1)