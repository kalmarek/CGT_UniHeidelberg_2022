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