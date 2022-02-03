using CairoMakie
using Random, Distributions
using SpecialFunctions

α = 1.0
β = 3.0

function beta_distribution(x, α, β)
    return gamma(α+β) / (gamma(α) * gamma(β)) * x^(α-1) * (1 - x)^(β - 1)
end


x = range(0, 1, length=100)
y = beta_distribution.(x, α, β)
l = lines(x, y, color = :grey, axis = (xminorticks = IntervalsBetween(4),xminorticksvisible = true,
yminorticksvisible = true,
xminorgridvisible = true,
yminorgridvisible = true,))
xlims!(0, nothing)
ylims!(0, nothing)

save("beta-alpha$(α)-beta$β.pdf", l)