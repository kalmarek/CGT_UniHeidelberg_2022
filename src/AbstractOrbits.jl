# module AbstractOrbits

import ..GroupElement

export AbstractOrbit, Orbit, Transversal, Schreier

"""
    `orbit_plain`, `transversal` and `schreier` have the common property
    that we iterate over a vector of values δ (initialized with a
    starting value) and a vector of generators `s` (of type
    `GroupElement`). Then, we apply `action(δ, s)` and get some γ in the
    orbit. This element is then processed exactly once, checking for
    uniqueness.

    Compared to `orbit_plain`, `transversal` and `schreier` proceed in
    the same way but store some extra fields (namely, a `Dict`). As
    such, the implementation here is based on this common denominator,
    but allows to store and modify additional fields.

    There is one striking difference: `orbit_plain` is defined on a
    vector of elements, and returns a union of orbits in this case.
    `transversal` and `schreier` are only defined on a single element.
    In this module we assume the orbit of a single element.

    The implementation is done by passing functions and their source
    (dictionaries) to a generalized orbit function.
"""
abstract type AbstractOrbit end

# Parametrized producer which will be specialized later in `Orbit`,
# `Transversal` and `Schreier` structs.
function orbit_producer(x, S::AbstractVector{<:GroupElement}, action=^, Vin=nothing, Vfunc=nothing)
    @assert !isempty(S)
    if isnothing(Vfunc)
        Vfunc = (Vin, δ, s, γ) -> nothing
    end

    # We iterate over both a set and an array because sets are
    # implicitly sorted on insertion, while arrays preserve order.
    Δ_vec = [x]
    Δ = Set(Δ_vec)

    for δ ∈ Δ_vec
        for s ∈ S
            γ = action(δ, s)
            if γ ∉ Δ
                # We push to arrays inside the function so that the loop
                # can continue over the whole orbit.
                push!(Δ, γ)
                push!(Δ_vec, γ)
                # Perform additional operations on δ,s,γ (if defined)
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

    function Orbit(x, S::AbstractVector{<:GroupElement}, action=^)
        return new(orbit_producer(x, S, action))
    end
end

struct Transversal <: AbstractOrbit
    Δ::AbstractVector
    T # Dict{typeof(x), eltype(S)}()

    # XXX: do anonymous functions capture surrounding variables (by reference)?
    function Transversal(x, S::AbstractVector{<:GroupElement}, action=^)
        T_tmp = Dict(x => one(first(S)))
        T_fnc = (T_tmp, δ, s, γ) -> (T_tmp[γ] = T_tmp[δ]*s)
        Δ_tmp = orbit_producer(x, S, action, T_tmp, T_fnc)

        return new(Δ_tmp, T_tmp)
    end
end

struct Schreier <: AbstractOrbit
    Δ::AbstractVector
    Sch # Dict{typeof(x), eltype(S)}()

    # XXX: do anonymous functions capture surrounding variables (by reference)?
    function Schreier(x, S::AbstractVector{<:GroupElement}, action=^)
        Sch_tmp = Dict{typeof(x), eltype(S)}()
        Sch_fnc = (Sch_tmp, δ, s, γ) -> (Sch_tmp[γ] = s)
        Δ_tmp = orbit_producer(x, S, action, Sch_tmp, Sch_fnc)

        return new(Δ_tmp, Sch_tmp)
    end
end

# end # of module AbstractOrbits
