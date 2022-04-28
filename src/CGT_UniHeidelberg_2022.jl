module CGT_UniHeidelberg_2022

abstract type GroupElement end

include("orbits.jl")
include("AbstractPermutations.jl")
using .AbstractPermutations

include("permutations.jl")

end # of module CGT_UniHeidelberg_2022
