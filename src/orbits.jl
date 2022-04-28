"""
    orbit_plain(x, S[, action=^])
Compute the orbit of `x` under the action of a group `G` generated by set `S`.

It is assumed that elements `g ∈ G` act on `x` _on the right_ via `action(x, g)`.

### Input
 * `x` - point in a set `Ω`
 * `S` - finite generating set for `G = ⟨S⟩`.
 * `action` - action of `G` on `Ω` from the right, defaulting to `^`.
### Output
 * `{xᵍ | g ∈ G}` - the orbit of `x` under the action of `G`, returned as a `Vector`.
"""
orbit_plain(x, S::AbstractVector{<:GroupElement}, action=^) =
    orbit_plain!([x], S, action)

function orbit_plain!(x::AbstractVector, S::AbstractVector{<:GroupElement}, action=^)
    @assert !isempty(S) # groups need generators
    Δ_vec = x
    Δ = Set(Δ_vec)
    for δ in Δ
        for s in S
            γ = action(δ, s)
            if γ ∉ Δ
                push!(Δ, γ)
                push!(Δ_vec, γ)
            end
        end
    end
    return Δ_vec
end

orbit_plain(x, s::GroupElement, action=^) = orbit_plain!([x], s, action)

function orbit_plain!(x::AbstractVector, s::GroupElement, action=^)
    Δ_vec = copy(x)
    Δ = Set(Δ_vec)
    for δ in Δ
        γ = action(δ, s)
        if γ ∉ Δ
            push!(Δ, γ)
            push!(Δ_vec, γ)
        end
    end
    return Δ_vec
end
