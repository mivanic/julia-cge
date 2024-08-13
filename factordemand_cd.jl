function factordemand(output, price, outputprice, α, β)
   outputprice .*  α ./ price  .* output ./β
end