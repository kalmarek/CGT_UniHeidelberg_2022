export CyclePermutation2, degree, cycle_decomposition

""" Implementation of `CyclePermutation` which does not assume knowledge
of `Permutation`, and stores data exclusively in `cycles`.
"""
struct CyclePermutation2 <: AbstractPermutation
    # Store the cyclic decomposition of the permutation
    cycles::Vector{Vector{Int}}

    function CyclePermutation2(v::AbstractVector{<:Integer}, check=true)
        cycles = AbstractPermutations.cycle_decomposition(v, check)
        # Check that we have a product of disjoint cycles.
        if check
            σ_cat = Int[]
            for c ∈ cycles
                append!(σ_cat, c)
            end
            @assert allunique(σ_cat) "σ is not a decomposition in disjoint cycles"
        end
        new(cycles) # inner constructor method
    end
end

function degree(σ::CyclePermutation2)
    # Cycles of length k>=2 have no elements mapped to themselves;
    # it then suffices to take the maximum element in each cycle,
    # and again take the maximum over these cycles for the degree.
    deg = 1
    if length(σ.cycles) >= 1
        deg = mapreduce(maximum, max, σ.cycles; init=deg)
    end
    return deg
end

# Taken from https://github.com/kalmarek/CGT_UniHeidelberg_2022/pull/2/files#r862717462
function (σ::CyclePermutation2)(n::Integer)
    n > degree(σ) && return convert(Int, n)
    for cycle in σ.cycles
        idx = findfirst(==(n), cycle)
        isnothing(idx) && continue
        next_idx = ifelse(idx < length(cycle), idx+1, 1)
        return cycle[next_idx]
    end
    return convert(Int, n) # e.g. when we decide later not to store cycles of length 1
end

# optional
function AbstractPermutations.cycle_decomposition(σ::CyclePermutation2)
    return σ.cycles
end

# Ad-hoc implementation of cycle_decomposition() for vectors which
# follows indices until a cycle is encountered.
function AbstractPermutations.cycle_decomposition(images::AbstractVector{<:Integer}, check=true)
    # Include the check here because we are operating directly on a
    # vector of images, instead of a permutation.
    if check
        @assert sort(images) == 1:length(images) "Image vector doesn't define a permutation"
    end
    n = length(images)
    visited = falses(n)
    cycles = []

    for i ∈ 1:n # loop over the indices (permutation domain)
        if visited[i]
            continue
        end
        i_cycle, cycle = i, Int[]
        visited[i_cycle] = true
        push!(cycle, i_cycle)

        for _ ∈ 2:n # no cycle can be longer than n
            if images[i_cycle] == i
                break
            end
            i_cycle = images[i_cycle]
            visited[i_cycle] = true
            push!(cycle, i_cycle)
        end

        # Since we are looping over the length of the images, instead of
        # over the degree, it is possible to have (several) cycles of
        # length 1 (e.g. [1], [2], [3], ...). We could either accept
        # that the identity has empty cycles, or only keep [1] as [2],
        # ... are redundant.
        if length(cycle) >= 2 || i == 1
            push!(cycles, copy(cycle))
        end
    end
    return cycles
end

