# Data source for ryanir connections https://blog.jonlu.ca/posts/ryan-air
using CSV, DataFrames

df = CSV.read("../data/ryanair/ryanair.csv", DataFrame)

id = 1
airports = Dict()
edges = Dict()
for row in Tables.namedtupleiterator(df)
    origin = getindex(row, Symbol("Origin"))
    if !haskey(airports, origin)
        push!(airports, origin => id)
        global id += 1
    end
    destination = getindex(row, Symbol("Destination"))
    if !haskey(airports, destination)
        push!(airports, destination => id)
        global id += 1
    end

    (from,to) = (airports[origin], airports[destination])
    distance = getindex(row, Symbol("Duration"))
    if !haskey(edges, (from,to)) && !haskey(edges, (to,from))
        push!(edges, (from,to) => distance)
    end
end

n, E, C = id - 1, collect(keys(edges)), collect(values(edges))

# output = open("../data/ryanair/ryanair.gr", "w")
# write(output, "c Ryanair connections with flight times\n")
# write(output, "c Source of connections data: https://blog.jonlu.ca/posts/ryan-air\n")
# write(output, "c Source of flight durations: https://www.ryanair.com/\n")
# write(output, "c\n")
# write(output, "p st ", string(n), " ", string(length(E)), "\n")
# write(output, "c\n")
# for (i, (a, b)) in enumerate(E)
#     write(output, "a ", string(a), " ", string(b), " ", string(C[i]), "\n")
# end
# close(output)