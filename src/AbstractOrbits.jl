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
"""
function orbit_producer(x::AbstractVector, S::AbstractVector{<:GroupElement}, Vin::Dict, Vfunc, action=^)
    @assert !isempty(S)

    # We iterate over both a set and an array because sets are
    # implicitly sorted on insertion, while arrays preserve order.
    Δ_vec = x
    Δ = Set(Δ_vec)

    for δ ∈ Δ_vec
        for s ∈ S
            γ = action(δ, s)
            if γ ∉ Δ
                # We push to arrays inside the function so that the loop
                # can continue over the whole orbit.
                push!(Δ, γ)
                push!(Δ_vec, γ)
                # Perform additional operations on δ,s,γ and Vin
                # dictionary, typically Vin[γ] = f(δ, s)
                Vfunc(Vin, δ, s, γ)
            end
        end
    end
    return Δ_vec
end

# Specialization for `orbit_plain`. This might result in an additional
# copy of the orbit, as it is stored in both producer the consumer.
struct Orbit <: AbstractOrbit
    Δ::AbstractVector

    # `Orbit` can be defined on an array of points, returning a union
    # of orbits for each point.
    function Orbit(x::AbstractVector, S::AbstractVector{<:GroupElement}, action=^)
        Δ_tmp = Dict{}()
        Δ_fnc = (Vin, δ, s, γ) -> nothing

        return new(orbit_producer(x, S, Δ_tmp, Δ_fnc, action))        
    end

    Orbit(x, S::AbstractVector{<:GroupElement}, action=^) = Orbit([x], S, action)
    Orbit(x, s::GroupElement, action=^) = Orbit(x, [s], action)
end

struct Transversal <: AbstractOrbit
    Δ::AbstractVector
    T::Dict # Dict{typeof(x), eltype(S)}()

    function Transversal(x, S::AbstractVector{<:GroupElement}, action=^)
        T_tmp = Dict(x => one(first(S)))
        T_fnc = (T_tmp, δ, s, γ) -> (T_tmp[γ] = T_tmp[δ]*s)
        Δ_tmp = orbit_producer([x], S, T_tmp, T_fnc, action)

        return new(Δ_tmp, T_tmp)
    end

    Transversal(x, s::GroupElement, action=^) = Transversal(x, [s], action)
end

struct Schreier <: AbstractOrbit
    Δ::AbstractVector
    Sch::Dict # Dict{typeof(x), eltype(S)}()

    function Schreier(x, S::AbstractVector{<:GroupElement}, action=^)
        Sch_tmp = Dict{typeof(x), eltype(S)}()
        Sch_fnc = (Sch_tmp, δ, s, γ) -> (Sch_tmp[γ] = s)
        Δ_tmp = orbit_producer([x], S, Sch_tmp, Sch_fnc, action)

        return new(Δ_tmp, Sch_tmp)
    end

    Schreier(x, s::GroupElement, action=^) = Schreier(x, [s], action)
end

# end # of module AbstractOrbits
