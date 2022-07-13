### A Pluto.jl notebook ###
# v0.19.3

using Markdown
using InteractiveUtils

# ╔═╡ fca05788-f16b-11ec-30c5-c1cb0c797642
md"""
# Finitely presented groups

In the lecture we learned that an element of a finitely presented group is a congruence class ``[w]`` of a word ``w`` over an alphabet ``\mathcal{A}(S)``. Lets unpack this definition.

0. At the bottom we have a set of symbols (*letters*) ``S``.
1. An **alphabet** ``\mathcal{A}(S)`` for a group will consist of the disjoint union of ``S`` and ``\widehat{S}``, where the latter consist of a distinct copies of elements from ``S`` connected via a bijective function ``\operatorname{inv}: S \to \widehat{S}`` (these are *formal inverses*). Here we'll need a `struct Alphabet`.
2. A set of all (including the empty) **words** ``\mathcal{A}(S)^*`` over the alphabet forms a monoid which we need to turn into a group by turning *formal* inverses to a true one. So we need a `struct Word` (which may or may not contain a reference to an `Alphabet`).
3. Finally we'll need `struct FPGroupElement` which will keep reference to a `FPGroup` (i.e. a parent object).

> **Note:** Here we're talking about groups only, but the whole `Alphabet`/`Word` setup should be general enough to encompass also *finitely presented monoids*, where not all elements have inverses.
"""

# ╔═╡ f8c187b3-73b2-4145-85d9-806582d3ca17
md"""
## Words of letters vs Words of integers

We could store letters in our words directly, however, since we'll be dealing with _millions_ of words at the same time we should be more conservative. Even storing a pointer to a letter will cost us `8` (or `4`) bytes per letter. We can do much better!

If we store only small integers (i.e. indices of letters in an alphabet) and the alphabet is short (less than `254` letters) we can get away with just `1` (one!) byte per letter (or maybe `2` for a really large alphabet). This has several advantages:

1. Memory savings -- we need almost `8`-times less memory to store a word.
2. Cache locality/cache trashing -- due to this we can more data in a single cache-line, therefore reducing global ↔ local memory lookups and transfers
3. We can use vectorized instructions to speed-up common tasks on words such as finding a subword. 
"""

# ╔═╡ 28018283-a925-43cb-9f0d-fa425f724323
md"""
> **Exercise 1**: Implement `Alphabet` structure that will allow arbitrary objects as letters (well except `Integers`) with the following functionality:
> * one can index into an `A::Alphabet` with integers receiving `i`-th letter;
> * one can index into an `A::Alphabet` with letters receiving the position where the letter is stored;
> * by default no letter has the inverse;
> * one can set a letter `X` to be the inverse of `x` so that the inverse of `X` is automatically `x`.
> * one can ask an alphabet for the inverse of a letter or an index (and receive an error if it is not invertible) 
"""

# ╔═╡ dfe2b536-77e9-47cb-9180-1ca0e7c0924a
struct Alphabet{T}
	...
end

Base.getindex(A::Alphabet{T}, letter::T) where T = ...
Base.getindex(A::Alphabet, index::Integer) = ...
setinverse!(A::Alphabet{T}, x::T, X::T) = ...
Base.inv(A::Alphabet{T}, letter::T) = ...
Base.inv(A::Alphabet{T}, index::Integer) = ...

hasinverse(A::Alphabet{T}, letter::T) = hasinverse(A, A[letter])
hasinverse(A::Alphabet, index::Integer) = ...

Base.iterate(A::Alphabet) = ...
Base.length(A) = ...

function Base.show(io::IO, A::Alphabet{T}) where T
	println(io, "Alphabet of $T with $(length(A)) letters:")
	for letter in A
		print(io, A[letter], "\t, letter")
		if hasinverse(A, letter)
			println(io, " with inverse", A[inv(A, A[letter]]))
		else
			println(io, "")
		end
	end
end

# ╔═╡ 7f9e1027-946a-4283-808a-ff7a73a8bc7a


# ╔═╡ a9035c44-1d3a-4ca4-8bff-a5df7e73f250
md"""
> **Exercise 2**: Implement `Word` structure with flexible storage type (defaulting to `UInt8`, but flexible at user disposal) which behaves like an `AbstractVector`. Words are meaningless on their own, only an alphabet brings their meaning. How should `Base.show` and `Base.inv` be implemented?
>
> What are the other functions which might working with for words simpler? (think: `Base.:*`, `Base.one`, `Base.occursin`, `prefixes`...)
>
> Think about other possible word types which might be useful in the future. What are the basic operations for words that you can think of? (do not try to set `AbstractWord` API yet, it's too early :)

Note: Words will be too common to create and throw away. In the long run we will try to make them as **mutable** as possible and implement standard functions on top of these . 
"""

# ╔═╡ 9e495a33-be52-4d10-ba96-046a81b7f2cd
abstract type AbstractWord{T} <: AbstractVector{T} end

struct Word{T} <: AbstractWord{T}
	letter_indices::Vector{T}
end

#Abstract Vector interface

# * multiplication
function inv!(out::AbstractWord, A::Alphabet, w::AbstractWord)
	@assert length(out) == length(w)
	for (idx,letter) in enumerate(Iterators.reverse(w))
		out[idx] = inv(A, letter)
	end
	return out
end
Base.inv(A::Alphabet, w::AbstractWord) = inv!(similar(w), A, w)

function Base.show(io::IO, w::AbstractWord)
	l = length(w)
	for (i, letter) in enumerate(w)
		print(io, letter)
		if i < l
			print(io, '·')
		end
	end
end

string_repr(A::Alphabet, w::AbstractWord) = 
	join(A[idx] for idx in w, '·')

# Subwords
# BufferWord


# ╔═╡ 50d69882-1d24-4563-a45a-362b569fff38
md"""
> **Exercise 3**: Implement a prototype `FreeGroup` and `FPGroupElem` structures based on the structures above. One should be able to multiply, invert and solve the word problem with those.
"""

# ╔═╡ 654848c2-b7b7-41a3-ab56-d2d07a1a9a8d
struct FreeGroup <: AbstractFPGroup #(?)
	A::Alphabet
	gens::Vector{...}
	# ... ?
end

struct FPGroupElement{W<:AbstractWord, G<:AstractFreeGroup}
	word::W
	parent::G
	# ....
end

# real interesting task:
# how and when to freely reduce the underlying words.


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[deps]
"""

# ╔═╡ Cell order:
# ╟─fca05788-f16b-11ec-30c5-c1cb0c797642
# ╟─f8c187b3-73b2-4145-85d9-806582d3ca17
# ╟─28018283-a925-43cb-9f0d-fa425f724323
# ╠═dfe2b536-77e9-47cb-9180-1ca0e7c0924a
# ╠═7f9e1027-946a-4283-808a-ff7a73a8bc7a
# ╟─a9035c44-1d3a-4ca4-8bff-a5df7e73f250
# ╠═9e495a33-be52-4d10-ba96-046a81b7f2cd
# ╟─50d69882-1d24-4563-a45a-362b569fff38
# ╠═654848c2-b7b7-41a3-ab56-d2d07a1a9a8d
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
