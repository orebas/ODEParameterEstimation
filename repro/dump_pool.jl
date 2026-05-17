# Dump the pre-polish candidate pool for sirt_treatment_0_1em8 so we can analyze
# clustering behavior — especially whether the current uniform 0.1% rel-dist
# threshold over-clusters along weakly-identified directions.
#
# Mirrors repro_sirt_treatment_0_1em8/script.jl but with:
#   • polish_solutions = false                 (fast — no LSO LM)
#   • multipoint_max_pairs = 5                 (instead of 15, keep modest)
#   • diagnostics  = true (so [MULTIPOINT] / source_type / err are visible)
#
# Outputs:
#   repro/pool_dump.csv  — one row per candidate with provenance + (params, ic) + err
#   repro/pool_dump.json — same data but with cluster summary & per-axis stats

using Pkg
Pkg.activate(raw"$(JULIA_ODEPE_ENV)"; io=devnull)

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using JSON
using Statistics
using Symbolics: Num

const REPRO = joinpath(@__DIR__, "repro_sirt_treatment_0_1em8")
@assert isdir(REPRO) "Expected $(REPRO) to exist (untar repro_sirt_treatment_0_1em8.tar.gz first)"

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
p_truth = vcat(ic, p_true)  # IC then params
p_truth_names = ["In", "Npop", "S", "Tr", "a", "b", "d", "g", "nu"]

time_interval = [0.0, 10.0]
datasize = 750

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

opts = EstimationOptions(
    datasize = length(data_sample["t"]),
    noise_level = 0.000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    shooting_points = 20,
    shooting_warp = true,
    shooting_warp_beta = 3.0,
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 5,            # reduced from 15
    polish_solver_solutions = true,
    polish_solutions = false,            # *** the point of this script ***
    polish_method = PolishLSOBoundedLog,
    opt_lb = 1e-05 * ones(length(ic) + length(p_true)),
    opt_ub = 10.0 * ones(length(ic) + length(p_true)),
    abstol = 1e-12,
    reltol = 1e-12,
    diagnostics = true,
)

t_start = time()
raw_results, analysis, _ = analyze_parameter_estimation_problem(pep, opts)
elapsed = time() - t_start

(solutions_vector, besterror, _, _, _, _, _, _) = analysis

println("\n" * "="^60)
println("Pool-dump complete in $(round(elapsed; digits=1))s")
println("Solutions in pool: $(length(solutions_vector))")
println("Best error: $besterror")
println("="^60)

# ── Build flat table ─────────────────────────────────────────────────────────
state_keys = [string(s) for s in states]
param_keys = [string(p) for p in parameters]
all_keys = vcat(state_keys, param_keys)

rows = NamedTuple[]
for (i, sol) in enumerate(solutions_vector)
    states_dict = Dict(string(k) => Float64(v) for (k, v) in sol.states)
    params_dict = Dict(string(k) => Float64(v) for (k, v) in sol.parameters)
    prov = sol.provenance
    row = (
        i = i,
        err = isnothing(sol.err) ? NaN : Float64(sol.err),
        source_type = string(prov.source_type),
        primary_method = string(prov.primary_method),
        interpolator = isnothing(prov.interpolator_source) ? "" : string(prov.interpolator_source),
        rescue = string(prov.rescue_path),
        sp_idx = isnothing(prov.source_shooting_index) ? -1 : prov.source_shooting_index,
        cand_idx = isnothing(prov.source_candidate_index) ? -1 : prov.source_candidate_index,
        agg_strategy = string(prov.aggregation_strategy),
        mp_combo = isnothing(prov.multipoint_combo_index) ? -1 : prov.multipoint_combo_index,
        # values
        ((Symbol(k) => get(states_dict, k, get(params_dict, k, NaN))) for k in all_keys)...,
    )
    push!(rows, row)
end

# CSV
csv_path = joinpath(@__DIR__, "pool_dump.csv")
open(csv_path, "w") do io
    header = vcat(["i", "err", "source_type", "primary_method", "interpolator",
                    "rescue", "sp_idx", "cand_idx", "agg_strategy", "mp_combo"],
                   all_keys)
    println(io, join(header, ","))
    for r in rows
        vals = []
        for h in header
            v = r[Symbol(h)]
            push!(vals, v isa Number ? string(v) : "\"$(v)\"")
        end
        println(io, join(vals, ","))
    end
end
println("Wrote $csv_path with $(length(rows)) rows")

# ── Per-axis spread relative to truth ────────────────────────────────────────
println("\nPer-axis spread (min, max, mean ± std, rel.spread vs truth):")
println("  axis  truth  min  max  rel.spread")
for (k, t_val) in zip(all_keys, p_truth)
    vals = [r[Symbol(k)] for r in rows]
    finite_vals = filter(isfinite, vals)
    isempty(finite_vals) && continue
    vmin = minimum(finite_vals)
    vmax = maximum(finite_vals)
    rspread = (vmax - vmin) / max(abs(t_val), 1.0)
    println(@sprintf("  %5s  %.4f  %.4f  %.4f  %.4f", k, t_val, vmin, vmax, rspread))
end

# ── Naive 0.1% rel-dist clustering exactly as polish does ────────────────────
function cluster(rows, all_keys, threshold)
    n = length(rows)
    cluster_reps = Int[]
    cluster_id = zeros(Int, n)
    for i in 1:n
        merged = false
        ri = [rows[i][Symbol(k)] for k in all_keys]
        all(isfinite, ri) || (cluster_id[i] = 0; continue)
        for (k_idx, rep) in enumerate(cluster_reps)
            rj = [rows[rep][Symbol(k)] for k in all_keys]
            dist = 0.0
            for j in eachindex(ri)
                a = ri[j]; b = rj[j]
                scale = max(abs(a), abs(b), 1.0)
                dist = max(dist, abs(a - b) / scale)
            end
            if dist <= threshold
                cluster_id[i] = k_idx
                merged = true
                break
            end
        end
        if !merged
            push!(cluster_reps, i)
            cluster_id[i] = length(cluster_reps)
        end
    end
    return cluster_reps, cluster_id
end

for thresh in (0.001, 0.01, 0.05, 0.1, 0.25)
    reps, ids = cluster(rows, all_keys, thresh)
    println("Threshold $(thresh):  $(length(reps)) cluster reps from $(length(rows)) candidates")
end

# ── Dump JSON with all the above for downstream analysis ────────────────────
json_path = joinpath(@__DIR__, "pool_dump.json")
summary = Dict(
    "elapsed_s" => elapsed,
    "n_solutions" => length(solutions_vector),
    "best_error" => besterror,
    "truth" => Dict(zip(all_keys, p_truth)),
    "rows" => [Dict(string(k) => v isa AbstractString ? v : Float64(v) for (k, v) in pairs(r)) for r in rows],
)
open(json_path, "w") do io
    JSON.print(io, summary, 2)
end
println("Wrote $json_path")
