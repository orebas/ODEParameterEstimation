# Verify cstr_1_0 polish=OFF no longer crashes after Change 1.
# Also smoke-test Change 2 by setting opts.opt_lb / opts.opt_ub.

using CSV
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

# Build the bilby cstr_1_0 PEP
parameters = @parameters tau Tin dH_rhoCP UA_VrhoCP
states = @variables C(t) Temp(t) r_eff(t)
observables = @variables y1(t)
eqs = [
    D(C)     ~ (1.0 - C) / (2.0*tau) - 1.999863916554819*r_eff*C,
    D(Temp)  ~ (Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C
               - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP
               + 0.05714285714285714*UA_VrhoCP*sin(0.5*t),
    D(r_eff) ~ 12.5*r_eff/(Temp^2) * ((Tin - Temp) / (2.0*tau)
               + 0.0285694845222117*dH_rhoCP*r_eff*C
               - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP
               + 0.05714285714285714*UA_VrhoCP*sin(0.5*t)),
]
mq_orig = [y1 ~ 700.0*Temp]
ic = [0.843, 0.18, 0.856]
p_true_vals = [0.385, 0.113, 0.248, 0.421]

model, mq = ODEPE.create_ordered_ode_system("cstr", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/cstr_1_0"
pep = ParameterEstimationProblem(
    "cstr_after_fix", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true_vals),
    OrderedDict(states .=> ic),
    0,
)

println("[", Dates.format(now(), "HH:MM:SS"), "] Test 1: cstr_1_0 polish=OFF without bounds — should NOT crash now")
flush(stdout)

# Replicate bilby polish=OFF config (small datasize for speed)
opts_no_bounds = EstimationOptions(
    datasize = 1501,
    time_interval = [0.0, 20.0],
    nooutput = true,
    diagnostics = false,
    save_system = false,
    polish_solutions = false,
    polish_solver_solutions = false,
)

elapsed_t1 = @elapsed begin
    result_t1 = try
        with_logger(NullLogger()) do
            ODEPE.analyze_parameter_estimation_problem(pep, opts_no_bounds)
        end
    catch e
        println("CAUGHT: $e")
        nothing
    end
end
@printf("[%s] Test 1 done in %.1f s. Result type: %s\n",
    Dates.format(now(), "HH:MM:SS"), elapsed_t1, typeof(result_t1))
if !isnothing(result_t1)
    raw_results, analyzed_results, uq = result_t1
    @printf("Result shape: raw_results length=%d, analyzed_results length=%d\n",
        length(raw_results[1]), length(analyzed_results[1]))
    if !isempty(analyzed_results[1])
        best = first(analyzed_results[1])
        @printf("Best candidate err: %.4g\n", isnothing(best.err) ? Inf : best.err)
        println("  parameters: $(best.parameters)")
        println("  states (ICs): $(best.states)")
    else
        println("No analyzed_results — pipeline survived but produced no candidates")
    end
end
flush(stdout)

println("\n[", Dates.format(now(), "HH:MM:SS"), "] Test 2: cstr_1_0 polish=OFF WITH bounds — Change 2 active")
flush(stdout)

# Set bounds: 5 unknowns total (3 states + 4 params? Let me count)
# states: C, Temp, r_eff = 3
# params: tau, Tin, dH_rhoCP, UA_VrhoCP = 4
# total p_size = 7
# Bound order: [state_ic_bounds; param_bounds] = [C_lb, Temp_lb, r_eff_lb; tau_lb, Tin_lb, dH_rhoCP_lb, UA_VrhoCP_lb]
# Constrain dH_rhoCP > 0.05 (truth=0.248). Other params loose.
opts_with_bounds = EstimationOptions(
    datasize = 1501,
    time_interval = [0.0, 20.0],
    nooutput = true,
    diagnostics = false,
    save_system = false,
    polish_solutions = false,
    polish_solver_solutions = false,
    opt_lb = [-100.0, -100.0, -100.0,  0.001,  0.001, 0.05,  0.001],
    opt_ub = [ 100.0,  100.0,  100.0, 10.0,   10.0,  10.0,  10.0],
)

elapsed_t2 = @elapsed begin
    result_t2 = try
        with_logger(NullLogger()) do
            ODEPE.analyze_parameter_estimation_problem(pep, opts_with_bounds)
        end
    catch e
        println("CAUGHT: $e")
        nothing
    end
end
@printf("[%s] Test 2 done in %.1f s. Result type: %s\n",
    Dates.format(now(), "HH:MM:SS"), elapsed_t2, typeof(result_t2))
if !isnothing(result_t2)
    raw_results, analyzed_results, uq = result_t2
    @printf("Result shape: raw_results length=%d, analyzed_results length=%d\n",
        length(raw_results[1]), length(analyzed_results[1]))
    if !isempty(analyzed_results[1])
        best = first(analyzed_results[1])
        @printf("Best candidate err: %.4g\n", isnothing(best.err) ? Inf : best.err)
        println("  parameters: $(best.parameters)")
        println("  states (ICs): $(best.states)")
    else
        println("No analyzed_results — pipeline survived but produced no candidates")
    end
end

println("\n[", Dates.format(now(), "HH:MM:SS"), "] CSTR_AFTER_FIX_DONE")
