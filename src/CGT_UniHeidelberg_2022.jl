module CGT_UniHeidelberg_2022

abstract type GroupElement end

export AbstractPermutations,
    Permutation,
    degree,
    cycle_decomposition,
    @perm_str


include("orbits.jl")
include("AbstractPermutations.jl")
using .AbstractPermutations

include("permutations.jl")
include("permutations_02.jl")
include("schreier_sims.jl")
include("rand.jl")
include("perm_groups.jl")
include("backtrack.jl")

end # of module CGT_UniHeidelberg_2022
