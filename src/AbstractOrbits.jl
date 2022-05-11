# module AbstractOrbits

import ..GroupElement

export AbstractOrbit, Orbit, Transversal, Schreier

"""
`orbit_plain`, `transversal` and `schreier` have the common property
that we iterate over a vector of values δ (initialized with a starting
value) and a vector of generators `s` (of type `GroupElement`). Then, we
apply `action(δ, s)` and get some γ in the orbit. This element is then
processed exactly once, checking for uniqueness.

Compared to `orbit_plain`, `transversal` and `schreier` proceed in the
same way but store some extra fields (namely, a `Dict`). As such, the
implementation here is based on this common denominator, but allows to
store and modify additional fields.

There is one striking difference: `orbit_plain` is defined on a vector
of elements, and returns a union of orbits in this case.  `transversal`
and `schreier` are only defined on a single element.  In this module we
assume the orbit of a single element.

Summarized, the interface can be defined as follows:

1. `AbstractOrbit` can be constructed from an element x, a (non-empty)
   set of generators S, and a group action (defaulting to ^).
2. `AbstractOrbit` contains a vector Δ representing the orbit of x
   under the group action, with unique elements.
"""
abstract type AbstractOrbit end

"""
Generalized orbit function which takes an input dictionary `Vin` and a
function f(δ,s,γ) to populate it. This is used in `Transversal` and
`Schreier`, and these structures only define `Vin` and f accordingly.

The orbit Δ is taken an input argument so that both the orbit and the
dictionary V can be initialized in the same place (the caller), reducing
the odds of inconsistencies.
"""
function orbit_producer(Δ::AbstractVector, S::AbstractVector{<:GroupElement},
                        V::Dict, Vfunc, action=^)
    @assert !isempty(S)
    for δ ∈ Δ
        for s ∈ S
            γ = action(δ, s)
            if γ ∉ keys(V)
                push!(Δ, γ)
                push!(V, γ => Vfunc(V, δ, s))
            end
        end
    end
    return # Δ, V
end

struct Orbit <: AbstractOrbit
    Δ::AbstractVector

    function Orbit(x::AbstractVector, S::AbstractVector{<:GroupElement}, action=^)
        Δ_vec = x
        Δ_set = Dict{eltype(x), Nothing}() # ad-hoc Set
        noop = (V_tmp, δ, s) -> nothing

        # `Orbit` can be defined on an array of points, returning a union of
        # orbits for each point. Create a dictionary entry for each point.
        for δ ∈ Δ_vec
            push!(Δ_set, δ => nothing)
        end

        orbit_producer(Δ_vec, S, Δ_set, noop, action) # populates Δ_vec, Δ_set
        return new(Δ_vec)
    end

    Orbit(x, S::AbstractVector{<:GroupElement}, action=^) = Orbit([x], S, action)
    Orbit(x, s::GroupElement, action=^) = Orbit(x, [s], action)
end

struct Transversal <: AbstractOrbit
    Δ::AbstractVector
    T::Dict # Dict{typeof(x), eltype(S)}()

    function Transversal(x, S::AbstractVector{<:GroupElement}, action=^)
        Δ_vec = [x]
        T_tmp = Dict(x => one(first(S)))
        T_fnc = (T_tmp, δ, s) -> T_tmp[δ]*s

        orbit_producer(Δ_vec, S, T_tmp, T_fnc, action) # populates Δ, T
        return new(Δ_vec, T_tmp)
    end

    Transversal(x, s::GroupElement, action=^) = Transversal(x, [s], action)
end

struct Schreier <: AbstractOrbit
    Δ::AbstractVector
    Sch::Dict # Dict{typeof(x), eltype(S)}()

    function Schreier(x, S::AbstractVector{<:GroupElement}, action=^)
        Δ_vec = [x]
        Sch_tmp = Dict{typeof(x), eltype(S)}(x => one(first(S)))
        Sch_fnc = (Sch_tmp, δ, s) -> s

        orbit_producer(Δ_vec, S, Sch_tmp, Sch_fnc, action) # populates Δ, Sch
        return new(Δ_vec, Sch_tmp)
    end

    Schreier(x, s::GroupElement, action=^) = Schreier(x, [s], action)
end

# end # of module AbstractOrbits
