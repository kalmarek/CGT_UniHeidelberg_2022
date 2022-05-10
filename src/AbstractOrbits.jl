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

    The "common loop" between `orbit_plain`, `transversal` and `schreier`
    can be implemented with some heavy machinery, i.e. coroutines. [1]

    [1] https://docs.julialang.org/en/v1/manual/asynchronous-programming
"""
abstract type AbstractOrbit end

# Parametrized producer which will be specialized later in `Orbit`,
# `Transversal` and `Schreier` structs.
function orbit_producer(c::Channel, x, S::AbstractVector{<:GroupElement}, action)
    @assert !isempty(S)

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
                # The magic happens here!
                put!(c, (δ, s, γ))
            end
        end
    end
end

# Specialization for `orbit_plain`. This might result in an additional
# copy of the orbit, as it is stored in both producer the consumer.
struct Orbit <: AbstractOrbit
    Δ::AbstractVector

    function Orbit(x, S::AbstractVector{<:GroupElement}, action=^)
        producer(c::Channel) = orbit_producer(c, x, S, action)
        Δ_tmp = [x]

        for vals in Channel(producer)
            _, _, γ = vals # δ, s not needed
            push!(Δ_tmp, γ)
        end
        return new(Δ_tmp)
    end
end

struct Transversal <: AbstractOrbit
    Δ::AbstractVector
    T # Dict{typeof(x), eltype(S)}()

    function Transversal(x, S::AbstractVector{<:GroupElement}, action=^)
        producer(c::Channel) = orbit_producer(c, x, S, action)
        Δ_tmp = [x]
        T_tmp = Dict(x => one(first(S)))

        for vals in Channel(producer)
            δ, s, γ = vals
            push!(Δ_tmp, γ)
            T_tmp[γ] = T_tmp[δ]*s
        end
        return new(Δ_tmp, T_tmp)
    end
end

struct Schreier <: AbstractOrbit
    Δ::AbstractVector
    Sch # Dict{typeof(x), Int64}()

    function Schreier(x, S::AbstractVector{<:GroupElement}, action=^)
        producer(c::Channel) = orbit_producer(c, x, S, action)
        Δ_tmp = [x]
        Sch_tmp = Dict{typeof(x), Int64}()

        for vals in Channel(producer)
            δ, s, γ = vals
            push!(Δ_tmp, γ)
            Sch_tmp[γ] = s
        end
        return new(Δ_tmp, Sch_tmp)
    end
end

# end # of module AbstractOrbits
