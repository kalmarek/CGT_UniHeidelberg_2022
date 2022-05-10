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
    represented either by an empty array, or a special value; in the
    former case, array concatenation `[T[δ]; s]` will contain one
    element less.
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

    return
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

    return
end
