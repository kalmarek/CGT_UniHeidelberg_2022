export transversal, transversal_factored, schreier, representative

"""
    transversal(x, S::AbstractVector{<:GroupElement}[, action=^])
Compute the orbit `Δ` and a transversal `T` of `x ∈ Ω` under the action of `G = ⟨S⟩`.

Transversal is a set of representatives of left cosets `Stab_G(x)\\G` satisfying

    x^T[γ] = γ

for every `γ ∈ Δ`.

It is assumed that elements `G` act on `Ω` _on the right_ via `action(x, g)`.

### Input
 * `x` - point in set `Ω`,
 * `S` - finite generating set for `G = ⟨S⟩`,
 * `action` - function defining an action of `G`. Defaults to `^`.
### Output
 * `Δ::Vector` - the orbit of `x` under the action of `G`,
 * `T::Dict` - a transversal.
"""
transversal(x, s::GroupElement, action=^) = transversal(x, [s], action)

function transversal(x, S::AbstractVector{<:GroupElement}, action=^)
    @assert !isempty(S)
    Δ_vec = [x]
    Δ = Set(Δ_vec)

    # The definition of the unit element uses that `S` is not empty, and
    # that `one()` is defined for `GroupElement`.
    e = one(first(S))
    T = Dict(x => e)
    # T = Dict{typeof(x), eltype(S)}(); T[x] = e

    for δ in Δ_vec
        for s in S
            γ = action(δ, s)
            if γ ∉ Δ
                push!(Δ, γ)
                push!(Δ_vec, γ)
                T[γ] = T[δ]*s
            end
        end
    end
    return Δ_vec, T
end

"""
    This function stores factors of elements in the transversal, instead
    of elements themselves. Whenever we ask for a coset representative,
    this means we need to perform `length(T[γ])` multiplications to
    recover it.

    If we only want to store the indices of the generators, instead of
    the generators themselves, `T[γ]` is an `Int[]` array, and we loop
    over `1:length(S)` instead of `S` itself. The identity can then be
    represented either be left out (by initializing `T` as an empty
    dictionary), or a special value; in the former case, array
    concatenation `T[γ] = [T[δ]; s]` will contain one element less.
"""
transversal_factored(x, s::GroupElement, action=^) = transversal_factored(x, [s], action)

function transversal_factored(x, S::AbstractVector{<:GroupElement}, action=^)
    @assert !isempty(S)
    Δ_vec = [x]
    Δ = Set(Δ_vec)

    # The definition of the unit element uses that `S` is not empty, and
    # that `one()` is defined for `GroupElement`.
    e = one(first(S))
    T = Dict(x => [e])

    for δ in Δ_vec
        for s in S
            γ = action(δ, s)
            if γ ∉ Δ
                push!(Δ, γ)
                push!(Δ_vec, γ)
                T[γ] = [T[δ]; s]
            end
        end
    end
    return Δ_vec, T
end

"""
    schreier(x, S::AbstractVector{<:GroupElement}[, action=^])
Compute the orbit and a Schreier tree of `x ∈ Ω` under the action of `G = ⟨S⟩`.

Schreier tree is a compressed transversal satisfying

    Sch[γˢ] == s

for every `γ ∈ Δ` and every `s ∈ S`. A coset representative for `γ` can be obtained
from `Sch` by calling [`representative(γ, Δ, Sch, action)`](@ref).

It is assumed that elements `G` act on `Ω` _on the right_ via `action(x, g)`.

### Input
 * `x` - point in set `Ω`,
 * `S` - finite generating set for `G = ⟨S⟩`,
 * `action` - function defining an action of `G`. Defaults to `^`.
### Output
 * `Δ::Vector` - the orbit of `x` under the action of `G`, as a `Vector`,
 * `Sch::Dict` - a Schreier tree.
"""
function schreier(x, S::AbstractVector{<:GroupElement}, action=^)
    @assert !isempty(S)
    Δ_vec = [x]
    Δ = Set(Δ_vec)

    # The generating set `S` could include the neutral element `e`, so 
    # `S[Sch[γˢ]] == s` should also be defined in this case.
    # To sidestep the issue, initialize `Sch` as an empty dictionary.
    Sch = Dict{typeof(x), Int64}()

    for δ in Δ_vec
        for s in S
            γ = action(δ, s)
            if γ ∉ Δ
                push!(Δ, γ)
                push!(Δ_vec, γ)
                Sch[γ] = s
            end
        end
    end
    return Δ_vec, Sch
end

"""
    representative(y, Δ, Sch[, action=^])
Compute a representative `g` of left-coset `Stab_G(x)g` corresponding to point `y ∈ Δ` in the orbit of `x`.

## Input
* `y` - a point in `Δ`,
* `Δ` - the orbit of `x` under the action of `G`,
* `Sch` - a Schreier tree for `Δ` and `S`.
* `action` - function defining an action of `G`. Defaults to `^`.
## Output
* `g ∈ G` such that `xᵍ = y`.
"""
function representative(y, Δ, Sch, action=^)
    @assert !isempty(S)
    @assert !isempty(Δ)
    current_point = y
    g = one(first(S))

    # If `y = xᵍ` for `g` in `Stab_G(x)`, then `schreier()` places `y`
    # in the orbit, but not in `Sch`. Therefore we cannot distinguish
    # from `Sch` alone if `y` is _not_ in the orbit, or merely the root
    # of the Schreier tree. To disambiguate, the element `x` can be
    # specified; the full orbit Δ is not required.
    x = Δ[1]

    # If `y` is not x, and not in the orbit, the function will terminate
    # with `KeyError`. To make this a bit more clear, add an assert.
    if y ≠ x
        @assert haskey(Sch, y) "Element y is not in the orbit of x"
    end

    while current_point ≠ x
        s = Sch[current_point]            # s sends some previous point on the orbit to the current one
        current_point = current_point^inv(s) # shift current one to the previous one
        g = s * g                            # accumulate the change
        # observe: g sends current_point to y.
    end
    return g
end
