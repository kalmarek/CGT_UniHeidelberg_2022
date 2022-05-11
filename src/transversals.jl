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
schreier(x, s::GroupElement, action=^) = schreier(x, [s], action)

function schreier(x, S::AbstractVector{<:GroupElement}, action=^)
    @assert !isempty(S)
    Δ_vec = [x]
    Δ = Set(Δ_vec)
    Sch = Dict{typeof(x), eltype(S)}()

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
    @assert !isempty(Δ)
    current_point = y
    # XXX: this only works if `Sch` is non-empty
    g = one(first(values(Sch)))

    # If `y = xᵍ` for `g` in `Stab_G(x)`, then `schreier()` places `y`
    # in the orbit, but not in `Sch`. Therefore we cannot distinguish
    # from `Sch` alone if `y` is _not_ in the orbit, or merely the root
    # of the Schreier tree. To disambiguate, the element `x` can be
    # specified; the full orbit Δ is not required.
    x = first(Δ)

    # If `y` is not x, and not in the orbit, the function will terminate
    # with `KeyError`. To make this a bit more clear, add an assert.
    if y ≠ x
        @assert haskey(Sch, y) "Element y is not in the orbit of x"
    end

    while current_point ≠ x
        # s sends some previous point on the orbit to the current one
        s = Sch[current_point]
        # shift current one to the previous one
        current_point = current_point^inv(s)
        # accumulate the change
        g = s * g
        # observe: g sends current_point to y.
    end
    return g
end
