module CGT_UniHeidelberg_2022

abstract type GroupElement end

include("orbits.jl")
include("AbstractPermutations.jl")
using .AbstractPermutations

include("permutations.jl")
include("permutations_02.jl")
include("transversals.jl")

end # of module CGT_UniHeidelberg_2022
