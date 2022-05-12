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
same way but store some extra information (namely, a `Dict` representing
a transversal or Schreier tree). In the case of `orbit_plain`, we also
use a `Set` for fast element access. Since this is also a `Dict` (with
`nothing` values), we can assume an `AbstractOrbit` includes both a
vector and a dictionary.

There is one striking difference: `orbit_plain` is defined on a vector
of elements, and returns a union of orbits in this case.  `transversal`
and `schreier` are only defined on a single element.  In this module we
assume the orbit of a single element.

Summarized, the interface can be defined as follows:

1. `AbstractOrbit` can be constructed from an element x, a (non-empty)
   set of generators S, and a group action (defaulting to ^).
2. `AbstractOrbit` contains a vector Δ representing the orbit of x
   under the group action, with unique elements.
3. `AbstractOrbit` contains a dictionary T with keys the orbit of x
   under the group action.
"""
abstract type AbstractOrbit end

"""
Operations which are implemented using the `AbstractOrbit` interface.
"""
Base.first(O::AbstractOrbit) = first(O.Δ)
Base.haskey(O::AbstractOrbit) = haskey(O.T)

struct Orbit <: AbstractOrbit
    Δ::AbstractVector
    T::Dict

    function Orbit(x::AbstractVector, S::AbstractVector{<:GroupElement}, action=^)
        Δ_vec = x
        noop = (_, _, _) -> nothing
        # `Orbit` can be defined on an array of points, returning a union of
        # orbits for each point. Create a dictionary entry for each point.
        Δ_set = Dict(δ => noop(nothing, δ, nothing) for δ in Δ_vec)

        _orbit_producer!(Δ_vec, S, Δ_set, noop, action)
        return new(Δ_vec, Δ_set)
    end

    Orbit(x, S::AbstractVector{<:GroupElement}, action=^) = Orbit([x], S, action)
    Orbit(x, s::GroupElement, action=^) = Orbit(x, [s], action)
end

struct Transversal <: AbstractOrbit
    Δ::AbstractVector
    T::Dict # Dict{typeof(x), eltype(S)}()

    function Transversal(x, S::AbstractVector{<:GroupElement}, action=^)
        Δ_vec, T_tmp = transversal(x, S, action)
        return new(Δ_vec, T_tmp)
    end

    Transversal(x, s::GroupElement, action=^) = Transversal(x, [s], action)
end

struct Schreier <: AbstractOrbit
    Δ::AbstractVector
    T::Dict # Dict{typeof(x), eltype(S)}()

    function Schreier(x, S::AbstractVector{<:GroupElement}, action=^)
        Δ_vec, Sch = schreier(x, S, action)
        return new(Δ_vec, Sch)
    end

    Schreier(x, s::GroupElement, action=^) = Schreier(x, [s], action)
end

# end # of module AbstractOrbits
