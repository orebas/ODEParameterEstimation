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

@testset "M=1 benchmark variant multiplicity regressions" begin
    daisy_mamil4_m1 = StructuralIdentifiability.@ODEmodel(
        x1'(t) = -k01 * x1(t) + k12 * x2(t) + k13 * x3(t) + k14 * x4(t) -
                 k21 * x1(t) - k31 * x1(t) - k41 * x1(t),
        x2'(t) = -k12 * x2(t) + k21 * x1(t),
        x3'(t) = -k13 * x3(t) + k31 * x1(t),
        x4'(t) = -k14 * x4(t) + k41 * x1(t),
        y1(t) = x1(t),
        y2(t) = x2(t),
        y3(t) = x3(t) + x4(t),
        y4(t) = x3(t)
    )

    seir_m1 = StructuralIdentifiability.@ODEmodel(
        S'(t) = -b * S(t) * In(t) / N(t),
        E'(t) = b * S(t) * In(t) / N(t) - nu * E(t),
        In'(t) = nu * E(t) - a * In(t),
        N'(t) = 0,
        y1(t) = In(t),
        y2(t) = N(t),
        y3(t) = E(t)
    )

    slow_fast_m1 = StructuralIdentifiability.@ODEmodel(
        xA'(t) = -k1 * xA(t),
        xB'(t) = k1 * xA(t) - k2 * xB(t),
        xC'(t) = k2 * xB(t),
        eA'(t) = 0,
        eC'(t) = 0,
        eB'(t) = 0,
        y1(t) = xC(t),
        y2(t) = eA(t) * xA(t) + eB(t) * xB(t) + eC(t) * xC(t),
        y3(t) = eA(t),
        y4(t) = eC(t),
        y5(t) = eB(t)
    )

    biohydrogenation_m1 = StructuralIdentifiability.@ODEmodel(
        x4'(t) = -k5 * x4(t) / (k6 + x4(t)),
        x5'(t) = k5 * x4(t) / (k6 + x4(t)) - k7 * x5(t) / (k8 + x5(t) + x6(t)),
        x6'(t) = k7 * x5(t) / (k8 + x5(t) + x6(t)) - k9 * x6(t) * (k10 - x6(t)) / k10,
        x7'(t) = k9 * x6(t) * (k10 - x6(t)) / k10,
        y1(t) = x4(t),
        y2(t) = x5(t),
        y3(t) = x6(t)
    )

    @test branch_multiplicity(daisy_mamil4_m1) == 1
    @test branch_multiplicity(seir_m1) == 1
    @test branch_multiplicity(slow_fast_m1) == 1
    @test branch_multiplicity(biohydrogenation_m1) == 1
end
