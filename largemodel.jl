using JuMP, HiGHS, Ipopt, NamedArrays, ClipData, Tables, DataFrames, Printf

include("demand_les.jl")
include("factordemand_ces.jl")

nreg = 10
ncom = 7
nfac = 5 

com = "com" .* lpad.(1:ncom, 2, '0')
fac = "fac" .* lpad.(1:nfac, 2, '0')
reg = "reg" .* lpad.(1:nreg, 2, '0')


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

αₚ₊ = zeros(nreg, ncom)
for r in 1:nreg
    αₚ₊[r, 1] = r/nreg * .6
    for c in 2:ncom
        αₚ₊[r,c] = (1-αₚ₊[r, 1])/(ncom-1)
    end
end
αₚ=JuMP.Containers.DenseAxisArray(αₚ₊, reg, com)

γₚ₊ = zeros(nreg, ncom)
for r in 1:nreg
    for c in 1:ncom
        γₚ₊[r,c] = r/nreg * c/ncom *0.5
    end
end
γₚ=JuMP.Containers.DenseAxisArray(γₚ₊, reg, com)

αₒ₊ = zeros(nreg, nfac)
for r in 1:nreg
    αₒ₊[r, 1] = r/nreg * .4
    for f in 2:nfac
        αₒ₊[r,f] = (1-αₒ₊[r, 1])/(nfac-1)
    end
end
αₒ=JuMP.Containers.DenseAxisArray(αₒ₊, reg, fac)

#αₚ=JuMP.Containers.DenseAxisArray([0.2 0.5 0.3; 0.4 0.5 0.1;0.4 0.5 0.1], reg, com)
#γₚ=JuMP.Containers.DenseAxisArray([0.4 0.2 0.1; 0.3 0.2 0.1;0.1 0.2 0.3], reg, com)
#αₒ=JuMP.Containers.DenseAxisArray([0.4 0.6; 0.5 0.5; 0.7 0.3],   reg, fac)
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

fix(pₚ["com01"], 10; force = true)

for f in 1:nfac
    for r in 1:nreg
        fix(qₑₜ[fac[f],reg[r]], f/2 + r/3; force = true)       
    end
end
# fix(pₚ["wheat"], 10; force = true)
# fix(qₑₜ["labor","usa"], 4; force = true)
# fix(qₑₜ["capital","usa"], 2; force = true)
# fix(qₑₜ["labor","canada"], 1; force = true)
# fix(qₑₜ["capital","canada"], 3; force = true)
# fix(qₑₜ["labor","australia"], 1; force = true)
# fix(qₑₜ["capital","australia"], 1; force = true)

optimize!(model)

orig = value.(qₚ).data
αₚ
γₚ

for f in 1:nfac
    for r in 1:nreg
        fix(qₑₜ[fac[f],reg[r]], f/2 + r/3 +0.1; force = true)       
    end
end
optimize!(model)

new1 = value.(qₚ).data

for f in 1:nfac
    for r in 1:nreg
        fix(qₑₜ[fac[f],reg[r]], f/2 + r/3; force = true)       
    end
end
optimize!(model)
new2 = value.(qₚ).data

orig[1,:]
new1[1,:]
new2[1,:]

# fix(qₑₜ["capital","australia"], 2; force = true)

# optimize!(model)

# value.(qₚ)