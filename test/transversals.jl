function test_orbit_interface(P, T)
    @testset "AbstractOrbit API: $T, $P" begin
        @testset "action on points" begin
            σ = P([1,3,4,2]) # perm"(2,3,4)"
            τ = P([1,2,4,5,3]) # perm"(3,4,5)"
            x = 2
            S = [σ, τ]

            orb = T(x, S, ^)

            @test eltype(orb) == typeof(x)
            @test length(orb) == 4
            @test first(orb) == x
            @test 5 in orb
            @test !(1 in orb)

            l = Int[]
            for pt in orb
                push!(l, pt)
            end
            @test length(l) == length(orb)
            @test CGT.action(orb) == ^

            @test issubset(collect(orb), Set([2,3,4,5]))

            if orb isa CGT.AbstractTransversal
                @test orb[first(orb)] isa AbstractPermutations.AbstractPermutation
                for pt in orb
                    @test first(orb)^orb[pt] == pt
                end
            end
        end

        @testset "action on perms" begin
            σ = perm"(2,4,3)"
            τ = perm"(1,2,3)"
            x = one(σ)
            S = [σ, τ]

            orb = T(x, S, *)
            @test eltype(orb) == typeof(x)
            @test length(orb) == 12
            @test first(orb) == x
            @test σ*τ in orb
            @test !(perm"(1,2,3,4,5)" in orb)

            l = typeof(x)[]
            for pt in orb
                push!(l, pt)
            end
            @test length(l) == length(orb)
            @test CGT.action(orb) == *

            if orb isa CGT.AbstractTransversal
                @test orb[first(orb)] isa AbstractPermutations.AbstractPermutation
                for pt in orb
                    @test pt == orb[pt]
                end
            end
        end
    end
end

test_orbit_interface(CGT.Permutation, CGT.Orbit)
test_orbit_interface(CGT.CyclePermutation2, CGT.Orbit)

test_orbit_interface(CGT.Permutation, CGT.Transversal)
test_orbit_interface(CGT.CyclePermutation2, CGT.Transversal)
