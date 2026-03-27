# benchmark_noisy.jl
# Compare single-point vs multi-point estimation accuracy across models and noise levels.
#
# Usage:
#   julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/benchmark_noisy.jl")'

using ODEParameterEstimation
using Printf
using Random

# ---- model registry (functions live inside the examples submodule) ----
include(joinpath(pkgdir(ODEParameterEstimation), "src", "examples", "load_examples.jl"))

# ---- helpers ----

function flatten_results(x)
    out = ParameterEstimationResult[]
    if x isa ParameterEstimationResult
        push!(out, x)
    elseif x isa Tuple
        for item in x
            append!(out, flatten_results(item))
        end
    elseif x isa Vector
        for item in x
            append!(out, flatten_results(item))
        end
    end
    out
end

function best_error(results)
    flat = flatten_results(results)
    errs = Float64[]
    for r in flat
        if !isnothing(r.err) && isfinite(r.err)
            push!(errs, r.err)
        end
    end
    isempty(errs) ? NaN : minimum(errs)
end

"""Run `f()` in a Task with a wall-clock timeout. Returns `f()` result or throws on timeout."""
function with_timeout(f, timeout_sec::Real)
    result_channel = Channel{Any}(1)
    task = Threads.@spawn begin
        try
            put!(result_channel, f())
        catch e
            put!(result_channel, e)
        end
    end
    timer = Timer(timeout_sec)
    @async begin
        wait(timer)
        if isopen(result_channel) && !istaskdone(task)
            # We can't truly kill a Julia task, but we'll signal timeout
            put!(result_channel, ErrorException("TIMEOUT after $(timeout_sec)s"))
        end
    end
    val = take!(result_channel)
    close(result_channel)
    if val isa Exception
        throw(val)
    end
    return val
end

# ---- configuration ----

const MODEL_NAMES = [:simple, :lotka_volterra, :fitzhugh_nagumo, :biohydrogenation, :seir]
const NOISE_LEVELS = [0.0, 0.01, 0.05]
const PER_MODEL_TIMEOUT = 300.0  # 5 minutes per (model, noise) combo

# Rows: (model, noise, single_err, multi_err, single_time, multi_time)
struct BenchRow
    model::Symbol
    noise::Float64
    single_err::Float64
    multi_err::Float64
    single_sec::Float64
    multi_sec::Float64
end

# ---- main benchmark loop ----

function run_benchmark()
    rows = BenchRow[]

    for model_name in MODEL_NAMES
        for noise in NOISE_LEVELS
            @printf(">>> %-25s noise=%.2f ... ", model_name, noise)
            flush(stdout)

            single_err = NaN
            multi_err  = NaN
            single_sec = NaN
            multi_sec  = NaN

            try
                # Build model PEP
                model_fn = ALL_MODELS[model_name]
                pep = model_fn()

                # Resolve time interval
                ti = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval

                # --- single-point estimation ---
                sp_opts = EstimationOptions(
                    datasize       = 201,
                    noise_level    = noise,
                    time_interval  = ti,
                    shooting_points = 4,
                    nooutput       = true,
                    save_system    = false,
                    diagnostics    = false,
                )
                pep_sp = sample_problem_data(pep, sp_opts)

                t0 = time()
                res_sp = with_timeout(PER_MODEL_TIMEOUT) do
                    analyze_parameter_estimation_problem(pep_sp, sp_opts)
                end
                single_sec = time() - t0
                single_err = best_error(res_sp)

                # --- multi-point estimation ---
                mp_opts = EstimationOptions(
                    use_multipoint      = true,
                    multipoint_n_points = 2,
                    multipoint_n_pairs  = 6,
                    datasize            = 201,
                    noise_level         = noise,
                    time_interval       = ti,
                    shooting_points     = 4,
                    nooutput            = true,
                    save_system         = false,
                    diagnostics         = false,
                )
                # Re-use same sampled data (same noise realisation) for fair comparison
                pep_mp = ParameterEstimationProblem(
                    pep_sp.name,
                    pep_sp.model,
                    pep_sp.measured_quantities,
                    pep_sp.data_sample,
                    pep_sp.recommended_time_interval,
                    pep_sp.solver,
                    pep_sp.p_true,
                    pep_sp.ic,
                    pep_sp.unident_count,
                )

                t0 = time()
                res_mp = with_timeout(PER_MODEL_TIMEOUT) do
                    analyze_parameter_estimation_problem(pep_mp, mp_opts)
                end
                multi_sec = time() - t0
                multi_err = best_error(res_mp)

            catch e
                @printf("FAILED: %s ", sprint(showerror, e; context=:limit=>200))
                flush(stdout)
            end

            push!(rows, BenchRow(model_name, noise, single_err, multi_err, single_sec, multi_sec))
            @printf("SP=%.6f  MP=%.6f\n", single_err, multi_err)
            flush(stdout)
        end
    end

    # ---- summary table ----
    println()
    println("=" ^ 105)
    @printf("%-22s %6s | %12s %8s | %12s %8s | %8s\n",
        "Model", "Noise", "Single-Pt", "Time(s)", "Multi-Pt", "Time(s)", "Ratio")
    println("-" ^ 105)
    for r in rows
        ratio = r.single_err / r.multi_err
        ratio_str = (isnan(ratio) || isinf(ratio)) ? "      N/A" : @sprintf("%8.2fx", ratio)
        @printf("%-22s %6.2f | %12.6f %8.1f | %12.6f %8.1f | %s\n",
            r.model, r.noise, r.single_err, r.single_sec, r.multi_err, r.multi_sec, ratio_str)
    end
    println("=" ^ 105)
    println()
    println("Ratio = Single-Pt Error / Multi-Pt Error  (>1 means multi-point is better)")

    return rows
end

# ---- entry point ----
Random.seed!(42)
rows = run_benchmark()
