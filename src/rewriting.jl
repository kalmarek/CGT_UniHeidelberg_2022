import Base.Order: lt, Ordering

export rewrite!, rewrite, LenLex, lt

const Rule{W} = Pair{W, W} where W <: AbstractWord

"""
    rewrite!(v::AbstractWord, w::AbstractWord, rule::Rule)
Rewrite word `w` storing the result in `v` by using a single rewriting `rule`.
"""
function rewrite!(v::AbstractWord, w::AbstractWord, rule::Rule)
    v = resize!(v, 0)
    lhs, rhs = rule
    while !isone(w)
        push!(v, popfirst!(w))
        if issuffix(lhs, v)
            prepend!(w, rhs)
            resize!(v, length(v) - length(lhs))
        end
    end
    return v
end

"""
    rewrite!(v::AbstractWord, w::AbstractWord, rws::RewritingSystem)
Rewrite word `w` storing the result in `v` by left using rewriting rules of
rewriting system `rws`. See [Sims, p.66]
"""
function rewrite!(
    v::AbstractWord,
    w::AbstractWord,
    rws #::RewritingSystem,
)
    v = resize!(v, 0)
    while !isone(w)
        push!(v, popfirst!(w))
        for (lhs, rhs) in rws # in the future: rwrules(rws)
            if issuffix(lhs, v)
                prepend!(w, rhs)
                resize!(v, length(v) - length(lhs))
                break
            end
        end
    end
    return v
end

function rewrite(
    w::W,
    rewriting,
    vbuffer = one(w),
	# a queue with pre-allocated space at the end:
	# vbuffer = BufferWord{eltype(w)}(0, length(w)), 
    wbuffer = similar(w), 
	# a queue with pre-allocated space at the begining:
	# wbuffer = BufferWord{eltype(w)}(length(w), 0),
) where W
	# copy the content of w to wbuffer, possibly adjuting its size
    store!(wbuffer, w) 
	# do the destructive rewriting from `wbuffer` to `vbuffer`
    rewrite!(vbuffer, wbuffer, rewriting)
    return W(vbuffer) # return the result of the same type as w
end

abstract type WordOrdering <: Ordering end

"""
    struct LenLex{T} <: WordOrdering

`LenLex` order compares words first by length and then by lexicographic (left-to-right) order.
"""
struct LenLex{T} <: WordOrdering
    A::Alphabet{T}
    reordering::Vector{Int}

    function LenLex(A::Alphabet{T}, ord::Vector{T}) where T
        reord = Vector{Int}(undef, length(ord))
        for i in 1:length(ord)
            reord[A[ord[i]]] = i
        end
        new{T}(A, reord)
    end
end

function lt(o::LenLex, lp::Integer, lq::Integer)
    return o.reordering[lp] < o.reordering[lq]
end

function lt(o::LenLex, p::AbstractWord, q::AbstractWord)
    if length(p) == length(q)
        for (lp, lq) in zip(p, q)
            # lp < lq && return true
            lt(o, lp, lq) && return true
            lt(o, lq, lp) && return false
        end
        return false # i.e. p == q
    else
        return length(p) < length(q)
    end
end