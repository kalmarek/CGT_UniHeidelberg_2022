using Test
using CGT_UniHeidelberg_2022
const CGT = CGT_UniHeidelberg_2022

import CGT_UniHeidelberg_2022:
    Permutation,
    CyclePermutation,
    CyclePermutation2,
    Orbit,
    Transversal

@testset verbose=true "CGT" begin
   include("permutations.jl")
   include("transversals.jl")
end
