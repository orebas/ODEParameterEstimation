"""
Generate an exact-case block-consensus study for the benchmark-backed
`sirt_treatment_7_1em4` case, using the cached benchmark `result.csv`
candidate pool by default.
"""

using Logging
using ODEParameterEstimation

const ODEPE = ODEParameterEstimation

case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4"
isdir(case_dir) || throw(ArgumentError("Benchmark case not found at $case_dir"))

println("Running exact block-consensus study...")
artifact = with_logger(NullLogger()) do
    ODEPE._build_exact_block_study_artifact(
        case_dir;
        candidate_source = :benchmark_result_csv,
    )
end

report_path = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sirt_treatment_7_1em4", "block_consensus_study.md")
mkpath(dirname(report_path))
write(report_path, ODEPE._render_block_consensus_study_markdown(artifact))

println("Done! Report at: $report_path")
