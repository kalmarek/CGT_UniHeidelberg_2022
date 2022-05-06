using Test
using CGT_UniHeidelberg_2022

@testset verbose=true "CGT" begin
   include("permutations.jl")
   include("transversals.jl")
end
