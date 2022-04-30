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

