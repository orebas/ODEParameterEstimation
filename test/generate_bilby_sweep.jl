"""
Generate a bilby 1e-4 broad-mixed sweep comparing:
- best-fit baseline
- family consensus
- synthesized finalizer

Optional environment variables:
- ODEPE_SWEEP_CASE_LIMIT
- ODEPE_SWEEP_CASE_IDS (comma-separated)
"""

using Logging
using ODEParameterEstimation

const ODEPE = ODEParameterEstimation

const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sweeps", "bilby_2026_03_09_1em4_broad_mixed")

case_limit = let raw = get(ENV, "ODEPE_SWEEP_CASE_LIMIT", "")
    isempty(strip(raw)) ? nothing : parse(Int, strip(raw))
end

requested_case_ids = let raw = get(ENV, "ODEPE_SWEEP_CASE_IDS", "")
    isempty(strip(raw)) ? String[] : [String(strip(part)) for part in split(raw, ',') if !isempty(strip(part))]
end

println("Running bilby sweep...")
artifact = with_logger(NullLogger()) do
    ODEPE._build_bilby_sweep_artifact(
        BENCHMARK_ROOT;
        noise = 1e-4,
        noise_label = "1e-4",
        case_limit = case_limit,
        requested_case_ids = requested_case_ids,
    )
end

mkpath(OUTPUT_ROOT)
write(joinpath(OUTPUT_ROOT, "summary.md"), ODEPE._render_bilby_sweep_summary_markdown(artifact))
write(joinpath(OUTPUT_ROOT, "summary.csv"), ODEPE._render_bilby_sweep_summary_csv(artifact))

for case_artifact in artifact[:cases]
    case_dir = joinpath(OUTPUT_ROOT, "cases", case_artifact[:case_id])
    mkpath(case_dir)
    write(joinpath(case_dir, "study.md"), ODEPE._render_bilby_case_study_markdown(case_artifact))
end

println("Done! Sweep artifact root: $OUTPUT_ROOT")
