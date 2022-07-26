function elt_from_image(sc::StabilizerChain{T, P}, img::Vector{<:Integer}) where {T, P}
    r = one(first(gens(sc, 1)))

    for i in 1:depth(sc)
        t = transversal(sc, i)
        β = basis(sc, i)
        @assert img[β] ∈ t "impossible image for the given group"
        r = t[img[β]]*r
    end

    return r
end

function decompose(g::AbstractPermutation, G::PermutationGroup)
    sc = stabilizer_chain(G)
    L = []

    for i in 1:depth(sc)
        t = transversal(sc, i)
        β = basis(sc, i)
        @assert g(β) ∈ t "element not in group"
        push!(L, t[g(β)])
    end

    return L
end

function pseudorand_init(S::Vector{<:AbstractPermutation})
    L = copy(S)
    while length(L) < 11
        push!(L, S[length(L)%length(S) + 1])
    end

    s = one(first(S))

    for _ in 1:50
        L, s = pseudorand(L, s)
    end
    return L
end

function pseudorand(L::Vector{<:AbstractPermutation}, s::AbstractPermutation = one(first(L)))
    @assert length(L) > 1 "list too short"
    i, j = 1, 1
    while i == j
        i, j = rand(collect(1:length(L)), 2)
    end
    lj = rand(Bool) ? L[j] : inv(L[j])

    if rand(Bool)
        L[i] = L[i] * lj
        s = s * lj
    else
        L[i] = lj * L[i]
        s = lj * s
    end
    return L, s
end

function Base.rand(sc::StabilizerChain)
    b = basis(sc)
    img1 = [rand(collect(transversal(sc, i))) for i in 1:depth(sc)]
    img = collect(1:maximum(img1))

    for (i, j) in pairs(b)
        img[j] = img1[i]
        img[img1[i]] = j
    end

    return elt_from_image(sc, img)
end

# makeshift confidence estimate to compare Base.rand and pseudorand
# result: pseudorand is a tiny bit faster, but Base.rand seems to produce better randomness

# function get_confidence(S::AbstractVector{<:Permutation})
#     sc = schreier_sims(S)
#     V = []
#     n_reps = 100000
#     L = pseudorand_init(S)

#     for _ in 1:n_reps
#         L, s = pseudorand(L)
#         push!(V, s)
#         #push!(V, rand(sc))
#     end

#     C = [(i, count(==(i), V)) for i in unique(V)]
#     #@test length(C) == group_order # all elements were hit
#     pct = []
#     group_order = order(sc)
#     for i = 1:length(C)
#         push!(pct, C[i][2] * group_order / n_reps)
#     end

#     return minimum(pct), maximum(pct)
# end

# using Printf

# function get_confidence_overall(SPG)
#     pct = []
#     for group_order in 2:30
#         for S in SPG[group_order]
#             push!(pct, get_confidence(S))
#         end
#     end

#     mini, maxi = 1, 1
#     for (a, b) in pct
#         mini = min(mini, a)
#         maxi = max(maxi, b)
#     end

#     return mini, maxi
# end

# function printc(a)
#     @printf "Min: %.5f\n" a[1]
#     @printf "Max: %.5f" a[2]
# end
