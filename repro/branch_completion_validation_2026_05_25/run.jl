# Validate branch completion ("throw out all but the top entry, compute its
# algebraic conjugates") on clean constructed M>1 cases and on the Wallaby M>=2
# systems. One full-fat run per model with branch_completion=true.
#
# For each model we report:
#   - branch-completion provenance notes (replaced / kept_original_pool / reason)
#   - number of returned rows vs expected M
#   - parameters of each returned row (eyeball vs truth / known conjugates)
using ODEParameterEstimation
using Printf

function run_one(model_fn, M)
    pep = model_fn()
    nvars = length(pep.ic) + length(pep.p_true)
    opts = EstimationOptions(
        datasize = 101,
        noise_level = 0.0,
        system_solver = SolverHC,
        flow = FlowStandard,
        use_si_template = true,
        interpolator = InterpolatorAAAD,
        interpolators = [InterpolatorAAAD],
        auto_filter_interpolators = false,
        shooting_points = 4,
        shooting_warp = true,
        shooting_warp_beta = 3.0,
        use_parameter_homotopy = true,
        use_multipoint = false,
        polish_solver_solutions = false,
        polish_solutions = false,
        synthesize_aggregate_candidates = false,  # cut extra synthesis solves; anchor is the top real solution
        terminal_fallback = :none,
        backsolve_recovery = :none,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        branch_detection = true,
        algebraic_multiplicity = M,
        branch_top_k = M,
        branch_diversity_selection = true,
        branch_completion = true,
        branch_completion_max_anchors = 1,
        opt_lb = fill(1e-5, nvars),
        opt_ub = fill(5000.0, nvars),
    )
    spep = sample_problem_data(pep, opts)
    out = analyze_parameter_estimation_problem(spep, opts)
    return pep, out[2].returned_results
end

# cheapest / highest-value first so partial progress is informative.
# Qualify with module prefix: some example constructors are not re-exported.
const OPE = ODEParameterEstimation
# Wallaby systems first (lighter, and the ones explicitly requested); the
# constructed cases (receptor mixed_volume~6400, latent M=6) are HC-heavy → last.
models = [
    ("daisy_mamil4",                    OPE.daisy_mamil4,                    2),  # wallaby M=2
    ("slowfast",                        OPE.slowfast,                        2),  # wallaby M=2 (OOB caveat)
    ("biohydrogenation",                OPE.biohydrogenation,                2),  # wallaby M=2 (OOB caveat)
    ("seir",                            OPE.seir,                            2),  # wallaby M=2 (DEGENERATE control)
    ("receptor_subtype_binding_branch", OPE.receptor_subtype_binding_branch, 2),  # clean M=2 (swap) — HEAVY
    ("latent_subpopulation_branch",     OPE.latent_subpopulation_branch,     6),  # clean M=6 (3! perms) — HEAVIEST
]

for (name, fn, M) in models
    println("\n", "="^74)
    println("MODEL: ", name, "   expected M = ", M)
    println("="^74); flush(stdout)
    t0 = time()
    try
        pep, rows = run_one(fn, M)
        elapsed = round(time() - t0, digits=1)
        println("TRUTH params: ", [(string(k), round(v, sigdigits=5)) for (k, v) in pep.p_true])
        allnotes = Symbol[]
        for r in rows, n in r.provenance.notes
            push!(allnotes, n)
        end
        bc = unique(filter(n -> occursin("branch", String(n)), allnotes))
        println("branch-completion notes: ", isempty(bc) ? "(none)" : bc)
        println(@sprintf("returned rows: %d   (expected M = %d)   [%.1fs]", length(rows), M, elapsed))
        for (i, r) in enumerate(rows)
            erv = (r.err === nothing) ? NaN : r.err
            println(@sprintf("  row %d  err=%.3e  branch_size=%d", i, erv, r.branch_size))
            println("        params: ", [(string(k), round(v, sigdigits=5)) for (k, v) in r.parameters])
        end
    catch e
        println("ERROR on ", name, " after ", round(time()-t0,digits=1), "s: ", typeof(e))
        showerror(stdout, e); println()
    end
    flush(stdout)
end
println("\nALL DONE"); flush(stdout)
