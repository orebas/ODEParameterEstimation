using Pkg; Pkg.activate({{{julia_env_path}}})

using MKL

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using BenchmarkTools
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using JSON

using GaussianProcesses
using Statistics
using Optim, LineSearches
using Symbolics: Num

name = "{{name}}"
parameters = @parameters {{#parameters}}{{varname}} {{/parameters}}
states = @variables  {{#states}}{{varname}}(t){{space}}{{/states}}
observables = @variables  {{#measurements}}{{varname}}(t){{space}}{{/measurements}}
state_equations = [
{{#components}}
    D({{state_var}}) ~ {{state_expr}},
{{/components}}
]
measured_quantities = [
{{#measured_quantities}}
    {{measurement}} ~ {{measurement_expression}},
{{/measured_quantities}}
]
ic = [{{#initial_conditions}}{{value}}{{comma}}{{/initial_conditions}}]
p_true = [{{#parameters}}{{true}}{{comma}}{{/parameters}}]

time_interval = [{{time_start}}, {{time_end}}]
datasize = {{time_count}}

model, mq = create_ordered_ode_system(
    name,
    states,
    parameters,
    state_equations,
    measured_quantities
)

# Use mq (model-consistent variables) for data_sample keys, not original measured_quantities
csv_data = CSV.read(joinpath(@__DIR__, "{{data_filepath}}"), Tuple, header=false)
data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq)
    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
end

pep = ParameterEstimationProblem(
    name,
    model,
    mq,
    data_sample,
    time_interval,
    nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

# Create EstimationOptions with desired settings
# You can customize these options based on your needs
opts = EstimationOptions(
    datasize = length(data_sample["t"]),
    noise_level = 0.000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    # 7 interpolators: mix of GP, spectral, and rational
    interpolators = [
        InterpolatorAGPRobust,        # AGP-Robust-SE
        InterpolatorS3AdaptSE,        # S3-Adapt-SE
        InterpolatorChebyshevBIC,     # Chebyshev-BIC (new spectral)
        InterpolatorS3AdaptSExRQ,     # S3-Adapt-SExRQ
        InterpolatorAGPRobustSExRQ,   # AGP-Robust-SExRQ
        InterpolatorChebyshevAICc,    # Chebyshev-AICc (new spectral)
        InterpolatorAAADGPR,          # AAAD-GPR-Pivot (default)
    ],
    # Shooting: 12 warp points clustered near t=0
    shooting_points = 12,
    shooting_warp = true,
    shooting_warp_beta = 3.0,
    # Parameter homotopy + multi-point
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 15,
    # Polishing
    polish_solver_solutions = true,
    polish_solutions = {{ODEPE_POLISH}},
    polish_maxiters = 5000,
    polish_method = PolishBFGS,
    opt_maxiters = 200000,
    opt_lb = {{lower_bound}} * ones(length(ic) + length(p_true)),
    opt_ub = {{upper_bound}} * ones(length(ic) + length(p_true)),
    abstol = 1e-13,
    reltol = 1e-13,
    polish_maxtime = {{POLISH_MAXTIME}},
    polish_divergence_factor = {{POLISH_DIVERGENCE_FACTOR}},
    polish_stagnation_window = {{POLISH_STAGNATION_WINDOW}},
    polish_ode_maxiters = {{POLISH_ODE_MAXITERS}},
    diagnostics = true,
)

function ordered_pairs_to_string_dict(items)
    out = Dict{String, Float64}()
    for (k, v) in items
        out[string(k)] = Float64(v)
    end
    return out
end

function ordered_dict_to_string_dict(items)
    out = Dict{String, Float64}()
    for (k, v) in pairs(items)
        out[string(k)] = Float64(v)
    end
    return out
end

function result_metadata(best_sol)
    provenance = best_sol.provenance
    return Dict(
        "parameters" => ordered_pairs_to_string_dict(collect(best_sol.parameters)),
        "states" => ordered_pairs_to_string_dict(collect(best_sol.states)),
        "all_unidentifiable" => [string(x) for x in best_sol.all_unidentifiable],
        "primary_method" => string(provenance.primary_method),
        "interpolator_source" => isnothing(provenance.interpolator_source) ? nothing : string(provenance.interpolator_source),
        "rescue_path" => string(provenance.rescue_path),
        "source_shooting_index" => provenance.source_shooting_index,
        "source_candidate_index" => provenance.source_candidate_index,
        "structural_fix_set" => ordered_dict_to_string_dict(provenance.structural_fix_set),
        "residual_fix_set" => ordered_dict_to_string_dict(provenance.residual_fix_set),
        "representative_assignments" => ordered_dict_to_string_dict(provenance.representative_assignments),
        "template_status_before_residual_fix" => isnothing(provenance.template_status_before_residual_fix) ? nothing : string(provenance.template_status_before_residual_fix),
        "template_status_after_residual_fix" => isnothing(provenance.template_status_after_residual_fix) ? nothing : string(provenance.template_status_after_residual_fix),
        "equations_dropped_by_rank_trimming" => provenance.equations_dropped_by_rank_trimming,
        "practical_identifiability_status" => string(provenance.practical_identifiability_status),
        "notes" => [string(x) for x in provenance.notes],
    )
end

sidecar_file = joinpath(@__DIR__, "odepe_metadata.json")
metadata = Dict{String, Any}(
    "status" => "error",
    "raw_count" => 0,
    "best_count" => 0,
)

try
    raw_results, analysis, _ = analyze_parameter_estimation_problem(
        pep,
        opts,
    )

    (solutions_vector,
        besterror,
        best_min_error,
        best_mean_error,
        best_median_error,
        best_max_error,
        best_approximation_error,
        best_rms_error) = analysis

    raw_count = (raw_results isa Tuple && length(raw_results) >= 1 && raw_results[1] isa AbstractVector) ? length(raw_results[1]) : 0
    metadata["status"] = isempty(solutions_vector) ? "no_result" : "ok"
    metadata["raw_count"] = raw_count
    metadata["best_count"] = length(solutions_vector)
    metadata["besterror"] = besterror
    metadata["best_min_error"] = best_min_error
    metadata["best_mean_error"] = best_mean_error
    metadata["best_median_error"] = best_median_error
    metadata["best_max_error"] = best_max_error
    metadata["best_approximation_error"] = best_approximation_error
    metadata["best_rms_error"] = best_rms_error

    table = merge(
        Dict((string(x) => [each.states[x] for each in solutions_vector] for x in states)),
        Dict((string(x) => [each.parameters[x] for each in solutions_vector] for x in parameters)),
    )

    result_file = joinpath(@__DIR__, "result.csv")
    CSV.write(result_file, table, header = string.(collect(keys(table))))

    println("\n" * "="^60)
    println("Parameter Estimation Complete!")
    println("="^60)
    println("\nResults saved to: ", result_file)
    println("Number of solutions found: ", length(solutions_vector))
    if !isempty(solutions_vector)
        best_sol = solutions_vector[1]
        metadata["best"] = result_metadata(best_sol)
        println("\nBest solution:")
        println("  States: ", best_sol.states)
        println("  Parameters: ", best_sol.parameters)
        println("  Error metrics:")
        println("    Best error: ", besterror)
        println("    Min error: ", best_min_error)
        println("    Mean error: ", best_mean_error)
        println("    Median error: ", best_median_error)
        println("    Max error: ", best_max_error)
        println("    Approximation error: ", best_approximation_error)
        println("    RMS error: ", best_rms_error)
    end
catch err
    metadata["status"] = "error"
    metadata["error"] = sprint(showerror, err, catch_backtrace())
    rethrow()
finally
    open(sidecar_file, "w") do io
        JSON.print(io, metadata, 4)
    end
end
