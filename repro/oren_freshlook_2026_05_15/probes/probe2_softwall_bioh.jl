# Probe 2: Soft-wall regularization on biohydrogenation_6_1em6.
#
# Setup: load biohydrogenation_6_1em6 truth + data from the rsync mirror.
# Run analyze_parameter_estimation_problem with default opts (control) and with
# several (polish_softwall_lambda, polish_softwall_epsilon) settings.
# Report: per-row k10 distribution, oracle best-row rank, oracle range.
#
# To run:
#   julia --startup-file=no -e 'include("repro/oren_freshlook_2026_05_15/probes/probe2_softwall_bioh.jl")'

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using JSON
using Symbolics: Num
using Printf

const CELL_DIR = "/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run/biohydrogenation_6_1em6"
const OUT_DIR = joinpath(@__DIR__, "probe2_outputs")
isdir(OUT_DIR) || mkdir(OUT_DIR)

# --- biohydrogenation model ---
name = "biohydrogenation"
parameters = @parameters k5 k6 k7 k8 k9 k10
states = @variables x4(t) x5(t) x6(t) x7(t)
observables = @variables y1(t) y2(t)
state_equations = [
    D(x4) ~ (-8.0*k5*x4) / (8.0*(4.0*k6 + 8.0*x4)),
    D(x5) ~ ((-0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5) + (8.0*k5*x4) / (4.0*k6 + 8.0*x4)) / 0.5,
    D(x6) ~ ((-0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (10.0*k10) + (0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5)) / 0.5,
    D(x7) ~ (0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (5.0*k10),
]
measured_quantities = [
    y1 ~ 8.0*x4,
    y2 ~ 0.5*x5,
]
ic = [0.639, 0.841, 0.397, 0.421]
p_true = [0.476, 0.397, 0.107, 0.889, 0.73, 0.818]
time_interval = [0.0, 10.0]

model, mq = create_ordered_ode_system(name, states, parameters, state_equations, measured_quantities)
csv_data = CSV.read(joinpath(CELL_DIR, "data.csv"), Tuple, header=false)
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

const TRUTH_PARAMS = Dict("k5"=>0.476, "k6"=>0.397, "k7"=>0.107, "k8"=>0.889, "k9"=>0.73, "k10"=>0.818)
const TRUTH_ICS = Dict("x4"=>0.639, "x5"=>0.841, "x6"=>0.397, "x7"=>0.421)

# Reduced-but-realistic settings for the probe (avoid full 5+ minutes per run).
function make_opts(; softwall_lambda=0.0, softwall_epsilon=0.05)
    EstimationOptions(
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
        multipoint_max_pairs = 5,            # reduced from 15
        polish_solver_solutions = true,
        polish_solutions = true,
        polish_maxiters = 2000,              # reduced from 5000
        polish_method = PolishLSOBoundedLog,
        polish_softwall_lambda = softwall_lambda,
        polish_softwall_epsilon = softwall_epsilon,
        opt_maxiters = 100000,
        opt_lb = 1e-05 * ones(length(ic) + length(p_true)),
        opt_ub = 10.0 * ones(length(ic) + length(p_true)),
        abstol = 1e-12,
        reltol = 1e-12,
        polish_maxtime = 600.0,              # reduced from 3600
        polish_divergence_factor = 10.0,
        polish_stagnation_window = 50,
        polish_ode_maxiters = 20000,
        diagnostics = false,                 # diagnostics off — we don't need them here
        nooutput = true,
    )
end

function rel_err(v, t)
    return abs(v - t) / max(abs(t), 1.0)
end

function summarize(label::String, raw_results, analysis, elapsed_s::Float64)
    (solutions_vector, besterror, _, _, _, _, _, _) = analysis
    n = length(solutions_vector)
    if n == 0
        @printf("  [%s] elapsed=%.1fs  N=0  (no candidates)\n", label, elapsed_s)
        return Dict(:label => label, :elapsed_s => elapsed_s, :n_sol => 0)
    end

    # Per-row data
    k10s = Float64[]
    oracles = Float64[]
    saturated_k10 = 0
    best_rank = 0
    best_oracle = Inf
    for (idx, s) in enumerate(solutions_vector)
        # Extract k10
        k10 = NaN
        for (k, v) in s.parameters
            if string(k) == "k10"
                k10 = Float64(v)
                break
            end
        end
        push!(k10s, k10)
        if k10 > 9.99
            saturated_k10 += 1
        end
        # Compute oracle (max rel err over identifiable axes; x7 is unidentifiable)
        rels = Float64[]
        for (k, v) in s.parameters
            kname = string(k)
            haskey(TRUTH_PARAMS, kname) || continue
            push!(rels, rel_err(Float64(v), TRUTH_PARAMS[kname]))
        end
        for (k, v) in s.states
            sname = string(k)[1:findlast('(', string(k))-1]
            (sname in keys(TRUTH_ICS)) || continue
            sname == "x7" && continue  # unidentifiable
            push!(rels, rel_err(Float64(v), TRUTH_ICS[sname]))
        end
        oracle = isempty(rels) ? Inf : maximum(rels)
        push!(oracles, oracle)
        if oracle < best_oracle
            best_oracle = oracle
            best_rank = idx
        end
    end

    rank1_oracle = oracles[1]
    @printf("  [%s] elapsed=%.1fs  N=%d  rank1_oracle=%.3g  best_oracle@rank%d=%.3g  k10_saturated=%d/%d\n",
        label, elapsed_s, n, rank1_oracle, best_rank, best_oracle, saturated_k10, n)
    k10_sorted = sort(k10s)
    @printf("       k10: min=%.4g, median=%.4g, max=%.4g, at_bound(≥9.99)=%d/%d\n",
        k10_sorted[1], k10_sorted[div(end+1,2)], k10_sorted[end], saturated_k10, n)
    return Dict(
        :label => label,
        :elapsed_s => elapsed_s,
        :n_sol => n,
        :rank1_oracle => rank1_oracle,
        :best_oracle => best_oracle,
        :best_rank => best_rank,
        :k10_saturated => saturated_k10,
        :besterror => besterror,
    )
end

# Run sweep
configs = [
    ("control λ_sw=0",             0.0,    0.05),
    ("λ_sw=1e-4, ε=0.05",          1e-4,   0.05),
    ("λ_sw=1e-3, ε=0.05",          1e-3,   0.05),
    ("λ_sw=1e-2, ε=0.05",          1e-2,   0.05),
    ("λ_sw=1e-1, ε=0.05",          1e-1,   0.05),
    ("λ_sw=1e-2, ε=0.10",          1e-2,   0.10),
    ("λ_sw=1e-2, ε=0.02",          1e-2,   0.02),
]

println("# Probe 2: soft-wall on biohydrogenation_6_1em6")
println("# Reduced settings: shooting_points=10, multipoint_max_pairs=5, polish_maxiters=2000")
println("# Truth: k5=0.476, k6=0.397, k7=0.107, k8=0.889, k9=0.73, k10=0.818")
println("# Truth ICs: x4=0.639, x5=0.841, x6=0.397, x7=0.421 (unobs)")
println()

results = []
for (label, lam, eps) in configs
    println("--- $label ---")
    opts = make_opts(softwall_lambda=lam, softwall_epsilon=eps)
    t0 = time()
    raw_results, analysis, _ = try
        analyze_parameter_estimation_problem(pep, opts)
    catch e
        @warn "Run failed: $e"
        (nothing, (Vector{Any}(), Inf, Inf, Inf, Inf, Inf, Inf, Inf), nothing)
    end
    elapsed = time() - t0
    r = summarize(label, raw_results, analysis, elapsed)
    push!(results, r)
    println()
end

# Final table
println("="^80)
println("# Summary:")
@printf("%-25s  %10s  %10s  %10s  %12s  %s\n",
    "config", "elapsed(s)", "N", "rank1_or", "best_oracle@", "k10_sat")
for r in results
    @printf("%-25s  %10.1f  %10d  %10.3g  %12s  %d\n",
        r[:label], r[:elapsed_s], r[:n_sol],
        get(r, :rank1_oracle, NaN),
        get(r, :best_rank, 0) == 0 ? "—" : "rank$(r[:best_rank])=$(round(r[:best_oracle], sigdigits=3))",
        get(r, :k10_saturated, 0))
end

# Write JSON
out_json = joinpath(OUT_DIR, "probe2_results.json")
open(out_json, "w") do io
    JSON.print(io, results, 2)
end
println("\nWrote $out_json")
