# Data source for london tube https://www.whatdotheyknow.com/request/distance_between_adjacent_underg
using CSV, DataFrames

df = CSV.read("../data/london/london.csv", DataFrame)

id = 1
stations = Dict()
edges = Dict()
for row in Tables.namedtupleiterator(df)
    station_a = getindex(row, Symbol("Station from (A)"))
    if !haskey(stations, station_a)
        push!(stations, station_a => id)
        global id += 1
    end
    station_b = getindex(row, Symbol("Station to (B)"))
    if !haskey(stations, station_b)
        push!(stations, station_b => id)
        global id += 1
    end

    (from,to) = (stations[station_a], stations[station_b])
    distance = getindex(row, Symbol("Distance (Kms)"))
    if !haskey(edges, (from,to)) && !haskey(edges, (to,from))
        push!(edges, (from,to) => round(Int, distance * 1000)) # in meters
    end
end

n, E, C = id - 1, collect(keys(edges)), collect(values(edges))

output = open("../data/london/london.gr", "w")
write(output, "c London Tube Stations Graph with distances\n")
write(output, "c Source: https://www.whatdotheyknow.com/request/distance_between_adjacent_underg\n")
write(output, "c\n")
write(output, "p st ", string(n), " ", string(length(E)), "\n")
write(output, "c\n")
for (i, (a, b)) in enumerate(E)
    write(output, "a ", string(a), " ", string(b), " ", string(C[i]), "\n")
end
close(output)