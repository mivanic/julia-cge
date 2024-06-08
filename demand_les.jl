function demand(p, y, α, γ)
    (y-sum(γ .* p)) * α ./ p .+ γ
end