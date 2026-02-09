# Profile biohydrogenation with 500 datapoints
# Run: julia temp_plans/profile_500pts.jl

using Printf

const DATASIZE = 500

println("="^70)
println("  Profiling: Biohydrogenation with $DATASIZE datapoints")
println("="^70)

println("\nLoading packages...")
t_load = @elapsed begin
    using ODEParameterEstimation
    include(joinpath(@__DIR__, "..", "src", "examples", "load_examples.jl"))
end
@printf("Packages loaded in %.1f s\n", t_load)

# ─── Helper: format bytes ───────────────────────────────────────────
function fmt_bytes(bytes::Number)
    if bytes < 1024
        return @sprintf("%.0f B", bytes)
    elseif bytes < 1024^2
        return @sprintf("%.1f KiB", bytes / 1024)
    elseif bytes < 1024^3
        return @sprintf("%.1f MiB", bytes / 1024^2)
    else
        return @sprintf("%.2f GiB", bytes / 1024^3)
    end
end

# ─── Warmup run ─────────────────────────────────────────────────────
println("\n[1/2] Warmup run (compilation) with minimal settings...")
opts_warmup = EstimationOptions(
    max_num_points = 2,
    datasize = 50,  # Small for warmup
)
GC.gc()
warmup_stats = @timed begin
    try
        run_parameter_estimation_examples(
            models = [:biohydrogenation],
            opts = opts_warmup,
            log_dir = "/tmp/warmup_logs",
            doskip = false
        )
    catch e
        println("  Warmup completed (some errors expected)")
    end
end
@printf("  Warmup: %.1f s, %s allocated\n", warmup_stats.time, fmt_bytes(warmup_stats.bytes))

# ─── Measured run with 500 datapoints + phase profiling ─────────────
println("\n[2/2] Measured run with $DATASIZE datapoints (phase profiling enabled)...")
opts = EstimationOptions(
    max_num_points = 4,
    datasize = DATASIZE,
    profile_phases = true,  # Enable per-phase breakdown
)

GC.gc()  # Clean up before measurement

measured_stats = @timed begin
    run_parameter_estimation_examples(
        models = [:biohydrogenation],
        opts = opts,
        log_dir = "/tmp/profile_logs",
        doskip = false
    )
end

# ─── Print Results ──────────────────────────────────────────────────
println("\n" * "="^70)
println("  PROFILING RESULTS: Biohydrogenation ($DATASIZE datapoints)")
println("="^70)
@printf("  Total Time:        %.2f seconds\n", measured_stats.time)
@printf("  Total Allocations: %s\n", fmt_bytes(measured_stats.bytes))
@printf("  GC Time:           %.2f seconds (%.1f%%)\n",
    measured_stats.gctime, 100 * measured_stats.gctime / max(measured_stats.time, 0.001))
println("="^70)

# Show the log file for phase details
println("\n  Full output + phase breakdown in: /tmp/profile_logs/biohydrogenation.log")
println("\nPhase breakdown should be printed above by the estimation code.")
