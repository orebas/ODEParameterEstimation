using Test
using TOML

include(joinpath(@__DIR__, "..", "repro", "uq_coverage_harness_2026_08",
    "run_audited_repeated_uq.jl"))
include(joinpath(@__DIR__, "..", "repro", "uq_coverage_harness_2026_08",
    "supervise_audited_repeated_uq.jl"))
include(joinpath(@__DIR__, "..", "repro", "uq_coverage_harness_2026_08",
    "summarize_audited_repeated_uq.jl"))

@testset "audited repeated-UQ campaign contracts" begin
    manifest = TOML.parsefile(joinpath(
        @__DIR__, "..", "repro", "uq_coverage_harness_2026_08",
        "audited_campaign_manifest_v1.toml",
    ))
    @test manifest["peb_frozen_sha"] == PEB_FROZEN_SHA
    @test manifest["h1"]["data_source"] == "frozen_noisy"
    @test manifest["n60_prepared_not_authorized"]["replicates"] == 60

    @test _aruq_cell_seed("case_a", 8164101) ==
        _aruq_cell_seed("case_a", 8164101)
    @test _aruq_cell_seed("case_a", 8164101) !=
        _aruq_cell_seed("case_b", 8164101)
    @test _aruq_cell_seed("case_a", 8164101) !=
        _aruq_cell_seed("case_a", 8164102)

    recipe = ODEParameterEstimation.FixedMultipointRecipe(
        [25, 635]; interpolator_source = :agp_uq,
    )
    config = _aruq_config(
        "lotka_volterra_5_1em6", "mp_solver_polish", "uq_only",
        "synthetic", 1e-6, 8164101, 20, 15, :spread, 1.0, recipe,
    )
    fingerprint = _aruq_config_fingerprint(config)
    @test length(fingerprint) == 64
    @test fingerprint == _aruq_config_fingerprint(deepcopy(config))
    changed = deepcopy(config)
    changed["master_seed"] = 8164102
    @test fingerprint != _aruq_config_fingerprint(changed)
    @test config["selection_recipe"]["rows"] == [25, 635]

    mktempdir() do dir
        path = joinpath(dir, "record.toml")
        _atomic_toml(path, Dict{String, Any}(
            "config_fingerprint" => fingerprint,
            "outcome" => "report",
        ))
        @test _aruq_existing_record(
            path, fingerprint; force = false, retry_failures = false,
        )["outcome"] == "report"
        @test_throws ArgumentError _aruq_existing_record(
            path, repeat("0", 64); force = false, retry_failures = false,
        )

        _atomic_toml(path, Dict{String, Any}(
            "config_fingerprint" => fingerprint,
            "outcome" => "uq_unavailable",
        ))
        @test isnothing(_aruq_existing_record(
            path, fingerprint; force = false, retry_failures = true,
        ))
        @test isnothing(_aruq_existing_record(
            path, fingerprint; force = true, retry_failures = false,
        ))
    end

    @testset "process-group accounting and bounded tree death" begin
        if Sys.islinux()
            process = run(pipeline(
                ignorestatus(`setsid sh -c "sleep 30 & wait"`),
                stdout = devnull, stderr = devnull,
            ); wait = false)
            pgid = getpid(process)
            try
                sleep(0.1)
                snapshot = _asu_process_group_snapshot(pgid)
                @test length(snapshot.members) >= 2
                @test snapshot.rss_bytes > 0
            finally
                @test _asu_terminate_group(
                    pgid; term_grace_seconds = 1.0,
                    kill_grace_seconds = 1.0, poll_seconds = 0.05,
                )
            end
            @test isempty(_asu_process_group_snapshot(pgid).members)
        end
    end

    @testset "summary retains failed cells in availability denominators" begin
        summary_config = deepcopy(config)
        summary_config["selection_recipe"] = Dict{String, Any}(
            "kind" => "adaptive", "rows" => Int[], "interpolator_source" => "",
        )
        report_record = Dict{String, Any}(
            "config" => summary_config,
            "case_id" => "lotka_volterra_5_1em6",
            "arm" => "mp_solver_polish",
            "interpolator_pool" => "uq_only",
            "data_source" => "synthetic",
            "noise" => 1e-6,
            "master_seed" => 1,
            "outcome" => "report",
            "artifact_match" => "exact",
            "uq_param_labels" => ["k1"],
            "uq_param_covariance" => [[0.04]],
            "coordinates" => [Dict{String, Any}(
                "label" => "k1", "identifiable" => true,
                "estimate" => 1.1, "truth" => 1.0, "z" => 0.5,
                "covered_95" => true,
            )],
            "uq_reliability" => Dict{String, Any}(
                "numerical_linearization" => "accepted",
            ),
            "linearization" => Dict{String, Any}("gp_jitter_to_noise" => 0.2),
            "elapsed_seconds" => 2.0,
            "max_rss_bytes" => 1024,
        )
        failed_record = Dict{String, Any}(
            "config" => deepcopy(summary_config),
            "case_id" => "lotka_volterra_5_1em6",
            "arm" => "mp_solver_polish",
            "interpolator_pool" => "uq_only",
            "data_source" => "synthetic",
            "noise" => 1e-6,
            "master_seed" => 2,
            "outcome" => "timeout",
            "elapsed_seconds" => 1800.0,
            "max_rss_bytes" => 2048,
        )
        different_revision = deepcopy(report_record)
        different_revision["config"]["odepe_commit"] = repeat("f", 40)
        @test _asru_group_key(report_record) != _asru_group_key(different_revision)
        different_policy = deepcopy(report_record)
        different_policy["config"]["multipoint_pair_strategy"] = "boundary_order"
        @test _asru_group_key(report_record) != _asru_group_key(different_policy)
        campaign_summary = _asru_group_summary([report_record, failed_record])
        @test campaign_summary["replicates"] == 2
        @test campaign_summary["estimate_available"] == 1
        @test campaign_summary["accurate_estimates_at_1e-3"] == 0
        @test campaign_summary["usable_reports"] == 1
        @test campaign_summary["usable_rate"] == 0.5
        coordinate = only(campaign_summary["coordinates"])
        @test coordinate["conditional_coverage_95"] == 1.0
        @test coordinate["unconditional_coverage_95"] == 0.5
        @test coordinate["median_absolute_z"] == 0.5
        @test coordinate["estimator_bias"] ≈ 0.1
        @test coordinate["estimator_rmse"] ≈ 0.1
        @test campaign_summary["outcome_reason_counts"]["timeout"] == 1

        reordered = deepcopy(report_record)
        reordered["master_seed"] = 3
        reordered["uq_param_labels"] = ["different"]
        reordered["coordinates"][1]["label"] = "different"
        @test_throws ArgumentError _asru_group_summary([report_record, reordered])
    end
end
