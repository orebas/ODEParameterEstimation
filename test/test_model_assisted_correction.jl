using Test
using ModelingToolkit
using OrderedCollections
using ODEParameterEstimation

const ODEPE_MAC = ODEParameterEstimation

@testset "Model-assisted correction primitives" begin
    times = collect(range(0.0, 1.0; length = 31))
    alternative = @. 1.2 * exp(0.4 * times)
    interp = agp_gpr_uq(times, @. exp(0.45 * times))
    stable = ODEPE_MAC._mac_fixed_smoother_jet(interp, alternative, 0.4, 2)
    _, influence = gp_derivative_influence_matrix(interp, 0.4, 2)
    @test stable ≈ influence * alternative rtol = 2e-7 atol = 2e-9

    fn = values -> [values[1]^2 - values[2]]
    root, ok, iterations, residual = ODEPE_MAC._mac_local_newton(
        fn, [2.0], [3.61]; max_iterations = 10, tolerance = 1e-12,
    )
    @test ok
    @test iterations > 0
    @test residual <= 1e-12
    @test root[1] ≈ 1.9 atol = 1e-11
end

@testset "Model-assisted repeated-noise aggregation" begin
    include(joinpath(
        @__DIR__, "..", "repro", "uq_coverage_harness_2026_08",
        "summarize_model_assisted_replicates.jl",
    ))

    _mac_test_estimator(error) = Dict{String, Any}(
        "available" => true,
        "max_relative_error" => error,
        "coordinates" => Any[
            Dict{String, Any}(
                "role" => "parameter", "relative_error" => error,
            ),
        ],
    )
    unavailable = Dict{String, Any}("available" => false)
    function _mac_test_aggregate_record(pilot_error, raw_error; accepted)
        pilot = _mac_test_estimator(pilot_error)
        raw = _mac_test_estimator(raw_error)
        policy = accepted ? raw : pilot
        return Dict{String, Any}(
            "estimators" => Dict{String, Any}(
                "pilot" => pilot,
                "model_assisted_linear" => unavailable,
                "model_assisted_resolved" => raw,
                "model_assisted_screened" => accepted ? raw : unavailable,
                "model_assisted_screened_policy" => policy,
            ),
            "correction_screen_status" => accepted ?
                "trajectory_objective_improved" :
                "trajectory_objective_not_improved",
            "correction_total_seconds" => 0.02,
            "selected_identity" => Dict{String, Any}(
                "estimator_kind" => "single_point_algebraic",
                "time_indices" => [4],
            ),
        )
    end

    summary = _mas_group_summary(Dict{String, Any}[
        _mac_test_aggregate_record(1.0, 0.5; accepted = true),
        _mac_test_aggregate_record(2.0, 0.5; accepted = false),
    ])
    @test summary["raw_usable"] == 2
    @test summary["screen_accepts"] == 1
    @test summary["raw_truth_improvements"] == 2
    @test summary["accepted_truth_improvements"] == 1
    @test summary["false_accepts"] == 0
    @test summary["false_rejects"] == 1
    @test summary["mechanism_advances"]
    @test !summary["screened_estimator_advances"]
end

@testset "Model-assisted repeated-polish aggregation" begin
    include(joinpath(
        @__DIR__, "..", "repro", "uq_coverage_harness_2026_08",
        "summarize_model_assisted_polish.jl",
    ))

    _mac_polish_estimator(error) = Dict{String, Any}(
        "available" => true,
        "max_relative_error" => error,
        "coordinates" => Any[
            Dict{String, Any}(
                "role" => "parameter",
                "label" => "a",
                "relative_error" => error,
                "estimate" => 1.0 + error,
                "truth" => 1.0,
            ),
        ],
    )
    polish_unavailable = Dict{String, Any}("available" => false)
    function _mac_test_polish_record(order, pilot_seconds, corrected_seconds)
        pilot = _mac_polish_estimator(1.0)
        raw = _mac_polish_estimator(0.5)
        pilot_polish = _mac_polish_estimator(0.01)
        corrected_polish = _mac_polish_estimator(0.01)
        pilot_polish["elapsed_seconds"] = pilot_seconds
        corrected_polish["elapsed_seconds"] = corrected_seconds
        return Dict{String, Any}(
            "estimators" => Dict{String, Any}(
                "pilot" => pilot,
                "model_assisted_linear" => polish_unavailable,
                "model_assisted_resolved" => raw,
                "model_assisted_screened" => raw,
                "model_assisted_screened_policy" => raw,
                "polish_from_pilot" => pilot_polish,
                "polish_from_corrected" => corrected_polish,
            ),
            "correction_screen_status" => "trajectory_objective_improved",
            "polish_order" => order,
        )
    end

    polish_summary = _map_group_summary(Dict{String, Any}[
        _mac_test_polish_record(["pilot", "corrected"], 2.0, 1.0),
        _mac_test_polish_record(["corrected", "pilot"], 1.0, 2.0),
    ])
    @test polish_summary["replicates"] == 2
    @test polish_summary["screen_accepts"] == 2
    @test polish_summary["paired_polish_records"] == 2
    @test polish_summary["raw_truth_improvements"] == 2
    @test polish_summary["median_raw_prepolish_max_error_ratio"] == 0.5
    @test polish_summary["median_paired_seed_max_error_ratio"] == 0.5
    @test polish_summary["median_pilot_polish_seconds"] == 1.5
    @test polish_summary["median_corrected_polish_seconds"] == 1.5
    @test polish_summary["max_paired_polished_estimate_relative_difference"] == 0
    @test polish_summary["polish_order_counts"] ==
          Dict("pilot->corrected" => 1, "corrected->pilot" => 1)
end

@testset "Model-assisted correction on a retained SP recipe" begin
    @parameters a
    @variables t x(t) y1(t)
    D = Differential(t)
    model, measured = create_ordered_ode_system(
        "mac_exp", [x], [a], [D(x) ~ a * x], [y1 ~ x],
    )
    times = collect(range(0.0, 1.0; length = 41))
    truth_a = 0.55
    truth_x0 = 1.1
    clean = @. truth_x0 * exp(truth_a * times)
    data = OrderedDict{Union{String, Num}, Vector{Float64}}(
        Num(x) => clean,
        "t" => times,
    )
    pep = ParameterEstimationProblem(
        "mac_exp", model, measured, data, [0.0, 1.0],
        package_wide_default_ode_solver,
        OrderedDict(a => truth_a), OrderedDict(x => truth_x0), 0,
    )
    interp = agp_gpr_uq(times, clean)
    time_index = 17
    time_value = times[time_index]
    jet = ODEPE_MAC._estimation_derivative.(
        Ref(interp), 0:1, Ref(time_value),
    )

    @variables a_0 y1_0 y1_1
    equations = Num[y1_1 - a_0 * y1_0]
    root = Float64[jet[2] / jet[1]]
    artifact = ODEPE_MAC.SinglePointUQArtifact(
        equations, Any[a_0], Any[y1_0, y1_1], Float64.(jet), root,
        Dict{Num, ODEPE_MAC.AbstractInterpolator}(Num(x) => interp),
        time_index, time_value,
    )
    identity = EstimatorIdentity(
        candidate_id = 1,
        estimator_kind = :single_point_algebraic,
        data_scope = :point_set,
        time_indices = [time_index],
        time_values = [time_value],
        interpolator_source = :agp_uq,
    )
    selected = ParameterEstimationResult(
        OrderedDict(a => root[1]), OrderedDict(x => truth_x0), time_value,
        nothing, nothing, length(times), first(times), nothing, Set{Num}(),
        nothing, :agp_uq,
        ResultProvenance(
            source_shooting_index = time_index,
            source_candidate_index = 1,
            source_type = :single_point,
            interpolator_source = :agp_uq,
            estimator_identity = identity,
        ),
    )

    report = research_model_assisted_one_step(pep, selected, artifact)
    @test report.status == :resolved
    @test !isnothing(report.linear_result)
    @test !isnothing(report.resolved_result)
    @test report.screen_status == :trajectory_objective_improved
    @test !isnothing(report.screened_result)
    @test report.resolved_residual <= 1e-10
    @test report.corrected_data_values ≈
          report.observed_data_values - report.estimated_bias
    @test :uq_unavailable_pending_model_assisted_influence in
          report.resolved_result.provenance.notes
    @test report.resolved_result.provenance.estimator_identity.estimator_kind ==
          :model_assisted_local_resolve
    @test report.resolved_result.err isa Float64
    @test isfinite(report.resolved_result.err)
    corrected_identity =
        report.resolved_result.provenance.estimator_identity
    corrected_uq = ODEPE_MAC._compute_estimator_aware_uq(
        pep,
        report.resolved_result,
        UQTargetSnapshot(
            identity = corrected_identity,
            lineage = EstimatorIdentity[corrected_identity],
            artifact_match = :missing,
        ),
        EstimationOptions(compute_uncertainty = true, nooutput = true),
    )
    @test corrected_uq isa UQUnavailable
    @test corrected_uq.reason == :unsupported_estimator
    @test occursin("pilot-through-correction", corrected_uq.message)

    rejected, rejected_status, _ = ODEPE_MAC._mac_screen_corrected_result(
        report.pilot_result, report.pilot_result, nothing,
    )
    @test isnothing(rejected)
    @test rejected_status == :trajectory_objective_not_improved
    absent, absent_status, _ = ODEPE_MAC._mac_screen_corrected_result(
        report.pilot_result, nothing, nothing,
    )
    @test isnothing(absent)
    @test absent_status == :no_usable_candidate

    # Refit the retained GP after a deterministic raw-data perturbation.  This
    # is not an influence claim; it pins that the complete pilot -> smoother ->
    # correction map remains finite and locally continuous when the data move.
    perturbation = @. 1e-7 * sin(7.0 * times)
    perturbed_values = clean + perturbation
    perturbed_interp = agp_gpr_uq(times, perturbed_values)
    perturbed_jet = ODEPE_MAC._estimation_derivative.(
        Ref(perturbed_interp), 0:1, Ref(time_value),
    )
    perturbed_root = Float64[perturbed_jet[2] / perturbed_jet[1]]
    perturbed_artifact = ODEPE_MAC.SinglePointUQArtifact(
        equations, Any[a_0], Any[y1_0, y1_1], Float64.(perturbed_jet),
        perturbed_root,
        Dict{Num, ODEPE_MAC.AbstractInterpolator}(Num(x) => perturbed_interp),
        time_index, time_value,
    )
    perturbed_selected = ParameterEstimationResult(
        OrderedDict(a => perturbed_root[1]), OrderedDict(x => truth_x0),
        time_value, nothing, nothing, length(times), first(times), nothing,
        Set{Num}(), nothing, :agp_uq,
        ResultProvenance(
            source_shooting_index = time_index,
            source_candidate_index = 2,
            source_type = :single_point,
            interpolator_source = :agp_uq,
            estimator_identity = EstimatorIdentity(
                candidate_id = 2,
                estimator_kind = :single_point_algebraic,
                data_scope = :point_set,
                time_indices = [time_index],
                time_values = [time_value],
                interpolator_source = :agp_uq,
            ),
        ),
    )
    perturbed_report = research_model_assisted_one_step(
        pep, perturbed_selected, perturbed_artifact,
    )
    @test perturbed_report.status == :resolved
    @test perturbed_report.screen_status == :trajectory_objective_improved
    perturbed_a = perturbed_report.resolved_result.parameters[a]
    baseline_a = report.resolved_result.parameters[a]
    @test isfinite(perturbed_a)
    @test 0 < abs(perturbed_a - baseline_a) < 1e-3
end
