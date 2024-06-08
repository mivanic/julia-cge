using JuMP, HiGHS, Ipopt, NamedArrays, ClipData, Tables, DataFrames

include("demand_les.jl")
include("factordemand_ces.jl")

com = ["rice", "wheat", "corn"]
fac = ["labor", "capital"]
reg = ["usa", "canada", "australia"]

sv = 16

model = JuMP.Model(Ipopt.Optimizer)

@variables(model,
    begin
         0.1 <= qₚ[i=com, r=reg] # quantity consumed
         0.1 <= pₚ[i=com] # quantity consumed
         0.1 <= qₑ[f=fac, i=com, r=reg] # quantity consumed
         0.1 <= qₛ[i=com, r=reg] # quantity consumed
         0.1 <= pₑ[f=fac, r=reg] # quantity consumed
         0.1 <= y[r=reg]  # quantity consumed
         0.1 <= qₑₜ[f=fac, r=reg]  # quantity consumed
         0.1 <= pₑₜ # Factor price
            end
)


αₚ=JuMP.Containers.DenseAxisArray([0.2 0.5 0.3; 0.4 0.5 0.1;0.4 0.5 0.1], reg, com)
γₚ=JuMP.Containers.DenseAxisArray([0.4 0.2 0.1; 0.3 0.2 0.1;0.1 0.2 0.3], reg, com)
αₒ=JuMP.Containers.DenseAxisArray([0.4 0.6; 0.5 0.5; 0.7 0.3],   reg, fac)
σₚ = 3

@constraints(
    model,
    begin
    [r = reg], demand(pₚ, y[r], αₚ[r,:], γₚ[r,:]) .== qₚ[:,r] # consumer demand
    [i = com], sum(qₛ[i,:])==sum(qₚ[i,:]) # Market clearing (frictionless trade)
    [i = com, r=reg], factordemand(qₛ[i,r], pₑ[:,r], αₒ[r,:], σₚ, 1) .== qₑ[:, i, r] # factor demand 
    [r = reg[1:2]], sum(qₑₜ[:,r] .* pₑ[:,r]) == y[r] # Income equation
    [f = fac, r = reg], qₑₜ[f,r] == sum(qₑ[f, :,r]) # Factor clearing
    [i = com, r =reg], sum(qₑ[:, i, r] .* pₑ[:,r]) == qₛ[i,r] * pₚ[i] # zero profits
    end
)

fix(pₚ["wheat"], 10; force = true)
fix(qₑₜ["labor","usa"], 4; force = true)
fix(qₑₜ["capital","usa"], 2; force = true)
fix(qₑₜ["labor","canada"], 1; force = true)
fix(qₑₜ["capital","canada"], 3; force = true)
fix(qₑₜ["labor","australia"], 1; force = true)
fix(qₑₜ["capital","australia"], 1; force = true)

optimize!(model)

fix(qₑₜ["capital","australia"], 2; force = true)

optimize!(model)

value.(qₚ)