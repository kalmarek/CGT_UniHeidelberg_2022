import CGT_UniHeidelberg_2022: transversal, schreier, representative, GroupElement

@testset "transversals: $P" for P in [Permutation, CyclePermutation2]

    @testset "transversals" begin
        @testset "action on points" begin
            σ = P([1,3,4,2]) # perm"(2,3,4)"
            τ = P([1,2,4,5,3]) # perm"(3,4,5)"
            x = 2
            S = [σ, τ]

            Δ, T = transversal(x, S)
            @test length(Δ) == 4
            for δ in Δ
                @test 2^T[δ] == δ
            end
        end

        @testset "action on perms" begin
            σ = P([1,4,2,3]) # perm"(2,4,3)"
            τ = P([2,3,1]) # perm"(1,2,3)"
            x = one(σ)
            S = [σ, τ]

            Δ, T = transversal(x, S, *)
            @test length(Δ) == 12
            for g in Δ
                @test g == T[g]
            end
        end
    end

    @testset "factored transversal" begin
        # implement here transversal_factored which contains list of generators instead of their product
        function transversal_factored(x, S::AbstractVector{<:GroupElement}, action=^)
            @assert !isempty(S)

            return
        end

        @testset "action on points" begin
            σ = P([1,3,4,2]) # perm"(2,3,4)"
            τ = P([1,2,4,5,3]) # perm"(3,4,5)"
            x = 2
            S = [σ, τ]

            Δ, T = transversal_factored(x, S)
            @test length(Δ) == 4
            for δ in Δ
                @test 2^prod(T[δ]) == δ
            end
        end

        @testset "action on perms" begin
            σ = P([1,4,2,3]) # perm"(2,4,3)"
            τ = P([2,3,1]) # perm"(1,2,3)"
            x = one(σ)
            S = [σ, τ]

            Δ, T = transversal_factored(x, S, *)
            @test length(Δ) == 12
            for g in Δ
                @test g == prod(T[g])
            end
        end
    end

    @testset "Schreier && representatives" begin
        @testset "action on points" begin
            σ = P([1,3,4,2]) # perm"(2,3,4)"
            τ = P([1,2,4,5,3]) # perm"(3,4,5)"
            x = 2
            S = [σ, τ]

            Δ, Sch = schreier(x, S)
            @test length(Δ) == 4
            for (idx,δ) in pairs(Δ)
                δ == x && continue # Sch[x] is undefined
                k = δ^inv(Sch[δ])
                @test findfirst(==(k), Δ) < idx # serialization breadth-first
                @test x^representative(δ, Δ, Sch) == δ
            end
        end

        @testset "action on perms" begin
            σ = P([1,4,2,3]) # perm"(2,4,3)"
            τ = P([2,3,1]) # perm"(1,2,3)"
            x = one(σ)
            S = [σ, τ]

            Δ, Sch = schreier(x, S, *)
            @test length(Δ) == 12
            for (idx,g) in pairs(Δ)
                g == x && continue
                h = g*inv(Sch[g])
                @test findfirst(==(h), Δ) < idx
                @test x*representative(g, Δ, Sch, *) == g
            end
        end
    end
end
