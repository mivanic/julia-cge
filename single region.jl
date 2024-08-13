using JuMP, HiGHS, Ipopt, NamedArrays

include("demand_cd.jl")
include("factordemand_cd.jl")

com = ["rice", "wheat", "corn"]
fac = ["labor", "capital"]

model = JuMP.Model(Ipopt.Optimizer)

@variables(model,
    begin
        qₚ[i=com] # quantity consumed
        0.01 <= pₚ[i=com] # price commodity
        vₚ[i=com] # value of commodity
        y           # income
        qₑ[i=com, j=fac]   # factor employed
        qₑₜ[i=fac]  # factors supplied
        0.01 <= pₑ[j=fac]   # factor price
    end
)

αₚ = [0.2, 0.5, 0.3]
αₒ = [0.4, 0.6]

@constraint(model, demand(pₚ, y, αₚ) .== qₚ) # consumer demand
#@constraint(model, [i = ["wheat"]], demand(pₚ, y, αₚ)[i] == qₚ[i]) # consumer demand
@constraint(model, [i = com], factordemand(qₚ[i], pₑ, pₚ[i], αₒ, 1) .== qₑ[i, :]) # factor demand
@constraint(model, [i = fac], qₑₜ[i] == sum(qₑ[:, i])) # market clearing for factors
@constraint(model, [i = com], sum(qₑ[i, :] .* pₑ) == qₚ[i] * pₚ[i]) # zero profit condition
#@constraint(model, sum(qₑₜ .* pₑ) == y)

fix(y, 0.1)
fix(qₑₜ["labor"], 4)
fix(qₑₜ["capital"], 2)

optimize!(model)

unfix(y)
fix(pₚ["wheat"],1; force = true)

optimize!(model)

unfix(pₚ["wheat"])
JuMP.set_lower_bound(pₚ["wheat"],0.01)
fix(qₚ["wheat"],0.4)

optimize!(model)


value.(qₑₜ) .* value.(pₑ)
value(y)
value.(pₚ)
value.(qₚ)
value.(qₑ)