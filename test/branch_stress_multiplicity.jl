using ODEParameterEstimation
using Test
using SIAN
using StructuralIdentifiability

include(joinpath(@__DIR__, "..", "repro", "multiplicity_complete_2026_05_19", "compute_M.jl"))

function branch_multiplicity(ode)
    return compute_algebraic_multiplicity(ode; p = 0.99, infolevel = 0)
end

@testset "Branch-stress multiplicity regressions" begin
    latent_aggregate = StructuralIdentifiability.@ODEmodel(
        S'(t) = -b1 * S(t) * I1(t) - b2 * S(t) * I2(t) - b3 * S(t) * I3(t),
        I1'(t) = b1 * S(t) * I1(t) - a1 * I1(t),
        I2'(t) = b2 * S(t) * I2(t) - a2 * I2(t),
        I3'(t) = b3 * S(t) * I3(t) - a3 * I3(t),
        R'(t) = a1 * I1(t) + a2 * I2(t) + a3 * I3(t),
        y1(t) = S(t),
        y2(t) = I1(t) + I2(t) + I3(t),
        y3(t) = R(t)
    )

    latent_observed = StructuralIdentifiability.@ODEmodel(
        S'(t) = -b1 * S(t) * I1(t) - b2 * S(t) * I2(t) - b3 * S(t) * I3(t),
        I1'(t) = b1 * S(t) * I1(t) - a1 * I1(t),
        I2'(t) = b2 * S(t) * I2(t) - a2 * I2(t),
        I3'(t) = b3 * S(t) * I3(t) - a3 * I3(t),
        R'(t) = a1 * I1(t) + a2 * I2(t) + a3 * I3(t),
        y1(t) = S(t),
        y2(t) = I1(t),
        y3(t) = I2(t),
        y4(t) = I3(t),
        y5(t) = R(t)
    )

    receptor_aggregate = StructuralIdentifiability.@ODEmodel(
        L'(t) = -kon1 * L(t) * (R1tot - Ca(t)) + koff1 * Ca(t) -
                kon2 * L(t) * (R2tot - Cb(t)) + koff2 * Cb(t),
        Ca'(t) = kon1 * L(t) * (R1tot - Ca(t)) - koff1 * Ca(t),
        Cb'(t) = kon2 * L(t) * (R2tot - Cb(t)) - koff2 * Cb(t),
        y1(t) = L(t),
        y2(t) = Ca(t) + Cb(t)
    )

    receptor_observed = StructuralIdentifiability.@ODEmodel(
        L'(t) = -kon1 * L(t) * (R1tot - Ca(t)) + koff1 * Ca(t) -
                kon2 * L(t) * (R2tot - Cb(t)) + koff2 * Cb(t),
        Ca'(t) = kon1 * L(t) * (R1tot - Ca(t)) - koff1 * Ca(t),
        Cb'(t) = kon2 * L(t) * (R2tot - Cb(t)) - koff2 * Cb(t),
        y1(t) = L(t),
        y2(t) = Ca(t),
        y3(t) = Cb(t)
    )

    @test branch_multiplicity(latent_aggregate) == 6
    @test branch_multiplicity(latent_observed) == 1
    @test branch_multiplicity(receptor_aggregate) == 2
    @test branch_multiplicity(receptor_observed) == 1
end
