function parse_graph_data(name::String)
    local n
    E = Tuple{Int64, Int64}[]
    C = Float64[]
    open(name) do file
        while ! eof(file)
            line = readline(file)
            designator = line[begin]
            if (designator == 'p')
                elems = split(line, " ", keepempty = false)

                @assert(length(elems) == 4)

                n = parse(Int, elems[3])
            elseif (designator == 'a')
                elems = split(line, " ", keepempty = false)

                @assert(length(elems) == 4)

                v₁ = parse(Int64, elems[2])
                v₂ = parse(Int64, elems[3])
                push!(E, (v₁, v₂))

                Cᵢ = parse(Int64, elems[4])
                push!(C, Cᵢ)
            end
        end
    end
    return n, E, C
end

function generate_uncertain_costs(dist::Distribution, c::Vector{Float64})
    return map(cᵢ -> cᵢ * rand(dist), c)
end

function generate_scenario(dist::Distribution, A::Vector{InputEdge})
    return [e.c + rand(dist) * e.d for e ∈ A]
end

function calculate_cost(A::Vector{InputEdge}, x::Vector{Tuple{Int64, Int64}}, c::Float64)
    C = sum([e.C for e ∈ A if (e.i, e.j) in x || (e.j, e.i) in x])
    return C + c
end