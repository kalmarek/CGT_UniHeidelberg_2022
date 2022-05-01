@testset "Permutations" begin
    import CGT_UniHeidelberg_2022: Permutation, degree, orbit_plain

    σ = Permutation([2,1,3])
    τ = Permutation([1,3,2])

    @test inv(one(σ)) == one(σ)
    @test inv(σ)*σ == one(σ)
    @test τ*inv(τ) == one(τ)
    @test inv(σ*τ) == inv(τ)*inv(σ)
    # (1,2)·(2,3) == (1,3,2)
    @test σ*τ == Permutation([3,1,2])

    @test degree(σ) == 2
    @test degree(τ) == 3
    @test degree(one(σ)) == 1

    @test orbit_plain(1, [Permutation([2,3,4,1])]) == [1,2,3,4]

    @test sprint(show, σ) == "(1,2)"
    @test sprint(show, τ) == "(2,3)"
    @test sprint(show, one(σ)) == "()"
    ρ = Permutation([2,3,4,1])
    @test sprint(show, ρ) == "(1,2,3,4)"
    @test sprint(show, ρ*ρ) == "(1,3)(2,4)"
end

# TODO: The only change here is the type, could the testset be templatized?
# (cf. TEMPLATE_TEST_CASE in Catch2)
@testset "CyclePermutations" begin
    import CGT_UniHeidelberg_2022: CyclePermutation, degree, orbit_plain

    σ = CyclePermutation([2,1,3])
    τ = CyclePermutation([1,3,2])

    @test inv(one(σ)) == one(σ)
    @test inv(σ)*σ == one(σ)
    @test τ*inv(τ) == one(τ)
    @test inv(σ*τ) == inv(τ)*inv(σ)
    # (1,2)·(2,3) == (1,3,2)
    @test σ*τ == CyclePermutation([3,1,2])

    @test degree(σ) == 2
    @test degree(τ) == 3
    @test degree(one(σ)) == 1

    @test orbit_plain(1, [CyclePermutation([2,3,4,1])]) == [1,2,3,4]

    @test sprint(show, σ) == "(1,2)"
    @test sprint(show, τ) == "(2,3)"
    @test sprint(show, one(σ)) == "()"
    ρ = CyclePermutation([2,3,4,1])
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
    # XXX: test_throws doesn't seem to do anything. All I get is "Got
    # exception outside of a @test".
    # @test_throws Meta.ParseError perm"(1,)"
    # @test_throws Meta.ParseError perm"(,2)"
    # @test_throws Meta.ParseError perm"()"
    # @test_throws Meta.ParseError perm"(1,2"
    # @test_throws Meta.ParseError perm"2,1)"
    # @test_throws Meta.ParseError perm"2"
    # @test_throws Meta.ParseError perm"2;1"
    # @test_throws Meta.ParseError perm"(2,3,1)⋅(4,5)" # this or (2,3,1)∗(4,5) is arguably also a valid case
end
