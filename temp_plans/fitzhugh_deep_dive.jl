"""
Deep-dive investigation of fitzhugh_nagumo_2_1em4 polish=OFF.

Phases:
- D1: Run diagnose(pep) — existing diagnostic framework
- D2: Pool composition deep-dive — walk every candidate, print provenance + rel-err + loss
- D3: Cross-interpolator derivative grid — at the actual shooting points
- D4: ODE eigenvalue / timescale analysis — does the [0,1] window resolve the slow mode?
- D5: Algebraic system at truth — ‖F(x_truth, d_obs)‖ and Jacobian condition
- D6: Sloppy-direction perturbation — does L(x) flatten along sloppy directions?

D7 and D8 live in separate scripts (counterfactual sweep, manual SI inspection).

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/fitzhugh_deep_dive.jl")'
"""

using CSV
using Logging
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Random
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Statistics
using Printf

const ODEPE = ODEParameterEstimation

const OUTDIR = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "fitzhugh_deep_dive")
mkpath(OUTDIR)

# ─── Case loading ──────────────────────────────────────────────────────────────────

function _load_bilby_data(case_dir::AbstractString, mq)
    datafile = joinpath(case_dir, "data.csv")
    isfile(datafile) || error("Benchmark dataset not found at $datafile")
    csv_data = CSV.read(datafile, Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

function build_fitzhugh_nagumo_pep()
    parameters = @parameters g a b
    states = @variables Vm(t) R(t)
    observables = @variables y1(t)
    state_equations = [
        D(Vm) ~ (-3.0) * g * (0.5 * R - 2.0 * Vm + (2.6666666666666665) * (Vm^3)),
        D(R) ~ (-0.4 * a - 2.0 * Vm + 0.2 * b * R) / (3.0 * g),
    ]
    measured_quantities = [y1 ~ -2.0 * Vm]
    ic = [0.42, 0.404]
    p_true = [0.779, 0.849, 0.887]
    model, mq = ODEPE.create_ordered_ode_system("fitzhugh_nagumo", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "fitzhugh_nagumo_2_1em4",
        model, mq, data_sample, [0.0, 1.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

# ─── D1: existing diagnose() framework ─────────────────────────────────────────────

const SKIP_D1 = get(ENV, "SKIP_D1", "0") == "1"

pep = build_fitzhugh_nagumo_pep()

function _get_param(d, name)
    for (k, v) in d
        string(k) == name && return Float64(v)
    end
    return NaN
end
function _get_state(d, name)
    for (k, v) in d
        string(k) == name && return Float64(v)
    end
    return NaN
end

if !SKIP_D1
println("\n", "="^72)
println("D1: diagnose(pep) — existing diagnostic framework")
println("="^72)

@printf("Truth params: g=%.4g, a=%.4g, b=%.4g\n",
    _get_param(pep.p_true, "g"), _get_param(pep.p_true, "a"), _get_param(pep.p_true, "b"))
@printf("Truth states: Vm=%.4g, R=%.4g\n",
    _get_state(pep.ic, "Vm(t)"), _get_state(pep.ic, "R(t)"))

println("Running diagnose() ... (this generates HTML/CSV reports under artifacts/diagnostics/fitzhugh_nagumo_2_1em4/)")
diag_elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep; save_to_disk = true, html_report = true)
    end
end
println("diagnose() ran in $(round(diag_elapsed; digits=1))s")

# Summarize key sections
println("\n--- D1 summary ---")
if hasfield(typeof(diag_report), :difficulty)
    println("Difficulty:    $(diag_report.difficulty)")
end
if hasfield(typeof(diag_report), :bottleneck)
    println("Bottleneck:    $(diag_report.bottleneck)")
end

# Check derivative accuracy
if hasfield(typeof(diag_report), :derivative_accuracy) && !isnothing(diag_report.derivative_accuracy)
    da = diag_report.derivative_accuracy
    if hasfield(typeof(da), :worst_rel_error)
        @printf("Worst derivative rel-err:        %.4g\n", da.worst_rel_error)
    end
    if hasfield(typeof(da), :worst_obs) && hasfield(typeof(da), :worst_order)
        println("Worst at:                        obs=$(da.worst_obs), order=$(da.worst_order)")
    end
end

# Check polynomial feasibility
if hasfield(typeof(diag_report), :polynomial_feasibility) && !isnothing(diag_report.polynomial_feasibility)
    pf = diag_report.polynomial_feasibility
    if hasfield(typeof(pf), :n_solutions_perfect)
        println("HC solutions (perfect data):     $(pf.n_solutions_perfect)")
    end
    if hasfield(typeof(pf), :n_solutions_production)
        println("HC solutions (production data):  $(pf.n_solutions_production)")
    end
    if hasfield(typeof(pf), :is_square)
        println("Square system?                   $(pf.is_square)")
    end
end

# Check sensitivity
if hasfield(typeof(diag_report), :sensitivity) && !isnothing(diag_report.sensitivity)
    sr = diag_report.sensitivity
    if hasfield(typeof(sr), :jacobian_cond)
        @printf("∂F/∂x condition number:          %.4g\n", sr.jacobian_cond)
    end
    if hasfield(typeof(sr), :effective_rank)
        println("Effective rank:                  $(sr.effective_rank)")
    end
end

println("\nFull HTML report: artifacts/diagnostics/fitzhugh_nagumo_2_1em4/report.html")
end  # if !SKIP_D1

# ─── D2: pool composition deep-dive ────────────────────────────────────────────────

println("\n", "="^72)
println("D2: Pool composition deep-dive")
println("="^72)

opts = EstimationOptions(
    interpolator = InterpolatorAAADGPR,
    interpolators = InterpolatorMethod[],
    shooting_points = 3,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    polish_solutions = false,
    polish_solver_solutions = false,
    polish_maxiters = 50,
    polish_maxtime = 30.0,
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 4,
    max_solutions = 30,
    use_sensitivity_seeds = false,
)

println("Re-running pipeline to capture pool ...")
pool_elapsed = @elapsed begin
    results = with_logger(NullLogger()) do
        ODEPE.analyze_parameter_estimation_problem(pep, opts)
    end
end
pool = results[1][1]
ctx = ODEPE._build_polish_context(pep; opts = opts)
println("Captured pool: $(length(pool)) candidates in $(round(pool_elapsed; digits=1))s")

truth = OrderedDict{Any, Any}()
for (k, v) in pep.p_true; truth[k] = v; end
for (k, v) in pep.ic; truth[k] = v; end

function _max_rel_err(c, truth)
    estimated = OrderedDict{Any, Any}()
    for (k, v) in c.parameters; estimated[k] = v; end
    for (k, v) in c.states; estimated[k] = v; end
    rels = Float64[]
    for (sym, true_val) in truth
        haskey(estimated, sym) || continue
        est_val = Float64(estimated[sym])
        tv = Float64(true_val)
        push!(rels, abs(tv) > 1e-12 ? abs(est_val - tv) / abs(tv) : abs(est_val - tv))
    end
    return isempty(rels) ? NaN : maximum(rels)
end

function _candidate_loss(c, ctx)
    try
        state_lookup = Dict{String, Float64}(string(k) => Float64(v) for (k, v) in c.states)
        param_lookup = Dict{String, Float64}(string(k) => Float64(v) for (k, v) in c.parameters)
        ic_vec = Float64[get(state_lookup, string(s), NaN) for s in ctx.unknown_syms]
        p_vec = Float64[get(param_lookup, string(p), NaN) for p in ctx.param_syms]
        any(isnan, ic_vec) && return NaN
        any(isnan, p_vec) && return NaN
        p_external = vcat(ic_vec, p_vec)
        if !isnothing(ctx.lb) && !isnothing(ctx.ub)
            p_external = clamp.(p_external, ctx.lb, ctx.ub)
        end
        p_internal = ODEPE._polish_external_to_internal(
            p_external, ctx.coordinate_transforms, ctx.coordinate_shifts,
        )
        return Float64(ctx.optf.f(p_internal, nothing))
    catch
        return NaN
    end
end

# Walk pool, collect rows
pool_rows = []
for (i, c) in enumerate(pool)
    g_v = _get_param(c.parameters, "g")
    a_v = _get_param(c.parameters, "a")
    b_v = _get_param(c.parameters, "b")
    Vm_v = _get_state(c.states, "Vm(t)")
    R_v = _get_state(c.states, "R(t)")

    rel = _max_rel_err(c, truth)
    loss = _candidate_loss(c, ctx)

    src = isnothing(c.provenance) ? :unknown : c.provenance.source_type
    sp_idx = isnothing(c.provenance) ? nothing : c.provenance.source_shooting_index
    interp = isnothing(c.provenance) ? nothing : c.provenance.interpolator_source
    mp_idx = isnothing(c.provenance) ? nothing : c.provenance.multipoint_combo_index
    mp_times = isnothing(c.provenance) ? nothing : c.provenance.multipoint_time_indices

    push!(pool_rows, (
        idx = i,
        src = src,
        sp_idx = sp_idx,
        interp = interp,
        mp_idx = mp_idx,
        mp_times = mp_times,
        g = g_v,
        a = a_v,
        b = b_v,
        Vm = Vm_v,
        R = R_v,
        rel = rel,
        loss = loss,
    ))
end

# Print table sorted by rel-err
println("\nPool sorted by rel-err (best first):")
@printf("%-3s %-15s %-3s %-25s %-3s %-25s %-8s %-8s %-8s %-8s %-8s %-10s %-10s\n",
    "idx", "src", "sp", "interp", "mp", "mp_times", "g", "a", "b", "Vm", "R", "rel", "loss")
for r in sort(pool_rows; by = x -> isfinite(x.rel) ? x.rel : Inf)
    @printf("%-3d %-15s %-3s %-25s %-3s %-25s %-8.4g %-8.4g %-8.4g %-8.4g %-8.4g %-10.4g %-10.4g\n",
        r.idx, string(r.src),
        isnothing(r.sp_idx) ? "-" : string(r.sp_idx),
        isnothing(r.interp) ? "-" : string(r.interp),
        isnothing(r.mp_idx) ? "-" : string(r.mp_idx),
        isnothing(r.mp_times) ? "-" : string(r.mp_times),
        r.g, r.a, r.b, r.Vm, r.R, r.rel, r.loss,
    )
end

# Print sorted by loss
println("\nPool sorted by trajectory loss (best first):")
@printf("%-3s %-15s %-3s %-8s %-8s %-8s %-10s %-10s\n",
    "idx", "src", "sp", "g", "a", "b", "rel", "loss")
for r in sort(pool_rows; by = x -> isfinite(x.loss) ? x.loss : Inf)
    @printf("%-3d %-15s %-3s %-8.4g %-8.4g %-8.4g %-10.4g %-10.4g\n",
        r.idx, string(r.src),
        isnothing(r.sp_idx) ? "-" : string(r.sp_idx),
        r.g, r.a, r.b, r.rel, r.loss,
    )
end

finite_rel = filter(r -> isfinite(r.rel), pool_rows)
finite_loss = filter(r -> isfinite(r.loss), pool_rows)
println("\nBest-by-rel-err idx: $(isempty(finite_rel) ? "n/a" : finite_rel[argmin([r.rel for r in finite_rel])].idx)")
println("Best-by-loss idx:    $(isempty(finite_loss) ? "n/a" : finite_loss[argmin([r.loss for r in finite_loss])].idx)")

# Save D2 output as markdown
io = IOBuffer()
println(io, "# fitzhugh_nagumo_2_1em4 — Pool deep-dive (D2)")
println(io)
println(io, "Truth: g=0.779, a=0.849, b=0.887, Vm=0.42, R=0.404")
println(io, "Pool size: $(length(pool))")
println(io)
println(io, "## Sorted by max-rel-err (best first)")
println(io)
println(io, "| idx | src | sp | interp | mp | mp_times | g | a | b | Vm | R | rel | loss |")
println(io, "|---:|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|")
for r in sort(pool_rows; by = x -> isfinite(x.rel) ? x.rel : Inf)
    println(io, "| $(r.idx) | $(r.src) | $(isnothing(r.sp_idx) ? "—" : r.sp_idx) | $(isnothing(r.interp) ? "—" : r.interp) | $(isnothing(r.mp_idx) ? "—" : r.mp_idx) | $(isnothing(r.mp_times) ? "—" : r.mp_times) | $(round(r.g; sigdigits=4)) | $(round(r.a; sigdigits=4)) | $(round(r.b; sigdigits=4)) | $(round(r.Vm; sigdigits=4)) | $(round(r.R; sigdigits=4)) | $(round(r.rel; sigdigits=4)) | $(round(r.loss; sigdigits=4)) |")
end
write(joinpath(OUTDIR, "pool_breakdown.md"), String(take!(io)))
println("\nWrote $(joinpath(OUTDIR, "pool_breakdown.md"))")

println("\nD1+D2 done.")

# ─── D4: ODE timescale analysis ─────────────────────────────────────────────────────

println("\n", "="^72)
println("D4: ODE Jacobian eigenvalues / timescales at truth (t=0)")
println("="^72)

# Manually evaluate the ODE Jacobian at truth at t=0.
# F(Vm, R; g, a, b):
# dVm/dt = -3.0 * g * (0.5 * R - 2.0 * Vm + (8/3) * Vm^3)
# dR/dt = (-0.4 * a - 2.0 * Vm + 0.2 * b * R) / (3.0 * g)
let
    g_t = _get_param(pep.p_true, "g")
    a_t = _get_param(pep.p_true, "a")
    b_t = _get_param(pep.p_true, "b")
    Vm0 = _get_state(pep.ic, "Vm(t)")
    R0 = _get_state(pep.ic, "R(t)")

    # Jacobian of (dVm, dR) w.r.t. (Vm, R) at (Vm0, R0) with truth params:
    # ∂(dVm)/∂Vm = -3 * g * (-2 + 8 * Vm^2)         = -3g(-2 + 8Vm^2)
    # ∂(dVm)/∂R  = -3 * g * 0.5                     = -1.5g
    # ∂(dR)/∂Vm  = -2 / (3g)
    # ∂(dR)/∂R   = 0.2 * b / (3g)                   = b/(15g)
    J = [
        -3 * g_t * (-2 + 8 * Vm0^2)   -1.5 * g_t;
        -2 / (3 * g_t)                 b_t / (15 * g_t);
    ]
    println("Jacobian at (Vm=$Vm0, R=$R0; g=$g_t, a=$a_t, b=$b_t):")
    println("  ", J[1, :])
    println("  ", J[2, :])

    eigvals_J = eigvals(J)
    println("Eigenvalues:           ", eigvals_J)
    timescales = 1 ./ abs.(real(eigvals_J))
    println("Timescales (1/|Re λ|): ", round.(timescales; sigdigits=4))
    println("tspan:                 [0.0, 1.0]")
    println("Slowest mode period:   ~$(round(2π / minimum(abs.(imag.(eigvals_J)) .+ eps()); sigdigits=3)) (if oscillatory)")
    @printf("Stiffness ratio:       %.4g\n", maximum(timescales) / minimum(timescales))

    # Trajectory dynamic range over [0,1]
    t_vec = pep.data_sample["t"]
    y1_vec = let
        # find the y1 column key (Symbolics.Num)
        found = nothing
        for (k, v) in pep.data_sample
            k isa String && continue
            found = v
            break
        end
        found
    end
    if !isnothing(y1_vec)
        @printf("y1(t) over data: min=%.4g, max=%.4g, range=%.4g, |mean|=%.4g\n",
            minimum(y1_vec), maximum(y1_vec), maximum(y1_vec) - minimum(y1_vec), abs(mean(y1_vec)))
        @printf("y1(0)=%.4g, y1(end)=%.4g, y1(t≈0.183)=%.4g, y1(t≈1)=%.4g\n",
            y1_vec[1], y1_vec[end],
            y1_vec[min(275, length(y1_vec))],
            y1_vec[min(1501, length(y1_vec))])
        n_samples = length(y1_vec)
        println("Time vector: $(n_samples) samples, dt=$(round(t_vec[2]-t_vec[1]; sigdigits=4))")
    end
end


# ─── D5: Trajectory loss at truth (sanity check) ───────────────────────────────────
println("\n", "="^72)
println("D5: Trajectory loss at TRUTH (sanity check — does truth fit the data?)")
println("="^72)

let
    # Build a fake candidate at truth and evaluate its loss via polish_ctx
    truth_params = OrderedDict{Symbolics.Num, Float64}()
    for (k, v) in pep.p_true
        truth_params[k] = Float64(v)
    end
    truth_states = OrderedDict{Symbolics.Num, Float64}()
    for (k, v) in pep.ic
        truth_states[k] = Float64(v)
    end

    truth_candidate = ODEPE.ParameterEstimationResult(
        truth_params, truth_states, 0.0, nothing, nothing, 0, 0.0,
        OrderedDict{Symbolics.Num, Float64}(), Set{Symbolics.Num}(), nothing,
    )

    truth_loss = _candidate_loss(truth_candidate, ctx)
    @printf("L(x_truth) = %.4g  (loss at the actual truth)\n", truth_loss)
    @printf("L(x_pool_best=idx 3, b=7.15) = %.4g  (loss at the fit-best pool member)\n",
        sort(pool_rows; by = x -> isfinite(x.loss) ? x.loss : Inf)[1].loss)
    @printf("L(idx 11, b=−9.88) = %.4g  (a far-from-truth pool member)\n",
        let
            idx_11 = findfirst(r -> r.idx == 11, pool_rows)
            isnothing(idx_11) ? NaN : pool_rows[idx_11].loss
        end)

    # If L(x_truth) << L(x_pool_best), polish from truth would converge to truth — but the pool
    # doesn't contain truth-near. If L(x_truth) >> L(x_pool_best), even truth doesn't fit the
    # noisy data, suggesting the data noise is the dominant issue.
    println("\nInterpretation:")
    println("  - L(x_truth) tells us if truth is the actual minimum of the trajectory loss.")
    println("  - L(x_pool_best) tells us how well the polynomial pool's best candidate fits.")
    println("  - If L(x_truth) ≈ L(x_pool_best), the noisy data has 'voted for' a non-truth minimum.")
    println("  - If L(x_truth) >> L(x_pool_best), polish would NOT find truth even from a good seed.")
end

# ─── D6: Sloppy-direction perturbation at truth ─────────────────────────────────────
println("\n", "="^72)
println("D6: Probe along the dominant sloppy direction at TRUTH (does loss flatten?)")
println("="^72)

println("(Skipping the symbolic SI-template construction step; relying on diagnose() output.)")
println("From sensitivity.csv: σ_1=1087.6, σ_14=9.6e-4 → cond=1.13e6.")
println("σ_14's right singular vector is the most-sloppy direction. We don't have it from the")
println("script; would require re-extracting from SensitivityReport. TODO: pull from in-memory")
println("diagnose_report and perturb truth along it.")

println("\nDEEP_DIVE_DONE")
