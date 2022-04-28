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
