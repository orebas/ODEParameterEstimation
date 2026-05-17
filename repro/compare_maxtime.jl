# Compare polish maxtime values on a reduced sirt_treatment_0_1em8 case.
#
# Reduced settings (so total wall-clock is bounded for an interactive session):
#   multipoint_max_pairs = 3   (down from 15)
#   polish_maxiters      = 2000  (down from 5000)
#   polish_method        = PolishLSOBoundedLog (production residual polish)
#   abstol = reltol      = 1e-12 (production)
#   diagnostics          = true
#
# Pass MAXTIME on the command line:  julia --startup-file=no compare_maxtime.jl <maxtime_seconds>
# Output: repro/compare_maxtime_<maxtime>.json with best error and wall-clock.

using Pkg
Pkg.activate(raw"$(JULIA_ODEPE_ENV)"; io=devnull)

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using JSON
using Symbolics: Num
using Printf

length(ARGS) >= 1 || error("Usage: julia compare_maxtime.jl <maxtime_seconds>")
const MAXTIME = parse(Float64, ARGS[1])
@info "Running with polish_maxtime = $MAXTIME s"

const REPRO = joinpath(@__DIR__, "repro_sirt_treatment_0_1em8")
@assert isdir(REPRO)

name = "sirt_treatment"
parameters = @parameters a b d g nu
states = @variables  In(t) Npop(t) S(t) Tr(t)
observables = @variables  y1(t) y2(t) y3(t)
state_equations = [
    D(In) ~ 1.52*b*S*In/Npop + 0.608*d*b*S*Tr/Npop - (0.2*a + 0.6*g)*In,
    D(Npop) ~ 0,
    D(S) ~ -0.08*b*S*In/Npop - 0.032*d*b*S*Tr/Npop,
    D(Tr) ~ 6.0*g*In - 0.2*nu*Tr,
]
measured_quantities = [
    y1 ~ 10.0*Tr,
    y2 ~ 2000.0*Npop,
    y3 ~ 10.0*In,
]
ic = [0.674, 0.208, 0.725, 0.109]
p_true = [0.473, 0.734, 0.378, 0.775, 0.62]
ic_truth_dict = Dict("In" => 0.674, "Npop" => 0.208, "S" => 0.725, "Tr" => 0.109)
p_truth_dict = Dict("a" => 0.473, "b" => 0.734, "d" => 0.378, "g" => 0.775, "nu" => 0.62)

time_interval = [0.0, 10.0]

model, mq = create_ordered_ode_system(name, states, parameters, state_equations, measured_quantities)

csv_data = CSV.read(joinpath(REPRO, "data.csv"), Tuple, header=false)
data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq)
    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
end

pep = ParameterEstimationProblem(
    name, model, mq, data_sample, time_interval, nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

p_size = length(ic) + length(p_true)
opts = EstimationOptions(
    datasize = length(data_sample["t"]),
    noise_level = 0.000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    shooting_points = 10,                # reduced from 20
    shooting_warp = true,
    shooting_warp_beta = 3.0,
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 2,           # reduced from 15
    synthesize_aggregate_candidates = false,  # off — pool inflates >600 with this on
    polish_solver_solutions = true,
    polish_solutions = true,
    polish_method = PolishLSOBoundedLog,
    polish_maxiters = 1500,             # reduced from 5000
    polish_maxtime = MAXTIME,
    polish_divergence_factor = 10.0,
    polish_stagnation_window = 50,
    polish_ode_maxiters = 20000,
    opt_lb = 1e-05 * ones(p_size),
    opt_ub = 10.0 * ones(p_size),
    abstol = 1e-12,
    reltol = 1e-12,
    diagnostics = true,
)

t_start = time()
raw_results, analysis, _ = analyze_parameter_estimation_problem(pep, opts)
elapsed = time() - t_start

(solutions_vector, besterror, best_min, best_mean, best_median, best_max, best_approx, best_rms) = analysis

# Compute relative parameter error vs truth for the best solution
best_rel_err = NaN
best_p_dict = Dict{String, Float64}()
best_s_dict = Dict{String, Float64}()
n_timed_out_polishes = 0
n_polishes_total = 0
if !isempty(solutions_vector)
    bs = solutions_vector[1]
    for (k, v) in bs.parameters
        best_p_dict[string(k)] = Float64(v)
    end
    for (k, v) in bs.states
        best_s_dict[string(k)] = Float64(v)
    end
    rels = Float64[]
    for (k, t_val) in p_truth_dict
        if haskey(best_p_dict, k)
            push!(rels, abs(best_p_dict[k] - t_val) / max(abs(t_val), 1.0))
        end
    end
    for (k, t_val) in ic_truth_dict
        if haskey(best_s_dict, k)
            push!(rels, abs(best_s_dict[k] - t_val) / max(abs(t_val), 1.0))
        end
    end
    best_rel_err = isempty(rels) ? NaN : maximum(rels)

    for sol in solutions_vector
        prov = sol.provenance
        if prov.polish_applied === true
            global n_polishes_total += 1
            if :polish_maxtime_exceeded in prov.notes
                global n_timed_out_polishes += 1
            end
        end
    end
end

println()
println("="^60)
@printf("MAXTIME=%g  ELAPSED=%.1fs  N_SOL=%d  BEST_ERR=%.6g  BEST_RELERR=%.4f%%\n",
    MAXTIME, elapsed, length(solutions_vector), besterror, 100*best_rel_err)
@printf("polishes total=%d, timed_out=%d\n", n_polishes_total, n_timed_out_polishes)
println("="^60)

result = Dict(
    "maxtime" => MAXTIME,
    "elapsed_s" => elapsed,
    "n_solutions" => length(solutions_vector),
    "best_error" => besterror,
    "best_min_error" => best_min,
    "best_mean_error" => best_mean,
    "best_median_error" => best_median,
    "best_max_error" => best_max,
    "best_rel_param_err" => best_rel_err,
    "best_params" => best_p_dict,
    "best_states" => best_s_dict,
    "polishes_total" => n_polishes_total,
    "polishes_timed_out" => n_timed_out_polishes,
)

out = joinpath(@__DIR__, "compare_maxtime_$(Int(MAXTIME)).json")
open(out, "w") do io
    JSON.print(io, result, 2)
end
println("Wrote $out")
