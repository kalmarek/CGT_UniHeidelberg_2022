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
function transversal(x::Any, S::AbstractVector{<:GroupElement}, action = ^)
    @assert !isempty(S) # groups need generators
    Δ = [x]

    T = Dict(x => one(first(S)))
    for δ in Δ
        for s in S
            γ = action(δ, s)
            if γ ∉ keys(T)
                push!(Δ, γ)
                T[γ] = T[δ] * s
            end
        end
    end

    return Δ, T
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
function schreier(x, S::AbstractVector{<:GroupElement}, action = ^)
    @assert !isempty(S) # groups need generators
    Δ = [x]
    Sch = Dict(x => one(first(S)))
    for δ in Δ
        for (i, s) in pairs(S)
            γ = action(δ, s)
            if γ ∉ keys(Sch)
                push!(Δ, γ)
                Sch[γ] = s
            end
        end
    end

    return Δ, Sch
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
function representative(y, Δ, Sch, action = ^)
    current = y
    g = one(Sch[y])

    while (gen = Sch[current]) != one(Sch[current])
        current = action(current, inv(gen))
        g = gen * g
    end

    return g
end
