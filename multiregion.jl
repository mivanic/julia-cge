using JuMP, HiGHS, Ipopt, NamedArrays, ClipData, Tables, DataFrames

include("demand_les.jl")
include("factordemand_ces.jl")

com = ["rice", "wheat", "corn"]
fac = ["labor", "capital"]
reg = ["usa", "canada", "australia"]

sv = 16

model = JuMP.Model(Ipopt.Optimizer)

@variable(model,         0.0001 <= qₚ[i=com, r=reg], start = sv) # quantity consumed
@variable(model,         0.0001 <= pₚ[i=com], start = sv) # quantity consumed
@variable(model,         0.0001 <= qₑ[f=fac, i=com, r=reg], start = sv) # quantity consumed
@variable(model,         0.0001 <= qₛ[i=com, r=reg], start = sv) # quantity consumed
@variable(model,         0.0001 <= pₑ[f=fac, r=reg], start = sv) # quantity consumed
@variable(model,         0.0001 <= y[r=reg] , start = sv) # quantity consumed
@variable(model,         0.0001 <= qₑₜ[f=fac, r=reg] , start = sv) # quantity consumed
@variable(model,         0.1 <= pₑₜ, start = sv) # Factor price

# @variables(model,
#     begin
#          0.1 <= qₚ[i=com, r=reg] # quantity consumed
#          0.1 <= pₚ[i=com] # quantity consumed
#          0.1 <= qₑ[f=fac, i=com, r=reg] # quantity consumed
#          0.1 <= qₛ[i=com, r=reg] # quantity consumed
#          0.1 <= pₑ[f=fac, r=reg] # quantity consumed
#          0.1 <= y[r=reg]  # quantity consumed
#          0.1 <= qₑₜ[f=fac, r=reg]  # quantity consumed
#          0.1 <= pₑₜ # Factor price
#             end
# )


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
    # sum(qₑₜ .* pₑ) / sum(qₑₜ)  == pₑₜ
    end
)

# pₚ=JuMP.Containers.DenseAxisArray([10; 10; 10],com)
# y=JuMP.Containers.DenseAxisArray([27.448; 19.112; 10.000], reg)
# qₚ=JuMP.Containers.DenseAxisArray([ 0.809       0.824       0.260;        1.222       0.856       0.400;         0.713       0.231       0.340], com, reg)
# qₛ=JuMP.Containers.DenseAxisArray([0.702       0.978       0.213; 0.787       0.914       0.777;       1.255       0.019       0.010], com, reg)

# qₑ=JuMP.Containers.DenseAxisArray(cat([1.023 1.147 1.830;0.512 0.574 0.915], [0.512 0.478 0.010; 1.536 1.434 0.030 ],[0.213 0.777 0.010; 0.213 0.777 0.010 ], dims = 3), fac, com,reg)
# pₑ=JuMP.Containers.DenseAxisArray([3.528       6.205       7.000; 6.668       4.302       3.000],  fac, reg)

# r="australia"
# i="rice"
# demand(pₚ, y[r], αₚ[r,:], γₚ[r,:]) .- qₚ[:,r]
# sum(qₛ[i,:]) - sum(qₚ[i,:])

# r="canada"
# i="wheat"
# factordemand(qₛ[i,r], pₑ[:,r], αₒ[r,:], σₚ, 1) .- qₑ[:, i, r]

# qₑₜ=JuMP.Containers.DenseAxisArray([4.000       1.000       1.000; 2.000       3.000       1.000],  fac, reg)

# r = "usa"
# sum(qₑₜ[:,r] .* pₑ[:,r]) - y[r]

# i="wheat"
# r="usa"
# sum(qₑ[:, i, r] .* pₑ[:,r]) - qₚ[i,r] * pₚ[i]

fix(pₚ["wheat"], 10; force = true)
fix(qₑₜ["labor","usa"], 4; force = true)
fix(qₑₜ["capital","usa"], 2; force = true)
fix(qₑₜ["labor","canada"], 1; force = true)
fix(qₑₜ["capital","canada"], 3; force = true)
fix(qₑₜ["labor","australia"], 1; force = true)
fix(qₑₜ["capital","australia"], 1; force = true)
#fix(qₚ["rice","usa"], 0.809; force = true)

# fix(pₚ["rice"],	14.84176147; force = true)
# fix(pₚ["wheat"],	15.17521474; force = true)
# fix(pₚ["corn"],	13.2949744; force = true)

# fix(y["usa"],	42.5349707; force = true)
# fix(y["canada"],	41.32500342; force = true)
# fix(y["australia"],	36.14002588; force = true)

#fix(qₚ["rice","usa"], 0.809;force = true)
#fix(qₚ["rice","canada"], 0.824;force = true)
#fix(qₚ["corn","australia"], 0.340;force = true)

#fix(pₚ["wheat"], 15.17521474;force = true)

optimize!(model)

fix(qₑₜ["capital","australia"], 2; force = true)

optimize!(model)

value.(qₚ)


x = all_variables(model)
cliptable(DataFrame(
    name = name.(x),
    Value = value.(x),
))


value.(qₚ)

# Checks
## All income is spent
value.(y).data .-  transpose(mapslices(sum,repeat(value.(pₚ).data,inner=(1,3)) .* value.(qₚ).data, dims = 1))
## Zero profits
dropdims(mapslices(sum, value.(qₑ).data .* permutedims(repeat(value.(pₑ).data, inner=(1,1,3)),[1,3,2]), dims = 1),dims = (1)) - value.(qₚ).data .* repeat(value.(pₚ).data,inner=(1,3))
## Market clears



x = all_variables(model)
cliptable(DataFrame(
    name = name.(x),
    Value = value.(x),
))


x= all_constraints(model; include_variable_in_set_constraints = true)
cliptable(DataFrame(
    name = x,
))






sum(value.(qₚ)[:,"canada"] .* value.(pₚ) )
value.(y)

r="canada"
demand(value.(pₚ), value.(y[r]), αₚ[:,r])

clipboard(value.(pₚ))
clipboard(value.(qₚ)[:,"canada"])



value.(qₑ)
value.(pₑ)
value.(qₚ)
value.(pₚ)

@constraint(model,    [i = com, r =reg], sum(qₑ[:, i, r] .* pₑ[:,r]) == qₚ[i,r] * pₚ[i] # zero profits
)

optimize!(model)


value.(y)
value.(pₑ)
value.(qₚ)

unfix(y)
fix(pₚ["wheat"], 1; force=true)

optimize!(model)

unfix(pₚ["wheat"])
JuMP.set_lower_bound(pₚ["wheat"], 0.01)
fix(qₚ["wheat"], 0.4)

optimize!(model)


value.(qₑₜ) .* value.(pₑ)
value(y)
value.(pₚ)
value.(qₚ)
value.(qₑ)