# ============================================================================
# Capture the exact Groebner.groebner(J) input that HANGS inside
# StructuralIdentifiability.check_primality_zerodim when the
# latent_subpopulation_branch model is pinned at a PARAMETER-SYMMETRIC point
# (a2 ~= a3, b2 = b3) — the I2<->I3 exchange degeneracy.
#
# No source edits: we override check_primality_zerodim at RUNTIME (isolated to
# this process) to serialize J before the groebner call, then drive the exact
# pipeline path (apply_prefixed_params_to_model -> get_si_equation_system).
# Run, wait for "[GB-CAPTURE] serialized ...", then kill (it will hang in groebner).
# ============================================================================
using Pkg
Pkg.activate(raw"/home/orebas/ParameterEstimationBenchmark-local/environments/julia_odepe")

using Serialization
function dump_gb(J)
    fn = "/tmp/gb_capture_$(length(J))polys.jls"
    try
        serialize(fn, J)
        @info "[GB-CAPTURE] serialized groebner input: $(length(J)) polys -> $fn"
        flush(stderr); flush(stdout)
    catch e
        @warn "[GB-CAPTURE] serialize failed" exception = e
    end
end

using ODEParameterEstimation, ModelingToolkit, OrderedCollections, CSV
using ModelingToolkit: t_nounits as t, D_nounits as D
using Symbolics: Num
import StructuralIdentifiability, Nemo, Groebner

# --- RUNTIME override (isolated to this process): dump J, then run the original body ---
@eval StructuralIdentifiability begin
    function check_primality_zerodim(J::Array{QQMPolyRingElem, 1})
        Main.dump_gb(J)                       # [GB-CAPTURE] serialize before the (possibly hanging) call
        J = Groebner.groebner(J)
        basis = Groebner.quotient_basis(J)
        dim = length(basis)
        S = Nemo.matrix_space(Nemo.QQ, dim, dim)
        matrices = []
        for v in gens(parent(first(J)))
            M = zero(S)
            for (i, vec) in enumerate(basis)
                image = Groebner.normalform(J, v * vec)
                for (j, base_vec) in enumerate(basis)
                    M[i, j] = Nemo.QQ(coeff(image, base_vec))
                end
            end
            push!(matrices, M)
        end
        generic_multiplication = sum(Nemo.QQ(rand(1:100)) * M for M in matrices)
        R, _t = Nemo.polynomial_ring(Nemo.QQ, "t")
        return Nemo.is_irreducible(Nemo.charpoly(R, generic_multiplication))
    end
end

# --- latent_subpopulation_branch (verbatim) ---
parameters = @parameters a1 a2 a3 b1 b2 b3
states = @variables S(t) I1(t) I2(t) I3(t) R(t)
observables = @variables y1(t) y2(t) y3(t)
equations = [
    D(S) ~ -b1 * S * I1 - b2 * S * I2 - b3 * S * I3,
    D(I1) ~ b1 * S * I1 - a1 * I1,
    D(I2) ~ b2 * S * I2 - a2 * I2,
    D(I3) ~ b3 * S * I3 - a3 * I3,
    D(R) ~ a1 * I1 + a2 * I2 + a3 * I3,
]
measured_quantities = [y1 ~ S, y2 ~ I1 + I2 + I3, y3 ~ R]
model, mq = create_ordered_ode_system("latent_subpopulation_branch", states, parameters, equations, measured_quantities)

# --- the SYMMETRIC candidate that hung (from the live cell's stderr): a2~=a3, b2=b3 ---
known = OrderedDict(
    a1 => 0.5515444564623, a2 => 0.5280653476711991, a3 => 0.5280653476711998,
    b1 => 0.604353296407284, b2 => 0.5932284607536389, b3 => 0.5932284607536389,
)
fixed_model, fixed_mq = ODEParameterEstimation.apply_prefixed_params_to_model(model, mq, known)

csv = CSV.read(raw"/home/orebas/ParameterEstimationBenchmark-local/benchmark_quoll_broad_2026-05-29/filetree/odepe_v2_polish_run/latent_subpopulation_branch_5_1em6/data.csv", Tuple, header = false)
data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv[1])
for (i, eq) in enumerate(fixed_mq)
    data_sample[Num(eq.rhs)] = collect(Float64, csv[i+1])
end

@info "Triggering SIAN re-run on the symmetric model (the runtime override dumps J before any groebner hang)..."
ODEParameterEstimation.get_si_equation_system(fixed_model, fixed_mq, data_sample; DD = nothing, infolevel = 1)
@info "Reached the end WITHOUT hanging."
