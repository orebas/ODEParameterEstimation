# What derivatives does the CSTR SI/SP template need, and what are their TRUE values
# at t=0 (left boundary) and at the first bilby shooting point?

using CSV
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Logging
using Printf
using Dates

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

# ── Build the bilby cstr_1_0 PEP exactly as the bilby script does ──
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
ic = [0.843, 0.18, 0.856]
p_true = [0.385, 0.113, 0.248, 0.421]

model, mq = ODEPE.create_ordered_ode_system("cstr", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/cstr_1_0"
pep = ParameterEstimationProblem(
    "cstr_oracle_jets", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

# Apply trfn transform manually so we can inspect the polynomialized PEP
t_var = ModelingToolkit.get_iv(pep.model.system)
pep_t, _ = ODEPE.transform_pep_for_estimation(pep, t_var)
println("Polynomialized PEP: $(pep_t.name)")
println("States after trfn: ", collect(keys(pep_t.ic)))
println("Params: ", collect(keys(pep_t.p_true)))
println()

# Run setup_parameter_estimation to extract the SI template
println("Running setup_parameter_estimation to get SI template...")
setup_data = with_logger(NullLogger()) do
    ODEPE.setup_parameter_estimation(pep_t; interpolator = ODEPE.aaad_gpr_pivot, nooutput = true)
end

println("\n=== SP Template — derivative orders needed per observable ===")
if !isnothing(setup_data.good_deriv_level)
    for (obs, lvl) in pairs(setup_data.good_deriv_level)
        @printf("  %-40s  good_deriv_level = %d\n", string(obs), lvl)
    end
end

println("\n=== Polynomial system shape ===")
println("  good_varlist (length $(length(setup_data.good_varlist))): $(setup_data.good_varlist)")
println("  good_num_points: $(setup_data.good_num_points)")
println("  time_index_set (SI advisory's preferred SP): $(setup_data.time_index_set)")
println("  good_DD type: $(typeof(setup_data.good_DD))")
if hasfield(typeof(setup_data.good_DD), :obs_lhs)
    obs_lhs = setup_data.good_DD.obs_lhs
    println("  good_DD.obs_lhs: number of orders = $(length(obs_lhs))")
    for (k, row) in enumerate(obs_lhs)
        println("    order $(k - 1): $row")
    end
end

println("\n=== Bilby production shooting points (warp=true, beta=3.0, 12 points) ===")
n_total = length(pep_t.data_sample["t"])
shoot_indices = ODEPE.compute_shooting_indices(12, n_total; warp = true, beta = 3.0)
t_vec = pep_t.data_sample["t"]
println("  n_total = $n_total points over [$(first(t_vec)), $(last(t_vec))]")
println("  shooting indices: $shoot_indices")
println("  shooting times:")
for (k, idx) in enumerate(shoot_indices)
    @printf("    SP[%2d] @ idx=%d → t = %.4f\n", k, idx, t_vec[idx])
end

# ── Evaluate oracle Taylor coefficients at t=0 (boundary), first SP, and t=9.99 ──
function show_oracle_jets(pep_t, setup_data, t_eval, label)
    println("\n=== ORACLE TAYLOR JETS at $label (t = $(round(t_eval; digits=4))) ===")
    max_order = isempty(setup_data.good_deriv_level) ? 6 : maximum(values(setup_data.good_deriv_level))
    println("Computing orders 0..$max_order for each observable...")
    oracle = ODEPE.compute_oracle_taylor_coefficients(pep_t, t_eval, max_order)
    println("  oracle keys ($(length(keys(oracle)))): $(collect(keys(oracle)))")
    for (key, jet) in pairs(oracle)
        println("  $key:")
        for (k, v) in enumerate(jet)
            @printf("    order %d:  %+.6e\n", k - 1, v)
        end
    end
end

# Three probe times
t_left   = first(t_vec) + 1e-12              # ≈ left boundary
t_first_sp = t_vec[shoot_indices[1]]         # first bilby shooting point
t_mid    = 9.9867                            # what diagnose chose previously

show_oracle_jets(pep_t, setup_data, t_left, "LEFT BOUNDARY")
show_oracle_jets(pep_t, setup_data, t_first_sp, "FIRST BILBY SHOOTING POINT")
show_oracle_jets(pep_t, setup_data, t_mid, "MIDPOINT (t=9.99)")

println("\nCSTR_ORACLE_JETS_DONE")
