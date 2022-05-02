# included from CGT_UniHeidelberg_2022.jl

export Permutation, CyclePermutation, degree, cycle_decomposition
export string_to_cycles, string_to_cycles_regexp

import ..degree
import ..cycle_decomposition

""" Exercise #1
`Permutation` as implementation of abstract type `AbstractPermutation`.
"""
struct Permutation <: AbstractPermutation
    images::Vector{Int}

    function Permutation(v::AbstractVector{<:Integer}, check=true)
        if check
            @assert sort(v) == 1:length(v) "Image vector doesn't define a permutation"
        end
        return new(v) # calls convert(Vector{Int}, v)
    end
end

function (σ::Permutation)(n::Integer)
    if n > length(σ.images)
        return convert(Int, n)
    else
        return σ.images[n]
    end
end

function degree(σ::Permutation)
    n = length(σ.images)
    for i in n:-1:1  # reverse in steps by -1
        if σ.images[i] != i
            return i
        end
    end
    return 1
end

""" Exercise #1
Create struct `CyclePermutation <: AbstractPermutation` that stores
`cycles::Vector{Vector{Int}}` in its fields.

* Implement the `AbstractPermutation` interface i.e. degree and obtaining
  the image of `i::Integer` under such permutation.
* Verify the correctness of multiplication, inversion etc. by writing
  appropriate begin ... end block with `@asserts`.
* What happens if we multiply `CyclePermutation` and `Permutation` together?
  Can you find where does this behaviour come from?
"""
struct CyclePermutation <: AbstractPermutation
    # Store the cyclic decomposition of the permutation.
    cycles::Vector{Vector{Int}}

    # Since we want to compute σ(i) with O(1) complexity, the simplest
    # way is to also store the vector of images. Computing σ(i) from a
    # cyclic decomposition (with disjoint cycles) would require finding
    # the cycle which contains the index i. Cycles are not necessarily
    # sorted, so this would result in O(N) complexity.
    images::Vector{Int}

    function CyclePermutation(v::AbstractVector{<:Integer}, check=true)
        # Construct temporary for cycle decomposition
        σ = Permutation(v, check)
        cycles = cycle_decomposition(σ)

        # We assume that `cycle_decomposition()` returns a product of
        # disjoint cycles. The implementation in `AbstractPermutations`
        # achieves this by computing orbits (which are either identical
        # or disjoint).
        if check
            σ_cat = Int[]
            for c ∈ cycles
                append!(σ_cat, c)
            end
            @assert allunique(σ_cat) "σ is not a decomposition in disjoint cycles"
        end
        new(cycles, σ.images) # inner constructor method
    end
end

# Since σ stores both the images and the cycles (see comment above), the
# implementation equals the one for σ::Permutation.
# XXX: CyclePermutation is not a subtype of Permutation. Can the
# implementation for `σ::Permutation` still be assigned here?
# If not, this could be a "detail" called by (σ::Permutation)(n) and
# (σ::CyclePermutation)(n).
function (σ::CyclePermutation)(n::Integer)
    if n > length(σ.images)
        return convert(Int, n)
    else
        return σ.images[n]
    end
end

function degree(σ::CyclePermutation)
    # Cycles of length k>=2 have no elements mapped to themselves;
    # it then suffices to take the maximum element in each cycle,
    # and again take the maximum over these cycles for the degree.
    deg = 1
    for c ∈ σ.cycles
        if maximum(c) > deg
            deg = maximum(c)
        end
    end
    return deg
end

# `cycle_decomposition()` can be specialized for `CyclePermutation`, in
# the sense that the operation becomes trivial (the decomposition is
# already part of the object). This avoids redundant computations when
# serializing the permutation (`Base.show()`).
function AbstractPermutations.cycle_decomposition(σ::CyclePermutation)
    return σ.cycles
end


""" Exercise 2
Parse permutations from a string, with cycles delimited by braces.
Cycles are not required to be disjoint.
"""
# Easy way: use a perl-compatible regex with `eachmatch`. Input
# validation is done by concatenating each match, and checking if the
# original string is recovered. However, only a generic error message is
# returned on invalid input.
function string_to_cycles_regexp(str::AbstractString)
    cycles = Vector{Vector{Int}}(undef, 0)
    str_reconstructed = ""

    for m in eachmatch(r"\(\d+(?:,\d+)*\)", str)
        str_cycle = m.match
        str_reconstructed *= str_cycle
        current_cycle = Int[]

        for m_num in eachmatch(r"\d+(?=[,\)])", str_cycle)
            num = tryparse(Int, m_num.match)
            @assert !isnothing(num)
            push!(current_cycle, num)
        end
        push!(cycles, copy(current_cycle))
    end

    # Basic input validation with generic error message
    if str_reconstructed != str
        throw(Meta.ParseError)
    end
    return cycles
end

# Hard way: implement a FSM by hand. Has detailed error messages for
# wrong inputs.
function string_to_cycles(str::AbstractString)
    in_cycle, in_number = false, false
    cycles = Vector{Vector{Int}}(undef, 0)
    current_cycle = Int[]
    current_num_str = ""

    for c in str # process string character by character
        if in_cycle == false && c != '('
            throw(Meta.ParseError("cycle must begin in a brace"))

        elseif c == '('
            in_cycle = true
            continue

        elseif in_number            
            if c == ')' || c == ','
                # substring of integers complete
                in_number = false
                num = tryparse(Int, current_num_str)
                @assert !isnothing(num) "Internal parser error"
                # println(current_num_str)
                push!(current_cycle, num)
                # println(current_cycle)
                current_num_str = ""
            end

            if c == ','
                continue
            elseif c == ')'
                # cycle complete, push if length >= 2
                if length(current_cycle) >= 2
                    push!(cycles, copy(current_cycle))
                end
                empty!(current_cycle)
                in_cycle = false
                # println(cycles)
                continue
            end

        elseif c == ',' && in_number == false
            throw(Meta.ParseError("separator has no preceding number"))

        elseif c == ')' && in_number == false
            throw(Meta.ParseError("terminator has no preceding number"))
        end

        if isdigit(c)
            in_number = true
            current_num_str *= c # concatenate to current string
            continue
        else
            throw(Meta.ParseError("numbers must be comma-separated"))
        end
    end

    if in_cycle == true
        throw(Meta.ParseError("cycle is unterminated"))
    end
    return cycles
end

# Turn cycles into an expression
# XXX: this makes no specific assumptions on the implementation of
# AbstractPermutation, but using ::Type{P} ... where
# P<:AbstractPermutation results in `UndefVarError: P not defined`.
function Meta.parse(::Type{Permutation}, str::AbstractString)
    cycles = string_to_cycles(str)
    if length(cycles) == 0
        return :(Permutation(Int[]))
    end

    # One way to represent a product of cycles as a Julia expression is
    # to convert each term to a Permutation (converting cycles to
    # images), and combining the expressions with '*'. In this way,
    # there are no assumptions on the implementation of '*' (which could
    # be either acting from the right, or the left).
    v = cycle_to_images(cycles[1])
    Π = :(Permutation($v)) # string interpolation

    for i ∈ range(2, length(cycles))
        v = cycle_to_images(cycles[i])
        Π = Expr(:call, :*, Π, :(Permutation($v)))
    end
    return Π
end

function cycle_to_images(cycle::Vector{Int})
    deg = maximum(cycle)
    images = collect(1:deg)

    for k in range(1, length(cycle))
        i = cycle[k]
        if k < length(cycle)
            images[i] = cycle[k+1]
        else
            images[i] = cycle[1]
        end
    end
    return images
end
export cycle_to_images

macro perm_str(str)
    return Meta.parse(Permutation, str)
end
export @perm_str

# end # of Permutations
