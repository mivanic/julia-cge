function factordemand(output, prices,  α, σ, γ)
   c = 1/γ * sum((α .^ σ) .* (prices .^ (1-σ)))^(1/(1-σ))
   (output/γ ) .* (( α .* γ .* c)./(prices)).^σ
end


# output = qₛ["rice","australia"]
# prices = pₑ[:,"australia"]
# α = αₒ["australia",:]
# σ = σₚ
# γ =1

# output = 100
#  prices = [1,1]
#   α = [.4, .6]
#   σ = 3.3
#   γ =2

#   prices .^  (1-σ)

#   c = 1/γ * sum((α .^ σ) .* (prices .^ (1-σ))) ^(1/(1-σ))
  
#   (output/γ ) .* (((1 .- α) .* γ .* c)./(prices)).^σ

