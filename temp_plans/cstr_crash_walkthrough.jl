# Step-by-step walkthrough of the bilby cstr_1_0 polish=OFF crash:
#   "ERROR: State C is missing from the SIAN re-solve output and is not directly reconstructible."
#
# Strategy:
# 1. Build the exact bilby PEP, apply trfn polynomialization.
# 2. Run setup_parameter_estimation at SP[1] (t=0, the first bilby shooting point).
# 3. Build the polynomial template, evaluate interpolant inputs.
# 4. Solve with HC.jl → collect candidate parameter values.
# 5. Take the closest-to-truth candidate (or just truth itself if HC missed).
# 6. Call resolve_states_with_fixed_params(...) — the function whose failure is the crash.
# 7. Print out: state_vars returned, state_sol returned, missing state list.
# 8. Identify WHY C is missing:
#    (a) SIAN re-run produces template that doesn't contain C as a free var?
#    (b) C is in the template but cascade fails to solve for it?
#    (c) Something else?

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
p_true_vals = [0.385, 0.113, 0.248, 0.421]

model, mq = ODEPE.create_ordered_ode_system("cstr", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/cstr_1_0"
pep_orig = ParameterEstimationProblem(
    "cstr_crash_walkthrough", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true_vals),
    OrderedDict(states .=> ic),
    0,
)
println("Built bilby cstr_1_0 PEP. Time interval [0, 20], 1501 points.")
println("Truth params: ", pep_orig.p_true)
println("Truth ICs:    ", pep_orig.ic)
flush(stdout)

# ── Step 1: Polynomialize via trfn ──
t_var = ModelingToolkit.get_iv(pep_orig.model.system)
pep, _ = ODEPE.transform_pep_for_estimation(pep_orig, t_var)
println("\nPolynomialized PEP: $(pep.name)")
println("  Final states: ", collect(keys(pep.ic)))
println("  Final params: ", collect(keys(pep.p_true)))
flush(stdout)

# ── Step 2: setup_parameter_estimation, ~at SP[1] which is t=0 ──
println("\n[", Dates.format(now(), "HH:MM:SS"), "] Running setup_parameter_estimation (point_hint=0.0)...")
flush(stdout)
setup_data = with_logger(NullLogger()) do
    ODEPE.setup_parameter_estimation(pep;
        point_hint = 0.0,
        interpolator = ODEPE.aaad_gpr_pivot,
        nooutput = true)
end
println("setup_data:")
println("  good_num_points = $(setup_data.good_num_points)")
println("  good_deriv_level = $(setup_data.good_deriv_level)")
println("  time_index_set chosen: $(setup_data.time_index_set)")
println("  good_varlist (length $(length(setup_data.good_varlist))): $(setup_data.good_varlist)")
flush(stdout)

# ── Step 3: We'll skip running HC.jl on the full template and use TRUTH parameters
# directly, so we isolate the resolve-time failure mode. We still need a candidate dict.
known_param_dict = OrderedDict{Num, Float64}(p => Float64(v) for (p, v) in pep.p_true)
println("\nUsing truth params for resolve_states_with_fixed_params:")
for (p, v) in known_param_dict
    @printf("  %s = %.6f\n", p, v)
end
flush(stdout)

# ── Step 4: Call resolve_states_with_fixed_params at t_index=1 (= t=0) ──
println("\n[", Dates.format(now(), "HH:MM:SS"), "] Running resolve_states_with_fixed_params at time_index=1 (t=0)...")
flush(stdout)
resolve_t1 = with_logger(NullLogger()) do
    ODEPE.resolve_states_with_fixed_params(
        pep.model.system,
        pep.measured_quantities,
        pep.data_sample,
        setup_data.good_deriv_level,
        Dict(),
        setup_data.good_varlist,
        setup_data.good_DD,
        known_param_dict,
        setup_data.interpolants;
        time_index = 1,
        diagnostics = true,
    )
end
println("resolve_t1 status: $(resolve_t1.status)")
println("resolve_t1 hc_status: $(resolve_t1.hc_status)")
println("resolve_t1 cascading_status: $(resolve_t1.cascading_status)")
println("resolve_t1 used_cascading: $(resolve_t1.used_cascading)")
println("resolve_t1 notes: $(resolve_t1.notes)")
println("resolve_t1 number of solutions: $(length(resolve_t1.solutions))")
println("resolve_t1 state_vars (length $(length(resolve_t1.state_vars))): $(resolve_t1.state_vars)")
if !isempty(resolve_t1.solutions)
    for (k, sol) in enumerate(resolve_t1.solutions)
        println("\n  Solution #$k (length $(length(sol))):")
        for (i, val) in enumerate(sol)
            vname = i <= length(resolve_t1.state_vars) ? string(resolve_t1.state_vars[i]) : "?"
            @printf("    %-30s = %+.6e\n", vname, val)
        end
        if k <= length(resolve_t1.missing_vars_per_solution)
            println("    missing vars: $(resolve_t1.missing_vars_per_solution[k])")
        end
    end
end
flush(stdout)

# ── Step 5: What MTK unknowns are there, and which got resolved? ──
println("\n=== MTK unknowns vs resolve output ===")
mtk_unknowns = ModelingToolkit.unknowns(pep.model.system)
println("MTK unknowns: $mtk_unknowns")
sian_name_to_val_t1 = Dict{String, Float64}()
if !isempty(resolve_t1.solutions)
    sol = resolve_t1.solutions[1]
    for j in eachindex(resolve_t1.state_vars)
        vname = replace(string(resolve_t1.state_vars[j]), "(t)" => "")
        parsed = ODEPE.parse_derivative_variable_name(vname)
        if !isnothing(parsed)
            base, order = parsed
            if order == 0
                sian_name_to_val_t1[String(base)] = sol[j]
            end
        end
    end
end
println("SIAN name → value (order-0 only): $sian_name_to_val_t1")
println("Per-MTK-unknown:")
for s in mtk_unknowns
    sname = replace(string(s), "(t)" => "")
    if haskey(sian_name_to_val_t1, sname)
        @printf("  %-30s ✓ resolved: %+.6e\n", sname, sian_name_to_val_t1[sname])
    elseif startswith(sname, "_trfn_")
        trfn_val = ODEPE.evaluate_trfn_template_variable(sname, 0.0)
        if !isnothing(trfn_val)
            @printf("  %-30s ✓ trfn-analytical: %+.6e\n", sname, trfn_val)
        else
            @printf("  %-30s ✗ trfn-FAILED\n", sname)
        end
    else
        # Check if observable directly
        obs_match = false
        for mq_eq in pep.measured_quantities
            mq_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
            if isequal(mq_rhs, s)
                @printf("  %-30s ◎ directly observed: %s\n", sname, mq_eq.lhs)
                obs_match = true
                break
            end
        end
        if !obs_match
            @printf("  %-30s ✗ MISSING — would trigger crash here\n", sname)
        end
    end
end
flush(stdout)

# ── Step 6: For comparison, dump the resolve template equations + variables explicitly ──
# This requires going one level deeper into resolve_states_with_fixed_params, which we can't
# easily do without intercepting. But we know `resolve_t1.state_vars` is what came out.
# Let's dump WHICH equations of the SIAN re-run actually contain C, by re-running the
# sub-step manually.

println("\n=== CSTR_CRASH_WALKTHROUGH_DONE ===")
