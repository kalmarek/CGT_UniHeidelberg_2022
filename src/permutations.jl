#module Permutation
# included from CGT_UniHeidelberg_2022.jl

#export Permutation, CyclicPermutation

""" Exercise #1
`Permutation` as implementation of abstract type `AbstractPermutation`.
"""
struct Permutation <: AbstractPermutation
    images::Vector{Int}

    function Permutation(v::AbstractVector{<:Integer}, check=true)
        if check
            @assert sort(v) == 1:length(v) "Image vector doesn't define a permutation"
        end
        return new(v) # calls convert(Vector{Int}, v)
    end
end

function (σ::Permutation)(n::Integer)
    if n > length(σ.images)
        return convert(Int, n)
    else
        return σ.images[n]
    end
end

function degree(σ::Permutation)
    n = length(σ.images)
    for i in n:-1:1  # reverse in steps by -1
        if σ.images[i] != i
            return i
        end
    end
    return 1
end
export degree


""" Exercise #1
Create struct `CyclePermutation <: AbstractPermutation` that stores
`cycles::Vector{Vector{Int}}` in its fields.

* Implement the `AbstractPermutation` interface i.e. degree and obtaining
  the image of `i::Integer` under such permutation.
* Verify the correctness of multiplication, inversion etc. by writing
  appropriate begin ... end block with `@asserts`.
* What happens if we multiply `CyclePermutation` and `Permutation` together?
  Can you find where does this behaviour come from?
"""
struct CyclePermutation <: AbstractPermutation
    # Store the cyclic decomposition of the permutation.
    cycles::Vector{Vector{Int}}

    # Since we want to compute σ(i) with O(1) complexity, the simplest
    # way is to also store the vector of images. Computing σ(i) from a
    # cyclic decomposition (with disjoint cycles) would require finding
    # the cycle which contains the index i. Cycles are not necessarily
    # sorted, so this would result in O(N) complexity.
    images::Vector{Int}

    function Permutation(v::AbstractVector{<:Integer}, check=true)
        # Construct temporary Permutation for cycle decomposition
        σ = Permutation(v, check)
        c = cycle_decomposition(σ)

        # We assume that `cycle_decomposition()` returns a product of
        # disjoint cycles. The implementation in `AbstractPermutations`
        # achieves this by computing orbits (which are either identical
        # or disjoint).
        if check
            σ_cat = Int[]
            for c ∈ cycles
                σ_cat = vcat(σ_cat, c)
            end
            @assert allunique(σ_cat) "σ is not a decomposition in disjoint cycles"
        end
        new(c, σ) # inner constructor method
    end
end

# Since σ stores both the images and the cycles (see comment above), the
# implementation equals the one for σ::Permutation.
# XXX: CyclePermutation is not a subtype of Permutation. Can the
# implementation for `σ::Permutation` still be assigned here?
# If not, this could be a "detail" called by (σ::Permutation)(n) and
# (σ::CyclePermutation)(n).
function (σ::CyclePermutation)(n::Integer)
    if n > length(σ.images)
        return convert(Int, n)
    else
        return σ.images[n]
    end
end

function degree(σ::CyclePermutation)
    # Cycles of length k>=2 have no elements mapped to themselves;
    # it then suffices to take the maximum element in each cycle,
    # and again take the maximum over these cycles for the degree.
    deg = 1
    for c ∈ σ.cycles
        if max(c) > deg
            deg = max(c)
        end
    end
    return deg
end
export degree

# `cycle_decomposition()` can be specialized for `CyclePermutation`, in
# the sense that the operation becomes trivial (the decomposition is
# already part of the object). This avoids redundant computations when
# serializing the permutation (`Base.show()`).
function cycle_decomposition(σ::CyclePermutation)
    return σ.cycles
end
export cycle_decomposition

# end # of Permutation
