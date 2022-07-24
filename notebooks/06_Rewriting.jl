### A Pluto.jl notebook ###
# v0.19.4

using Markdown
using InteractiveUtils

# ╔═╡ 6639b66d-03d8-457e-b20f-87a72903740b
using Test

# ╔═╡ d755aad8-c5e9-4b2f-bc25-b4e4b5955538
begin
"""
    AbstractWord{T} <: AbstractVector{T}
Abstract type representing words over an Alphabet.

`AbstractWord` is just a string of integers and as such gains its meaning in the
contex of an Alphabet (when integers are understood as pointers to letters).
The subtypes of `AbstractWord{T}` need to implement the following methods which
constitute `AbstractWord` interface:
 * a constructor from `AbstractVector{T}`
 * linear indexing (1-based) consistent with iteration returning pointers to letters of an alphabet (`getindex`, `setindex!`, `size`),
 * `Base.push!`/`Base.pushfirst!`: append a single value at the end/beginning,
 * `Base.pop!`/`Base.popfirst!`: pop a single value from the end/beginning,
 * `Base.append!`/`Base.prepend!`: append a another word at the end/beginning,
 * `Base.resize!`: drop/extend a word at the end to the requested length
 * `Base.similar`: an uninitialized word of a similar type/storage.

Note that `length` represents free word (how it is written in an alphabet)
and not its the shortest form (e.g. the normal form).

!!! note
    It is assumed that `eachindex(w::AbstractWord)` returns `Base.OneTo(length(w))`

The following are implemented for `AbstractWords` but can be overloaded for
performance reasons:

* `Base.==`: the equality (as words),
* `Base.hash`: simple uniqueness hashing function
* `Base.:*`: word concatenation (monoid binary operation),
"""
abstract type AbstractWord{T<:Integer} <: AbstractVector{T} end

function Base.hash(w::AbstractWord, h::UInt)
    return foldl((h, x) -> hash(x, h), w, init = hash(AbstractWord, h))
end

@inline function Base.:(==)(w::AbstractWord, v::AbstractWord)
    length(w) == length(v) || return false
    return all(w[i] == v[i] for i in eachindex(w))
end

# resize! + copyto!
function store!(w::AbstractWord, v::AbstractWord)
    resize!(w, length(v))
    copyto!(w, v)
    return w
end

Base.one(::Type{W}) where {T,W<:AbstractWord{T}} = W(T[])
Base.one(::W) where {W<:AbstractWord} = one(W)
Base.isone(w::AbstractWord) = isempty(w)

function Base.getindex(w::W, u::AbstractRange) where {W<:AbstractWord}
    return W([w[i] for i in u])
end

function Base.:^(w::AbstractWord, n::Integer)
    return n >= 0 ? repeat(w, n) :
           throw(
        DomainError(
            n,
            "To rise a Word to negative power you need to provide its inverse.",
        ),
    )
end
	
function Base.literal_pow(::typeof(^), w::AbstractWord, ::Val{p}) where {p}
    return p >= 0 ? repeat(w, n) :
           throw(
        DomainError(
            p,
            "To rise a Word to negative power you need to provide its inverse.",
        ),
    )
end
	
function Base.show(io::IO, ::MIME"text/plain", w::AbstractWord)
    print(io, typeof(w), ": ")
    return show(io, w)
end

function Base.show(io::IO, w::AbstractWord{T}) where {T}
    if isone(w)
        print(io, "(id)")
    else
        join(io, w, "·")
    end
end

Base.similar(w::AbstractWord) = similar(w, eltype(w), length(w))
Base.similar(w::AbstractWord, ::Type{T}) where T = similar(w, T, length(w))
Base.similar(w::AbstractWord, n::Integer) = similar(w, eltype(w), n)

end

# ╔═╡ 42d4232f-0fbd-4fc1-89f0-42e700ccf3dd
begin
struct Alphabet{T}
    letters::Vector{T}
    letter_to_idx::Dict{T, Int}
    inverses::Vector{Int}
end

function Alphabet(letters::AbstractVector)
	@assert !(eltype(letters) <: Integer)
    letters_to_idx = Dict(l=>i for (i, l) in pairs(letters))
    inverses = zeros(Int, length(letters))
    return Alphabet(letters, letters_to_idx, inverses)
end

Base.iterate(A::Alphabet) = iterate(A.letters)
Base.iterate(A::Alphabet, state) = iterate(A.letters, state)
Base.length(A::Alphabet) = length(A.letters)
Base.eltype(::Type{Alphabet{T}}) where T = T

Base.getindex(A::Alphabet, idx::Integer) = A.letters[idx]
Base.getindex(A::Alphabet, letter) = A.letter_to_idx[letter]
hasinverse(idx::Integer, A::Alphabet) = !iszero(A.inverses[idx])
hasinverse(letter, A::Alphabet) = hasinverse(A[letter], A)

Base.in(letter, A::Alphabet) = Base.haskey(A.letter_to_idx, letter)
Base.in(idx::Integer, A::Alphabet) = 1≤idx≤length(A)

function setinverse!(A::Alphabet, x::Integer, X::Integer)
    @assert x in A && X in A
    A.inverses[x] = X
    A.inverses[X] = x
    return A
end
setinverse!(A::Alphabet, l1, l2) = setinverse!(A, A[l1], A[l2])

function Base.inv(idx::Integer, A::Alphabet)
    if hasinverse(idx, A)
        return A.inverses[idx]
    end
    throw(DomainError(idx=>A[idx], "$(idx=>A[idx]) is not invertible in $A"))
end
Base.inv(letter, A::Alphabet) = A[inv(A[letter], A)]

function Base.show(io::IO, ::MIME"text/plain", A::Alphabet)
    for (idx, l) in enumerate(A)
        print(io, " ", idx, ":\t → ", l)
        hasinverse(idx, A) && print(io, "\t inverse of: ", inv(l, A))
        idx == length(A) && break
        println(io)
    end
end

Base.show(io::IO, A::Alphabet{T}) where T =
    print(io, "Alphabet{$T}: ", A.letters)

@testset "Alphabet" begin
    letters = [:a, :b, :A]
    A = Alphabet(letters)
    @test collect(A) == letters
    @test eltype(A) == eltype(letters)

    @test !any(hasinverse(l, A) for l in letters)
    @test !any(hasinverse(i, A) for i in 1:length(letters))

    @test A[letters[1]] == 1
    @test A[1] == letters[1]

    @test_throws DomainError inv(1, A)
    setinverse!(A, 1, 3)
    @test inv(1, A) == 3
    @test inv(A[1], A) == A[3]

    setinverse!(A, A[1], A[2])

    @test inv(1, A) == 2
    @test inv(A[1], A) == A[2]

    @test :b in A && 2 in A
    @test !(:d in A) && !(4 in A)

end
end

# ╔═╡ 1f1d17f3-7bc8-460e-9f84-c6e4185d967e
begin

struct Word{T} <: AbstractWord{T}
    letter_indices::Vector{T}

    function Word{T}(idx::AbstractVector) where T <: Integer
        w = new(idx)
        return w
    end
end

Word(v::AbstractVector{<:Integer}) = Word{UInt8}(v)

Base.size(w::Word) = size(w.letter_indices)
Base.getindex(w::Word, i::Integer) = w.letter_indices[i]
Base.setindex!(w::Word, v, i::Integer) = w.letter_indices[i] = v

Base.resize!(w::Word, n::Integer) = (resize!(w.letter_indices, n); w)

Base.pop!(w::Word) = pop!(w.letter_indices)
Base.popfirst!(w::Word) = popfirst!(w.letter_indices)

Base.push!(w::Word, n::Integer) = push!(w.letter_indices, n)
Base.pushfirst!(w::Word, n::Integer) = pushfirst!(w.letter_indices, n)

Base.append!(w::Word, v::AbstractWord) = append!(w.letter_indices, v)
Base.prepend!(w::Word, v::AbstractWord) = prepend!(w.letter_indices, v)

Base.similar(w::Word, ::Type{T}, n::Integer) where T = Word{T}(similar(w.letter_indices, T, n))
	
end

# ╔═╡ e34fa62e-027f-11ed-08f1-0d4298b5ec19
md"
# First shot at rewriting

So far we learned that It's best to separate letters (`Alphabet`) from words -- this way we can allow letters to grow (in size) and stor all the information we ever want without impacting the performance of operations on words.

Today we'll implement the first of such operations: __rewriting__.

Let us recall what we have:
"

# ╔═╡ bdadcd88-1332-44da-b3a5-897b0add8755
md"
Here is the specification of `AbstractWord` API:
"

# ╔═╡ 9b657b5f-f6ba-4f7b-af07-0c0b827576e2
md"
And a particular implementation of it
"

# ╔═╡ e094ec1d-102a-44a8-a697-e7741c7a36c4
function issuffix(v::AbstractWord, w::AbstractWord)
	d = length(w) - length(v)
	d < 0 && return false

	for (idx, l) in pairs(v)
		l == w[d+idx] || return false
	end

	return true
end

# ╔═╡ ccef219d-fe0c-40e2-9000-4a7901de7735
w1 = Word([1,2,3])

# ╔═╡ 606788cc-dfad-46d9-8eca-e4524d59ac43
show(stdout, [w1,])

# ╔═╡ 1e676b97-d78b-47b0-9cf8-2467aab98956


# ╔═╡ 93f5677d-5891-4a8b-9c6e-c48b26d45ce5
md"
## Rewriting
We'll base our rewriting procedure on a queue based-approach. In particular this will be a __destructive__ rewrite, i.e. the content of word `w` which is supposed to be rewritten will be transferred to another word in the process. Let us set the groundwork for this approach:
"

# ╔═╡ 47cf6cb4-b84f-46a9-a5d1-8d01b2f0a84f
md"""
Ok, so what can the `rewriting` object be? Let's start from something very simple. One could define _trivial rewriting_ as follows:
```julia
"
    rewrite!(v::AbstractWord, w::AbstractWord, ::Any)
Trivial rewrite: word `w` is simply stored (copied) to `v`.
"
rewrite!(v::AbstractWord, w::AbstractWord, ::Any) = store!(v, w)
```
But maybe it's better to `throw` instead?
"""

# ╔═╡ b5dac854-6dfb-48d4-81b4-acba340c84bb
md"
### Free reduction
A more interesting example could the _free reduction_, which essentially needs only an `Alphabet`:
"

# ╔═╡ b5f4e577-7807-4c71-a408-737623af9edf
"""
    rewrite!(v::AbstractWord, w::AbstractWord, A::Alphabet)
Rewrite word `w` storing the result in `v` by applying free reductions as
defined by the inverses present in alphabet `A`.
"""
function rewrite!(v::AbstractWord, w::AbstractWord, A::Alphabet)
    v = resize!(v, 0)
    while !isone(w)
		a = popfirst!(w)
		if !isone(v) && hasinverse(a, A) && inv(a, A) == last(v)
			resize!(v, length(v) - 1)
		else
			push!(v, a)
		end
    end
    return v
end

# ╔═╡ 541c6db9-0e72-4de1-9823-2e318dcf0dc0
md"""
### Rule-based rewriting

This will require a bit of thought. If we follow blindly the pattern of "find and replace, then repeat" we can be easily wasting lots of effort. On the other hand a single pass of "find and replace" may leave us with with unfinished rewriting.

Imaginge we have a rule `abab → ba` and we're rewriting a word `aababb`. The obvious single application of the rule yields `a·ba·b = abab`. We learn only on the second pass that the whole thing rewrites to `ba`. To achieve this we will adopt a queue based prodecudre. That is starting from a word `w` (to be rewritten) we will be transfering letters from `w` to the (initially empty word) `v` one-by-one, looking for possible opportunities to rewrite the _suffix_ of `V`. Such situation will occur when 
> `v=aabab` and 
> `w = b`. 

Now we will remove the _lhs_ of the rule from the end of `v` and __prepend__ the _rhs_ to `w`. After this step we'll see
> `v = a` and
> `w = bab`.

Transfering the letters again to `v` we encounter `abab` as a suffix of `v` when
> `v = abab` and
> `w = ε`.

we apply the same rule and get
> `v = ε` and
> `w = ba`.

No further suffixes of `v` in the process match our rule, so we output `v = ba` as the rewritten `w`.
"""

# ╔═╡ 2de66d50-73d4-4edb-870d-0dd1cad2b0cf
const Rule{W} = Pair{W, W} where W <: AbstractWord

# ╔═╡ ad8d78ce-14e5-4f82-bda0-73e85cd13a95
"""
    rewrite!(v::AbstractWord, w::AbstractWord, rule::Rule)
Rewrite word `w` storing the result in `v` by using a single rewriting `rule`.
"""
function rewrite!(v::AbstractWord, w::AbstractWord, rule::Rule)
    v = resize!(v, 0)
    lhs, rhs = rule
    while !isone(w)
        push!(v, popfirst!(w))
        if issuffix(lhs, v)
            prepend!(w, rhs)
            resize!(v, length(v) - length(lhs))
        end
    end
    return v
end

# ╔═╡ e46af5cf-4162-4645-ae9a-8af12b970bb4
md"
## Rewriting systems
Finally this is a rewriting w.r.t. a rewriting system `rws`. Later on (if time permits) we'll see a much more efficient way of rewriting using so called index automata (sometimes referred to as transducers in CS). 
"

# ╔═╡ 4aa03df1-e3e7-4837-81bf-bbe0f898dbde
"""
    rewrite!(v::AbstractWord, w::AbstractWord, rws::RewritingSystem)
Rewrite word `w` storing the result in `v` by left using rewriting rules of
rewriting system `rws`. See [Sims, p.66]
"""
function rewrite!(
    v::AbstractWord,
    w::AbstractWord,
    rws #::RewritingSystem,
)
    v = resize!(v, 0)
    while !isone(w)
        push!(v, popfirst!(w))
        for (lhs, rhs) in rws # in the future: rwrules(rws)
            if issuffix(lhs, v)
                prepend!(w, rhs)
                resize!(v, length(v) - length(lhs))
                break
            end
        end
    end
    return v
end

# ╔═╡ e1a7a33a-77ba-4b52-b37d-5b5555a2b47d
"""
    rewrite(w::AbstractWord, rewriting)
Rewrites word `w` using `rewriting` object. The object must implement
`rewrite!(v::AbstractWord, w::AbstractWord, rewriting)`.
"""
function rewrite(
    w::W,
    rewriting,
    vbuffer = one(w),
	# a queue with pre-allocated space at the end:
	# vbuffer = BufferWord{eltype(w)}(0, length(w)), 
    wbuffer = similar(w), 
	# a queue with pre-allocated space at the begining:
	# wbuffer = BufferWord{eltype(w)}(length(w), 0),
) where W
	# copy the content of w to wbuffer, possibly adjuting its size
    store!(wbuffer, w) 
	# do the destructive rewriting from `wbuffer` to `vbuffer`
    v = rewrite!(vbuffer, wbuffer, rewriting)
    return W(v) # return the result of the same type as w
end

# ╔═╡ 00d21c8c-733f-4c6d-84f4-cec820dad0aa
begin
	@testset "free reduction" begin
		A = Alphabet([:a, :b, :A])
		setinverse!(A, :a, :A)
		w = Word([A[:a], A[:A]])
		@test isone(rewrite(w, A))
		w = Word([A[:b], A[:a], A[:A]])
		@test rewrite(w, A) == Word([A[:b]])
	
		w = Word([A[:A], A[:b], A[:a]])
		@test rewrite(w, A) == w
	
		w = Word([A[:A], A[:a], A[:A]])
		@test rewrite(w, A) == Word([A[:A]])
	
		setinverse!(A, :b, :b)
		w = Word([A[:b], A[:a], A[:A], A[:b]])
		@test isone(rewrite(w, A))
	end
end

# ╔═╡ 1d5b1416-98e5-4106-8f08-26b047d6caec
md"""
> **Exercise**: Verify (empirically:) that the _rws_ for ℤ² defined by `LenLex(:a<:A<:b<:B)` correctly rewrites words to their canonical form. (for now just pass a vector of rules as `rws`).

> **Exercise**: Implement a (toy, simple) routine that verifies confluence of rwses based on the lecture. Test it on a variety of sets of rules (start with some arbitrary ones and/or those taken from Sims book). Try to complete some of them in a "computer guided fashion".

What you may find useful is `@debug` macro. Debugging messages in a module may be enabled through setting `ENV["JULIA_DEBUG"] = "CGT_UniHeidelberg2022"` and disabled by deleting the key, or setting it to "".
"""

# ╔═╡ 35a5b626-a10a-440e-b3e7-229a15f8c824
@testset "Z^2" begin
	A = Alphabet([:a, :A, :b, :B])
	rws_z2 = [
		Word([A[:a], A[:A]]) => Word(Int[]),
		Word([A[:A], A[:a]]) => Word(Int[]),
		Word([A[:b], A[:B]]) => Word(Int[]),
		Word([A[:B], A[:b]]) => Word(Int[]),

		Word([A[:b], A[:a]]) => Word([A[:a], A[:b]]),
		Word([A[:b], A[:A]]) => Word([A[:A], A[:b]]),
		Word([A[:B], A[:a]]) => Word([A[:a], A[:B]]),
		Word([A[:B], A[:A]]) => Word([A[:A], A[:B]]),
	]

	for _ in 1:100
		v = Word(UInt8[rand(1:length(A)) for _ in 1:rand(1:50)])
		w = rewrite(v, rws_z2)
		@test length(w) ≤ length(v)

		for i in 1:length(w)-1
			@test w[i] ≤ w[i+1]
			w[i] == 2 || @test w[i+1] - w[i] != 1
		end
	end
end

# ╔═╡ f6c39a04-425a-4e32-aeab-b43f0222286b
md"""
## Orderings
A crucial role in the rewriting process is played by the **rewriting ordering** (translation invariant well ordering). In Julia those can be implemented as follows:
"""

# ╔═╡ dd4501cf-0cdf-4c15-a515-0d1c01b9d32c
begin
	import Base.Order: lt, Ordering
	abstract type WordOrdering <: Ordering end

	"""
	    struct LenLex{T} <: WordOrdering
	
	`LenLex` order compares words first by length and then by lexicographic (left-to-right) order.
	"""
	struct LenLex{T} <: WordOrdering
		A::Alphabet{T}
		reordering::Vector{Int}
	
		function LenLex(A::Alphabet{T}, ord::Vector{T}) where T
			reord = Vector{Int}(undef, length(ord))
			for i in 1:length(ord)
				reord[A[ord[i]]] = i
			end
			new{T}(A, reord)
		end
	end

	function lt(o::LenLex, lp::Integer, lq::Integer)
		return o.reordering[lp] < o.reordering[lq]
	end
	
	function lt(o::LenLex, p::AbstractWord, q::AbstractWord)
	    if length(p) == length(q)
			for (lp, lq) in zip(p, q)
				# lp < lq && return true
				lt(o, lp, lq) && return true
				lt(o, lq, lp) && return false
			end
			return false # i.e. p == q
		else
			return length(p) < length(q)
		end
	end
end

# ╔═╡ e2e84aeb-bffa-410d-9d65-9c83b87f7d43
md"
> **Exercise**: Implement `LenLex` so that the following tests pass.

There are many other orderings used in practice for rewriting:
* `WeightedLex`
* `WreathOrder`
* `WeightedWreath`
* `RecursivePath`
and many more.

> **Exercise**: Try to find their definitions and understand/implement some form of the `WreathOrder` or `RecursivePath`. Produce meaningful tests for those.
"

# ╔═╡ 7df89bdf-6e09-4022-829c-0e9e87443450
@testset "LenLex" begin
	A = Alphabet([:a, :A, :b, :B])
    setinverse!(A, :a, :A)
    setinverse!(A, :b, :B)

    lenlexord = LenLex(A, [:a, :A, :B, :b])

    @test lenlexord isa Base.Order.Ordering

    u1 = Word([1,2])
    u3 = Word([1,3])
    u4 = Word([1,2,3])
    u5 = Word([1,4,2])

    @test lt(lenlexord, u1, u3) == true
    @test lt(lenlexord, u3, u1) == false
    @test lt(lenlexord, u3, u4) == true
    @test lt(lenlexord, u4, u5) == true
    @test lt(lenlexord, u5, u4) == false
    @test lt(lenlexord, u1, u1) == false
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
"""

# ╔═╡ Cell order:
# ╟─e34fa62e-027f-11ed-08f1-0d4298b5ec19
# ╠═6639b66d-03d8-457e-b20f-87a72903740b
# ╠═42d4232f-0fbd-4fc1-89f0-42e700ccf3dd
# ╟─bdadcd88-1332-44da-b3a5-897b0add8755
# ╠═d755aad8-c5e9-4b2f-bc25-b4e4b5955538
# ╟─9b657b5f-f6ba-4f7b-af07-0c0b827576e2
# ╠═1f1d17f3-7bc8-460e-9f84-c6e4185d967e
# ╠═e094ec1d-102a-44a8-a697-e7741c7a36c4
# ╠═ccef219d-fe0c-40e2-9000-4a7901de7735
# ╠═606788cc-dfad-46d9-8eca-e4524d59ac43
# ╠═1e676b97-d78b-47b0-9cf8-2467aab98956
# ╟─93f5677d-5891-4a8b-9c6e-c48b26d45ce5
# ╠═e1a7a33a-77ba-4b52-b37d-5b5555a2b47d
# ╟─47cf6cb4-b84f-46a9-a5d1-8d01b2f0a84f
# ╟─b5dac854-6dfb-48d4-81b4-acba340c84bb
# ╠═b5f4e577-7807-4c71-a408-737623af9edf
# ╠═00d21c8c-733f-4c6d-84f4-cec820dad0aa
# ╟─541c6db9-0e72-4de1-9823-2e318dcf0dc0
# ╠═2de66d50-73d4-4edb-870d-0dd1cad2b0cf
# ╠═ad8d78ce-14e5-4f82-bda0-73e85cd13a95
# ╟─e46af5cf-4162-4645-ae9a-8af12b970bb4
# ╠═4aa03df1-e3e7-4837-81bf-bbe0f898dbde
# ╟─1d5b1416-98e5-4106-8f08-26b047d6caec
# ╠═35a5b626-a10a-440e-b3e7-229a15f8c824
# ╟─f6c39a04-425a-4e32-aeab-b43f0222286b
# ╠═dd4501cf-0cdf-4c15-a515-0d1c01b9d32c
# ╟─e2e84aeb-bffa-410d-9d65-9c83b87f7d43
# ╠═7df89bdf-6e09-4022-829c-0e9e87443450
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
