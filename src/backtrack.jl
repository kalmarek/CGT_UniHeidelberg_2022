function backtrack!(L::AbstractVector{<:AbstractPermutation}, sc::StabilizerChain, g=gens(sc, 1)[1]::AbstractPermutation, d=1::Integer)
    t = transversal(sc, d)

    for δ in t
        x = g*t[δ]
        if d == depth(sc)
            push!(L, x)
        else
            backtrack!(L, sc, x, d+1)
        end
    end
    return L
end

function backtrack_step(sc::StabilizerChain{T,P}, stack) where {T,P}
    isempty(stack) && return [], []

    L = P[]

    g, d = pop!(stack)
    t = transversal(sc, d)

    for δ in t
        if d == depth(sc)
            push!(L, g*t[δ])
        else
            push!(stack, [g*t[δ], d+1])
        end
    end
    
    return L, stack
end

backtrack_iter(sc::StabilizerChain) = backtrack_iter(sc, [[gens(sc, 1)[1], 1]])

function backtrack_iter(sc::StabilizerChain{T,P}, stack) where {T,P}
    L = P[]

    while isempty(L) && !isempty(stack)
        L, stack = backtrack_step(sc, stack)
    end

    return L, stack
end
