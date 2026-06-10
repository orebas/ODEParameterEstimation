"""
Generate synthesized-finalizer benchmark report for daisy_mamil3 instance 7 (noise 1e-4).
Outputs a Markdown report comparing the raw consensus winner, best synthesized refined result,
and final selected winner from the synthesized finalizer.
"""

using CSV
using Logging
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t

const ODEPE = ODEParameterEstimation

parameters = @parameters a12 a13 a21 a31 a01
states = @variables x1(t) x2(t) x3(t)
observables = @variables y1(t) y2(t)
state_equations = [
    D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
    D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
    D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
]
measured_quantities = [y1 ~ 0.5 * x1, y2 ~ x2]
ic = [0.139, 0.303, 0.457]
p_true = [0.52, 0.7, 0.367, 0.839, 0.79]
model, mq = create_ordered_ode_system("daisy_mamil3", states, parameters, state_equations, measured_quantities)

datadir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4"
datafile = joinpath(datadir, "data.csv")
isfile(datafile) || throw(ArgumentError("Benchmark dataset not found at $datafile"))

csv_data = CSV.read(datafile, Tuple, header = false)
data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq)
    data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
end

pep = ParameterEstimationProblem(
    "daisy_mamil3",
    model,
    mq,
    data_sample,
    [0.0, 20.0],
    nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

est_opts = EstimationOptions(
    interpolator = InterpolatorAAADGPR,
    interpolators = InterpolatorMethod[],
    shooting_points = 3,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    polish_solutions = false,
    polish_solver_solutions = false,
    polish_maxiters = 20,
    polish_maxtime = 5.0,
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 4,
)

synth_opts = SynthesizedFinalizerOptions(
    base_consensus_opts = ConsensusOptions(
        strategy = :family_consensus,
        support_point_count = 4,
        support_combo_count = 4,
        refine_top_families = 1,
        do_equation_refit = false,
    ),
    max_family_seeds = 4,
    max_cross_family_seeds = 4,
    allow_cross_family_synthesis = true,
    allow_parameter_stitching = true,
    cross_family_distance_limit = 0.5,
    seed_consistency_threshold = 100.0,
    max_refine_candidates = 4,
    refine_with_full_trajectory = true,
    refine_objective_mode = :trajectory_only,
)

println("Running synthesized finalizer benchmark...")
artifact = with_logger(NullLogger()) do
    ODEPE._build_synthesized_benchmark_artifact(
        pep;
        est_opts = est_opts,
        synth_opts = synth_opts,
        dataset_label = "benchmark_bilby_2026_03_09/daisy_mamil3_7_1em4",
    )
end

report_path = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "daisy_mamil3", "synthesized_finalizer_benchmark.md")
mkpath(dirname(report_path))
write(report_path, ODEPE._render_synthesized_benchmark_markdown(artifact))

println("Done! Report at: $report_path")
