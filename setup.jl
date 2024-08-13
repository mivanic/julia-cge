using JuMP, HiGHS, Ipopt, NamedArrays

function demand(p, y, α)
   α .* y ./ p
end

com = ["rice", "wheat", "corn"]

model = JuMP.Model(Ipopt.Optimizer)

@variables(model, begin
    quantity[i=com]
    price[i=com]
    val[i=com]
end
)

y=10
α = [.3,.2,.3]


@constraint(model, demand(price, y, α) .==  quantity)
@constraint(model, price .* quantity .== val)

fix(price["wheat"], 4)
optimize!(model)

value.(price)
value.(quantity)

