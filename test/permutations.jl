@testset "Permutations" for P in [Permutation, CyclePermutation]
    import CGT_UniHeidelberg_2022: Permutation, degree, orbit_plain

    σ = P([2,1,3])
    τ = P([1,3,2])

    @test inv(one(σ)) == one(σ)
    @test inv(σ)*σ == one(σ)
    @test τ*inv(τ) == one(τ)
    @test inv(σ*τ) == inv(τ)*inv(σ)
    # (1,2)·(2,3) == (1,3,2)
    @test σ*τ == P([3,1,2])

    @test degree(σ) == 2
    @test degree(τ) == 3
    @test degree(one(σ)) == 1

    @test orbit_plain(1, [P([2,3,4,1])]) == [1,2,3,4]

    @test sprint(show, σ) == "(1,2)"
    @test sprint(show, τ) == "(2,3)"
    @test sprint(show, one(σ)) == "()"
    ρ = P([2,3,4,1])
    @test sprint(show, ρ) == "(1,2,3,4)"
    @test sprint(show, ρ*ρ) == "(1,3)(2,4)"
end

@testset "Permutations (deserialization)" begin
    import CGT_UniHeidelberg_2022: Permutation, @perm_str

    # Identity
    @test Permutation(Int[]) == perm"(1)"
    @test Permutation(Int[]) == perm"" # whether this should parse the identity or return an error is up for interpretation

    # Transpositions
    @test Permutation([2,1]) == perm"(1,2)"
    @test Permutation([3,1,2]) == perm"(1,2)(2,3)"

    # Other cycles
    @test Permutation([2,3,1,5,4]) == perm"(2,3,1)(4,5)"
    @test Permutation([4,1,2,3]) == perm"(1,2)(2,3)(3,4)"

    # Invalid input
    @test_throws Meta.ParseError string_to_cycles("(1,)")
    @test_throws Meta.ParseError string_to_cycles("(,2)")
    @test_throws Meta.ParseError string_to_cycles("()")
    @test_throws Meta.ParseError string_to_cycles("(1,2")
    @test_throws Meta.ParseError string_to_cycles("2,1)")
    @test_throws Meta.ParseError string_to_cycles("2")
    @test_throws Meta.ParseError string_to_cycles("2;1")
    @test_throws Meta.ParseError string_to_cycles("(2,3,1)⋅(4,5)") # this or (2,3,1)∗(4,5) is arguably also a valid case
end
