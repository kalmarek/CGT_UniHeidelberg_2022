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
        """
        This function stores factors of elements in the transversal, instead
        of elements themselves. Whenever we ask for a coset representative,
        this means we need to perform `length(T[γ])` multiplications to
        recover it.

        If we only want to store the indices of the generators, instead of
        the generators themselves, `T[γ]` is an `Int[]` array, and we loop
        over `1:length(S)` instead of `S` itself. The identity can then be
        represented either be left out (by initializing `T` as an empty
        dictionary), or a special value; in the former case, array
        concatenation `T[γ] = [T[δ]; s]` will contain one element less.
        """
        transversal_factored(x, s::GroupElement, action=^) = transversal_factored(x, [s], action)

        function transversal_factored(x, S::AbstractVector{<:GroupElement}, action=^)
            @assert !isempty(S)
            Δ_vec = [x]
            Δ = Set(Δ_vec)

            # The definition of the unit element uses that `S` is not
            # empty, and that `one()` is defined for `GroupElement`.
            e = one(first(S))
            T = Dict(x => [e])

            for δ in Δ_vec
                for s in S
                    γ = action(δ, s)
                    if γ ∉ Δ
                        push!(Δ, γ)
                        push!(Δ_vec, γ)
                        T[γ] = [T[δ]; s]
                    end
                end
            end
            return Δ_vec, T
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
