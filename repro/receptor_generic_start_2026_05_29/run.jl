# Receptor (receptor_subtype_binding_branch) end-to-end recovery with the three requested knobs:
#   homotopy_tracking_mode = :generic_start  -> ab-initio: solve ONCE at a generic complex p0 (full
#                                               count N), then fan out to every real point via
#                                               γ-straight tracking. (This single mode == "generic
#                                               start" AND "straight line"; see homotopy_continuation.jl:1109.)
#   use_column_scaling     = true            -> data-driven per-order column rescaling of the HC system.
#   polish_solutions       = true            -> LSO polish; runs polish_max_concurrency = nthreads()
#                                               tasks in parallel, so this is what uses the 10 cores.
#
# NO OUTPUT SUPPRESSION, by deliberate choice:
#   nooutput=false, diagnostics=true, hc_show_progress=true; NO redirect_stdout/NullLogger/@suppress;
#   global Julia environment (NO Pkg.activate(; io=devnull)). Everything streams to stdout (tee'd to run.log).
#
# Oracle data (noise_level=0.0) so this is a clean test of whether :generic_start finds the truth,
# uncontaminated by noise — directly comparable to the prior :gamma_straight e2e that failed
# (besterror 13.85, spurious roots via branch_completion).
#
# Run (10 cores, no time limit — launched in background):
#   julia --startup-file=no --threads=10 repro/receptor_generic_start_2026_05_29/run.jl 2>&1 | tee run.log

using ODEParameterEstimation, OrdinaryDiffEq, ModelingToolkit, OrderedCollections, Printf
const OPE = ODEParameterEstimation

const OUTDIR = @__DIR__
const PARAMS = ["R1tot", "R2tot", "kon1", "kon2", "koff1", "koff2"]
const TRUTH  = Dict("R1tot"=>1.10, "R2tot"=>0.70, "kon1"=>0.80, "kon2"=>1.30, "koff1"=>0.40, "koff2"=>0.60)
const SWAP   = Dict("R1tot"=>0.70, "R2tot"=>1.10, "kon1"=>1.30, "kon2"=>0.80, "koff1"=>0.60, "koff2"=>0.40)

println("="^78)
println("RECEPTOR e2e  |  generic_start + column scaling + γ-straight  |  NO suppression")
println("threads available (= polish concurrency / HC tracking) : ", Threads.nthreads())
println("started: ", Libc.strftime(time()))
println("="^78); flush(stdout)

pep = OPE.receptor_subtype_binding_branch()
n_unknown = length(PARAMS) + 3   # 6 params + 3 states (L, Ca, Cb)

opts = EstimationOptions(
    datasize               = 201,            # plenty of points for the high-order receptor jets
    noise_level            = 0.0,            # oracle data
    system_solver          = SolverHC,
    flow                   = FlowStandard,
    use_si_template        = true,
    use_parameter_homotopy = true,           # the path on which homotopy_tracking_mode applies
    use_column_scaling     = true,           # *** requested ***
    homotopy_tracking_mode = :generic_start, # *** requested (generic start + γ-straight fan-out) ***
    use_multipoint         = true,
    multipoint_n_points    = 2,
    branch_completion      = true,
    polish_solutions       = true,           # *** parallel polish uses the 10 cores ***
    polish_method          = PolishLSOBoundedLog,
    opt_lb                 = 1e-5 .* ones(n_unknown),
    opt_ub                 = 10.0 .* ones(n_unknown),
    abstol                 = 1e-12,
    reltol                 = 1e-12,
    # --- OUTPUT: explicitly NOT suppressed ---
    nooutput               = false,
    diagnostics            = true,
    hc_show_progress       = true,
)

println("\n--- requested knobs (echoed) ---")
println("  homotopy_tracking_mode = ", opts.homotopy_tracking_mode)
println("  use_column_scaling     = ", opts.use_column_scaling)
println("  polish_solutions       = ", opts.polish_solutions, "  (polish_maxtime/solution = ", opts.polish_maxtime, "s)")
println("  datasize / noise_level = ", opts.datasize, " / ", opts.noise_level)
println("--------------------------------\n"); flush(stdout)

spep = sample_problem_data(pep, opts)

t_start = time()
raw_results, analysis, _ = analyze_parameter_estimation_problem(spep, opts)
elapsed = time() - t_start

(solutions_vector, besterror, best_min, best_mean, best_median, best_max, best_approx, best_rms) = analysis

println("\n" * "="^78)
@printf("DONE in %.1f s  |  pool size = %d  |  besterror = %.6g\n", elapsed, length(solutions_vector), besterror)
@printf("  (min=%.4g mean=%.4g median=%.4g max=%.4g rms=%.4g)\n",
        best_min, best_mean, best_median, best_max, best_rms)
println("  truth = R1tot,R2tot,kon1,kon2,koff1,koff2 = 1.10,0.70,0.80,1.30,0.40,0.60")
println("  (estimated-vs-true comparison is printed above by the diagnostics=true pipeline)")
println("="^78); flush(stdout)

# Durable one-line result (crash-proof tail — never blocks the headline above)
try
    open(joinpath(OUTDIR, "result.txt"), "w") do io
        @printf(io, "besterror=%.8g\nelapsed_s=%.1f\npool=%d\nthreads=%d\nmode=generic_start\ncolumn_scaling=true\npolish=true\n",
                besterror, elapsed, length(solutions_vector), Threads.nthreads())
    end
    println("wrote ", joinpath(OUTDIR, "result.txt"))
catch e
    println("could not write result.txt: ", e)   # printed, never silently swallowed
end
