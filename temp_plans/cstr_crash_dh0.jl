# Verify the cstr crash hypothesis: when HC.jl finds a candidate with dH_rhoCP ≈ 0,
# C drops out of D(Temp) → SIAN re-run produces template without C → crash.
#
# Run resolve_states_with_fixed_params with dH_rhoCP=0 (and pool-typical other params).

using CSV
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Logging
using Printf

const ODEPE = ODEParameterEstimation

function _load_bilby_data(case_dir, mq)
    csv_data = CSV.read(joinpath(case_dir, "data.csv"), Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

parameters = @parameters tau Tin dH_rhoCP UA_VrhoCP
states = @variables C(t) Temp(t) r_eff(t)
observables = @variables y1(t)
eqs = [
    D(C)     ~ (1.0 - C) / (2.0*tau) - 1.999863916554819*r_eff*C,
    D(Temp)  ~ (Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C
               - 2.0*UA_VrhoCP*Temp
               + 0.8571428571428571*UA_VrhoCP
               + 0.05714285714285714*UA_VrhoCP*sin(0.5*t),
    D(r_eff) ~ 12.5*r_eff/(Temp^2) * ((Tin - Temp) / (2.0*tau)
               + 0.0285694845222117*dH_rhoCP*r_eff*C
               - 2.0*UA_VrhoCP*Temp
               + 0.8571428571428571*UA_VrhoCP
               + 0.05714285714285714*UA_VrhoCP*sin(0.5*t)),
]
mq_orig = [y1 ~ 700.0*Temp]

model, mq = ODEPE.create_ordered_ode_system("cstr", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/cstr_1_0"
pep_orig = ParameterEstimationProblem(
    "cstr_dh0", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 20.0], nothing,
    OrderedDict(parameters .=> [0.385, 0.113, 0.248, 0.421]),  # truth
    OrderedDict(states .=> [0.843, 0.18, 0.856]),
    0,
)

t_var = ModelingToolkit.get_iv(pep_orig.model.system)
pep, _ = ODEPE.transform_pep_for_estimation(pep_orig, t_var)

setup_data = with_logger(NullLogger()) do
    ODEPE.setup_parameter_estimation(pep;
        point_hint = 0.0,
        interpolator = ODEPE.aaad_gpr_pivot,
        nooutput = true)
end

println("=== Test 1: TRUTH params (dH_rhoCP = 0.248) — control ===")
flush(stdout)
truth_params = OrderedDict{Num, Float64}(
    ModelingToolkit.parameters(pep.model.system)[1] => 0.385,
    ModelingToolkit.parameters(pep.model.system)[2] => 0.113,
    ModelingToolkit.parameters(pep.model.system)[3] => 0.248,
    ModelingToolkit.parameters(pep.model.system)[4] => 0.421,
)
resolve_truth = with_logger(NullLogger()) do
    ODEPE.resolve_states_with_fixed_params(
        pep.model.system, pep.measured_quantities, pep.data_sample,
        setup_data.good_deriv_level, Dict(),
        setup_data.good_varlist, setup_data.good_DD,
        truth_params, setup_data.interpolants;
        time_index = 1, diagnostics = false,
    )
end
println("  state_vars (length $(length(resolve_truth.state_vars))): $(resolve_truth.state_vars)")
println("  status: $(resolve_truth.status), hc_status: $(resolve_truth.hc_status)")
flush(stdout)

println("\n=== Test 2: dH_rhoCP = 0.0 (pool-typical) — should crash or omit C ===")
flush(stdout)
pool_params = OrderedDict{Num, Float64}(
    ModelingToolkit.parameters(pep.model.system)[1] => 0.117,        # tau pool
    ModelingToolkit.parameters(pep.model.system)[2] => 0.385,        # Tin pool (swapped with tau truth!)
    ModelingToolkit.parameters(pep.model.system)[3] => 0.0,          # dH_rhoCP collapsed to 0
    ModelingToolkit.parameters(pep.model.system)[4] => 0.421,        # UA_VrhoCP correct
)
println("  Using pool params: $pool_params")
flush(stdout)
resolve_pool = try
    with_logger(NullLogger()) do
        ODEPE.resolve_states_with_fixed_params(
            pep.model.system, pep.measured_quantities, pep.data_sample,
            setup_data.good_deriv_level, Dict(),
            setup_data.good_varlist, setup_data.good_DD,
            pool_params, setup_data.interpolants;
            time_index = 1, diagnostics = false,
        )
    end
catch e
    println("  CAUGHT exception: $e")
    nothing
end
if !isnothing(resolve_pool)
    println("  state_vars (length $(length(resolve_pool.state_vars))): $(resolve_pool.state_vars)")
    println("  status: $(resolve_pool.status), hc_status: $(resolve_pool.hc_status)")
    println("  notes: $(resolve_pool.notes)")
    println("  number of solutions: $(length(resolve_pool.solutions))")
    state_var_names = Set(replace(string(v), "(t)" => "") for v in resolve_pool.state_vars)
    has_c = any(startswith(n, "C_") for n in state_var_names)
    has_temp = any(startswith(n, "Temp_") for n in state_var_names)
    has_reff = any(startswith(n, "r_eff_") for n in state_var_names)
    println("  Has C? $has_c   Has Temp? $has_temp   Has r_eff? $has_reff")
end

println("\n=== Test 3: dH_rhoCP = 1e-12 (numerically zero but not symbolically zero) ===")
flush(stdout)
pool_params_eps = OrderedDict{Num, Float64}(
    ModelingToolkit.parameters(pep.model.system)[1] => 0.117,
    ModelingToolkit.parameters(pep.model.system)[2] => 0.385,
    ModelingToolkit.parameters(pep.model.system)[3] => 1e-12,
    ModelingToolkit.parameters(pep.model.system)[4] => 0.421,
)
resolve_eps = try
    with_logger(NullLogger()) do
        ODEPE.resolve_states_with_fixed_params(
            pep.model.system, pep.measured_quantities, pep.data_sample,
            setup_data.good_deriv_level, Dict(),
            setup_data.good_varlist, setup_data.good_DD,
            pool_params_eps, setup_data.interpolants;
            time_index = 1, diagnostics = false,
        )
    end
catch e
    println("  CAUGHT: $e")
    nothing
end
if !isnothing(resolve_eps)
    println("  state_vars: $(resolve_eps.state_vars)")
    state_var_names = Set(replace(string(v), "(t)" => "") for v in resolve_eps.state_vars)
    has_c = any(startswith(n, "C_") for n in state_var_names)
    println("  Has C? $has_c")
end

println("\n=== CSTR_CRASH_DH0_DONE ===")
