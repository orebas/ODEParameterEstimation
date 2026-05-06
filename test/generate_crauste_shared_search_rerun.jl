using CSV
using Dates
using ODEParameterEstimation
using Printf
using Statistics

const ODEPE = ODEParameterEstimation
const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const CASE_ID = get(ENV, "ODEPE_CRAUSTE_CASE_ID", "crauste_3_1em8")
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "crauste_shared_search_rerun", CASE_ID)
const BLOCK_SUPPORT_POINTS = 4
const BLOCK_SUPPORT_COMBOS = 4
const TIE_ATOL = 1e-4

struct CaseSpec
    case_id::String
    system::String
    run_idx::Int
    noise_tag::String
end

function parse_case_spec(case_id::AbstractString)
    parts = split(String(case_id), "_")
    length(parts) < 3 && error("Invalid case id '$case_id'")
    system = join(parts[1:(end - 2)], "_")
    run_idx = parse(Int, parts[end - 1])
    noise_suffix = parts[end]
    noise_tag = if noise_suffix == "0"
        "0e+00"
    elseif noise_suffix == "1em8"
        "1e-08"
    elseif noise_suffix == "1em6"
        "1e-06"
    elseif noise_suffix == "1em4"
        "1e-04"
    elseif noise_suffix == "1em2"
        "1e-02"
    else
        error("Unsupported noise suffix '$noise_suffix'")
    end
    return CaseSpec(String(case_id), system, run_idx, noise_tag)
end

function case_dir_for_variant(case_id::AbstractString, variant::AbstractString)
    return joinpath(BENCHMARK_ROOT, "filetree", variant, String(case_id))
end

function comparison_path(spec::CaseSpec, method::AbstractString)
    return joinpath(
        BENCHMARK_ROOT,
        "analysis_results",
        "parameter_comparison_$(spec.system)_$(method)_noise_$(spec.noise_tag).csv",
    )
end

function load_selected_metrics(spec::CaseSpec, method::AbstractString)
    path = comparison_path(spec, method)
    isfile(path) || return nothing
    for row in CSV.File(path)
        Int(row.Run) == spec.run_idx || continue
        return (
            median_rel_err = Float64(row.MedianRelErr),
            mean_rel_err = Float64(row.MeanRelErr),
            max_rel_err = Float64(row.MaxRelErr),
            rmse = Float64(row.RMSE),
            success = Bool(row.Success),
        )
    end
    return nothing
end

function candidate_reference_summary(
    pep::ODEPE.ParameterEstimationProblem,
    strategy::Symbol,
    candidates::Vector{ODEPE.ParameterEstimationResult},
)
    idx, best = ODEPE._best_fit_raw_candidate(candidates)
    return Dict{Symbol, Any}(
        :strategy => strategy,
        :candidate_count => length(candidates),
        :selected_index => idx,
        :selected_candidate => best,
        :selected_truth_metrics => ODEPE._candidate_truth_metrics(pep, best),
    )
end

function best_truth_candidate(
    pep::ODEPE.ParameterEstimationProblem,
    candidates::Vector{ODEPE.ParameterEstimationResult},
)
    isempty(candidates) && return nothing, Dict{Symbol, Any}(), Inf
    best_idx = nothing
    best_metrics = Dict{Symbol, Any}()
    best_rmse = Inf
    for (idx, candidate) in enumerate(candidates)
        metrics = ODEPE._candidate_truth_metrics(pep, candidate)
        rmse = get(metrics, :combined_rel_rmse, Inf)
        if rmse < best_rmse
            best_idx = idx
            best_metrics = metrics
            best_rmse = rmse
        end
    end
    return best_idx, best_metrics, best_rmse
end

function best_finalist_truth(
    pep::ODEPE.ParameterEstimationProblem,
    report::Union{Nothing, ODEPE.TryhardFinalistReport},
)
    if isnothing(report) || isempty(report.finalists)
        return nothing, Dict{Symbol, Any}(), Inf
    end
    best_idx = nothing
    best_metrics = Dict{Symbol, Any}()
    best_rmse = Inf
    for (idx, finalist) in enumerate(report.finalists)
        metrics = ODEPE._candidate_truth_metrics(pep, finalist.representative_candidate)
        rmse = get(metrics, :combined_rel_rmse, Inf)
        if rmse < best_rmse
            best_idx = idx
            best_metrics = metrics
            best_rmse = rmse
        end
    end
    return best_idx, best_metrics, best_rmse
end

function _format_float(x; digits::Int = 4)
    if x isa Nothing
        return "N/A"
    elseif x isa Symbol
        return String(x)
    elseif x isa Bool
        return string(x)
    elseif !(x isa Real)
        return string(x)
    elseif !isfinite(x)
        return string(x)
    elseif abs(x) >= 1000 || abs(x) < 1e-3
        return @sprintf("%.4e", x)
    else
        return @sprintf("%.*f", digits, x)
    end
end

function _fmt_pct(x)
    return ODEPE._fmt_percent(x)
end

function _fmt_sci(x)
    return ODEPE._fmt_sci(x)
end

function _compare(lhs::Real, rhs::Real; atol::Float64 = TIE_ATOL)
    if !isfinite(lhs) && !isfinite(rhs)
        return :tie
    elseif !isfinite(lhs)
        return :worse
    elseif !isfinite(rhs)
        return :better
    elseif lhs < rhs - atol
        return :better
    elseif lhs > rhs + atol
        return :worse
    end
    return :tie
end

function build_local_stock_polish_report(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
)
    timed = @timed begin
        polish_ctx = nothing
        ctx_seconds = @elapsed polish_ctx = ODEPE._build_polish_context(pep; opts = run_opts)
        polished_pool = nothing
        polish_seconds = @elapsed polished_pool = ODEPE._polish_batch_from_context(polish_ctx, raw_candidates; opts = run_opts)
        analyzed = ODEPE.analyze_estimation_result(pep, polished_pool; nooutput = true)
        analyzed_candidates = analyzed[1]
        selected_idx, selected_candidate = ODEPE._best_fit_raw_candidate(analyzed_candidates)
        best_idx, best_metrics, best_rmse = best_truth_candidate(pep, analyzed_candidates)
        (
            ctx_seconds = ctx_seconds,
            polish_seconds = polish_seconds,
            polish_ctx = polish_ctx,
            polished_pool = polished_pool,
            analyzed_candidates = analyzed_candidates,
            selected_idx = selected_idx,
            selected_candidate = selected_candidate,
            selected_metrics = ODEPE._candidate_truth_metrics(pep, selected_candidate),
            best_idx = best_idx,
            best_metrics = best_metrics,
            best_rmse = best_rmse,
        )
    end
    return Dict{Symbol, Any}(
        :build_polish_context_seconds => timed.value.ctx_seconds,
        :polish_seconds => timed.value.polish_seconds,
        :selection_seconds => timed.time,
        :polish_ctx => timed.value.polish_ctx,
        :polished_pool => timed.value.polished_pool,
        :analyzed_candidates => timed.value.analyzed_candidates,
        :analyzed_candidate_count => length(timed.value.analyzed_candidates),
        :selected_index => timed.value.selected_idx,
        :selected_candidate => timed.value.selected_candidate,
        :selected_metrics => timed.value.selected_metrics,
        :best_in_set_index => timed.value.best_idx,
        :best_in_set_metrics => timed.value.best_metrics,
        :best_in_set_rmse => timed.value.best_rmse,
    )
end

function render_summary_tsv(path::String, artifact::Dict{Symbol, Any})
    open(path, "w") do io
        println(io, join([
            "case_id",
            "saved_amigo_rmse",
            "saved_nopolish_rmse",
            "saved_polish_rmse",
            "saved_polish_best_in_set_rmse",
            "local_raw_best_fit_rmse",
            "local_raw_best_in_set_rmse",
            "local_stock_selected_rmse",
            "local_stock_best_in_set_rmse",
            "local_frontier_selected_rmse",
            "local_frontier_best_in_set_rmse",
            "raw_candidate_count",
            "stock_analyzed_count",
            "frontier_finalist_count",
            "frontier_polished_seed_count",
            "local_search_seconds",
            "local_stock_seconds",
            "local_frontier_seconds",
        ], '\t'))
        println(io, join([
            artifact[:case_id],
            string(get(artifact[:saved_amigo_metrics], :rmse, Inf)),
            string(get(artifact[:saved_nopolish_metrics], :rmse, Inf)),
            string(get(artifact[:saved_polish_metrics], :rmse, Inf)),
            string(artifact[:saved_polish_best_in_set_rmse]),
            string(get(artifact[:local_raw_best_fit_metrics], :combined_rel_rmse, Inf)),
            string(artifact[:local_raw_best_in_set_rmse]),
            string(get(artifact[:local_stock_selected_metrics], :combined_rel_rmse, Inf)),
            string(artifact[:local_stock_best_in_set_rmse]),
            string(get(artifact[:local_frontier_selected_metrics], :combined_rel_rmse, Inf)),
            string(artifact[:local_frontier_best_in_set_rmse]),
            string(artifact[:raw_candidate_count]),
            string(artifact[:local_stock_report][:analyzed_candidate_count]),
            string(length(artifact[:local_frontier_report].finalists)),
            string(count(row -> !isnothing(row[:polished_candidate]), artifact[:local_frontier_report].polished_seed_rows)),
            string(artifact[:local_search_seconds]),
            string(artifact[:local_stock_report][:selection_seconds]),
            string(get(artifact[:local_frontier_report].selection_summary, :selection_seconds, Inf)),
        ], '\t'))
    end
end

function render_summary_markdown(path::String, artifact::Dict{Symbol, Any})
    open(path, "w") do io
        println(io, "# Crauste Shared-Search Rerun\n")
        println(io, "- Case: `$(artifact[:case_id])`")
        println(io, "- Generated: `$(Dates.now())`")
        println(io, "- Benchmark root: `$(BENCHMARK_ROOT)`")
        println(io, "- Search basis: bilby `odepe_nopolish` settings")
        println(io, "- Comparison basis: same local raw candidate pool for stock polish and frontier\n")

        println(io, "## Benchmark-Faithful Configuration\n")
        println(io, "- Interpolators: `$(length(artifact[:search_interpolators]))`")
        println(io, "- Shooting points: `$(artifact[:search_shooting_points])`")
        println(io, "- Shooting warp: `$(artifact[:search_shooting_warp])` (beta=`$(artifact[:search_shooting_warp_beta])`)")
        println(io, "- Parameter homotopy: `$(artifact[:search_use_parameter_homotopy])`")
        println(io, "- Solver polish during raw search: `$(artifact[:search_polish_solver_solutions])`")
        println(io, "- Final polish in raw search: `$(artifact[:search_polish_solutions])`\n")

        println(io, "## Saved Benchmark References\n")
        println(io, "| Method | Selected RMSE | Selected Max Rel Err | Success | Imported Candidate Count | Best Imported RMSE |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: |")
        println(io, "| `amigo2_run` | $(_fmt_pct(get(artifact[:saved_amigo_metrics], :rmse, Inf))) | $(_fmt_pct(get(artifact[:saved_amigo_metrics], :max_rel_err, Inf))) | $(get(artifact[:saved_amigo_metrics], :success, false)) | N/A | N/A |")
        println(io, "| `odepe_nopolish` | $(_fmt_pct(get(artifact[:saved_nopolish_metrics], :rmse, Inf))) | $(_fmt_pct(get(artifact[:saved_nopolish_metrics], :max_rel_err, Inf))) | $(get(artifact[:saved_nopolish_metrics], :success, false)) | $(length(artifact[:saved_nopolish_candidates])) | $(_fmt_pct(artifact[:saved_nopolish_best_in_set_rmse])) |")
        println(io, "| `odepe_polish` | $(_fmt_pct(get(artifact[:saved_polish_metrics], :rmse, Inf))) | $(_fmt_pct(get(artifact[:saved_polish_metrics], :max_rel_err, Inf))) | $(get(artifact[:saved_polish_metrics], :success, false)) | $(length(artifact[:saved_polish_candidates])) | $(_fmt_pct(artifact[:saved_polish_best_in_set_rmse])) |")
        println(io)

        println(io, "## Local Shared Raw Search\n")
        println(io, "- Raw candidate count: $(artifact[:raw_candidate_count])")
        println(io, "- Search runtime: $(_format_float(artifact[:local_search_seconds]; digits = 3)) s")
        println(io, "- Best-fit raw candidate RMSE: $(_fmt_pct(get(artifact[:local_raw_best_fit_metrics], :combined_rel_rmse, Inf)))")
        println(io, "- Best raw candidate in set RMSE: $(_fmt_pct(artifact[:local_raw_best_in_set_rmse]))\n")

        println(io, "## Same-Pool Local Comparison\n")
        println(io, "| Arm | Selected RMSE | Best In Set RMSE | Returned Count | Runtime |")
        println(io, "| --- | ---: | ---: | ---: | ---: |")
        println(io, "| `stock_polish` | $(_fmt_pct(get(artifact[:local_stock_selected_metrics], :combined_rel_rmse, Inf))) | $(_fmt_pct(artifact[:local_stock_best_in_set_rmse])) | $(artifact[:local_stock_report][:analyzed_candidate_count]) | $(_format_float(artifact[:local_stock_report][:selection_seconds]; digits = 3)) s |")
        println(io, "| `frontier_finalists` | $(_fmt_pct(get(artifact[:local_frontier_selected_metrics], :combined_rel_rmse, Inf))) | $(_fmt_pct(artifact[:local_frontier_best_in_set_rmse])) | $(length(artifact[:local_frontier_report].finalists)) finalists | $(_format_float(get(artifact[:local_frontier_report].selection_summary, :selection_seconds, Inf); digits = 3)) s |")
        println(io)

        println(io, "## Frontier Details\n")
        println(io, "- Polished seed count: $(count(row -> !isnothing(row[:polished_candidate]), artifact[:local_frontier_report].polished_seed_rows))")
        println(io, "- Baseline seed count: $(length(artifact[:local_frontier_report].raw_seed_rows))")
        println(io, "- Additive seed count: $(length(artifact[:local_frontier_report].additive_seed_rows))")
        println(io, "- Merged seed count: $(length(artifact[:local_frontier_report].merged_seed_rows))")
        println(io, "- Winner sources: `$(get(artifact[:local_frontier_report].selection_summary, :winner_sources, "none"))`")
        println(io, "- Post-polish metric: `$(get(artifact[:local_frontier_report].selection_summary, :post_polish_metric, :unknown))`\n")

        println(io, "## Conclusions\n")
        println(io, "- Frontier vs stock on same raw pool, selected winner: `$(artifact[:frontier_vs_stock_selected])`")
        println(io, "- Frontier vs stock on same raw pool, best-in-set: `$(artifact[:frontier_vs_stock_best_in_set])`")
        println(io, "- Frontier vs saved benchmark `odepe_polish`, best-in-set: `$(artifact[:frontier_vs_saved_polish_best_in_set])`")
        println(io, "- Stock vs saved benchmark `odepe_polish`, best-in-set: `$(artifact[:stock_vs_saved_polish_best_in_set])`")
        println(io)

        if artifact[:frontier_vs_stock_best_in_set] == :better
            println(io, "- The current frontier/finalist machinery improves basin coverage relative to stock polish on the same search output.")
        else
            println(io, "- The current frontier/finalist machinery does not improve basin coverage relative to stock polish on the same search output.")
        end

        if artifact[:local_frontier_best_in_set_rmse] + TIE_ATOL < get(artifact[:saved_amigo_metrics], :rmse, Inf)
            println(io, "- The local frontier beats the saved AMIGO selected result on this benchmark case.")
        else
            println(io, "- A substantial gap to AMIGO remains after the current frontier/finalist path.")
        end

        if artifact[:frontier_vs_stock_best_in_set] != :better && artifact[:local_frontier_best_in_set_rmse] > get(artifact[:saved_amigo_metrics], :rmse, Inf) + TIE_ATOL
            println(io, "- On this case, the remaining bottleneck still looks search-side rather than purely finalizer-side.")
        elseif artifact[:frontier_vs_stock_best_in_set] == :better && artifact[:local_frontier_best_in_set_rmse] > get(artifact[:saved_amigo_metrics], :rmse, Inf) + TIE_ATOL
            println(io, "- Frontier helps on the same pool, but search-side improvements are still likely needed to close the remaining AMIGO gap.")
        else
            println(io, "- This case does not currently force a search-side redesign by itself.")
        end
    end
end

function build_artifact(case_id::AbstractString)
    spec = parse_case_spec(case_id)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    datasize = isnothing(pep.data_sample) || !haskey(pep.data_sample, "t") ? 0 : length(pep.data_sample["t"])

    raw_run_opts = ODEPE.merge_options(
        isnothing(nopolish_case.benchmark_opts) ? ODEPE.EstimationOptions() : nopolish_case.benchmark_opts;
        datasize = datasize,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = false,
    )
    polish_run_opts = ODEPE.merge_options(
        isnothing(polish_case.benchmark_opts) ? ODEPE.EstimationOptions() : polish_case.benchmark_opts;
        datasize = datasize,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = true,
    )

    saved_nopolish_candidates = ODEPE._load_benchmark_result_candidates(pep, polish_run_opts, nopolish_case.case_dir)
    saved_polish_candidates = ODEPE._load_benchmark_result_candidates(pep, polish_run_opts, polish_case.case_dir)
    saved_nopolish_metrics = load_selected_metrics(spec, "odepe_nopolish")
    saved_polish_metrics = load_selected_metrics(spec, "odepe_polish")
    saved_amigo_metrics = load_selected_metrics(spec, "amigo2_run")
    _, _, saved_nopolish_best_rmse = best_truth_candidate(pep, saved_nopolish_candidates)
    _, _, saved_polish_best_rmse = best_truth_candidate(pep, saved_polish_candidates)

    raw_timed = @timed ODEPE.analyze_parameter_estimation_problem(pep, raw_run_opts)
    raw_results_tuple = raw_timed.value[1]
    local_raw_candidates = raw_results_tuple[1]
    local_raw_best_fit_idx, local_raw_best_fit = ODEPE._best_fit_raw_candidate(local_raw_candidates)
    local_raw_best_fit_metrics = ODEPE._candidate_truth_metrics(pep, local_raw_best_fit)
    local_raw_best_idx, local_raw_best_metrics, local_raw_best_rmse = best_truth_candidate(pep, local_raw_candidates)

    local_stock_report = build_local_stock_polish_report(pep, local_raw_candidates, polish_run_opts)
    context = ODEPE._build_consensus_context(pep, raw_run_opts; reuse_bundle = ODEPE._last_estimation_reuse())
    frontier_report = ODEPE.research_tryhard_finalists(
        pep;
        est_opts = polish_run_opts,
        raw_candidates = local_raw_candidates,
        context = context,
        tryhard_opts = ODEPE.TryhardFinalistOptions(
            block_support_point_count = BLOCK_SUPPORT_POINTS,
            block_support_combo_count = BLOCK_SUPPORT_COMBOS,
        ),
    )
    frontier_selected_metrics = ODEPE._candidate_truth_metrics(pep, frontier_report.best_result)
    frontier_best_idx, frontier_best_metrics, frontier_best_rmse = best_finalist_truth(pep, frontier_report)

    return Dict{Symbol, Any}(
        :case_id => String(case_id),
        :spec => spec,
        :saved_amigo_metrics => saved_amigo_metrics,
        :saved_nopolish_metrics => saved_nopolish_metrics,
        :saved_polish_metrics => saved_polish_metrics,
        :saved_nopolish_candidates => saved_nopolish_candidates,
        :saved_polish_candidates => saved_polish_candidates,
        :saved_nopolish_best_in_set_rmse => saved_nopolish_best_rmse,
        :saved_polish_best_in_set_rmse => saved_polish_best_rmse,
        :local_search_seconds => raw_timed.time,
        :raw_candidate_count => length(local_raw_candidates),
        :local_raw_candidates => local_raw_candidates,
        :local_raw_best_fit_index => local_raw_best_fit_idx,
        :local_raw_best_fit_metrics => local_raw_best_fit_metrics,
        :local_raw_best_in_set_index => local_raw_best_idx,
        :local_raw_best_in_set_metrics => local_raw_best_metrics,
        :local_raw_best_in_set_rmse => local_raw_best_rmse,
        :local_stock_report => local_stock_report,
        :local_stock_selected_metrics => local_stock_report[:selected_metrics],
        :local_stock_best_in_set_rmse => local_stock_report[:best_in_set_rmse],
        :local_frontier_report => frontier_report,
        :local_frontier_selected_metrics => frontier_selected_metrics,
        :local_frontier_best_in_set_index => frontier_best_idx,
        :local_frontier_best_in_set_metrics => frontier_best_metrics,
        :local_frontier_best_in_set_rmse => frontier_best_rmse,
        :frontier_vs_stock_selected => _compare(
            get(frontier_selected_metrics, :combined_rel_rmse, Inf),
            get(local_stock_report[:selected_metrics], :combined_rel_rmse, Inf),
        ),
        :frontier_vs_stock_best_in_set => _compare(
            frontier_best_rmse,
            local_stock_report[:best_in_set_rmse],
        ),
        :frontier_vs_saved_polish_best_in_set => _compare(frontier_best_rmse, saved_polish_best_rmse),
        :stock_vs_saved_polish_best_in_set => _compare(local_stock_report[:best_in_set_rmse], saved_polish_best_rmse),
        :search_interpolators => polish_run_opts.interpolators,
        :search_shooting_points => raw_run_opts.shooting_points,
        :search_shooting_warp => raw_run_opts.shooting_warp,
        :search_shooting_warp_beta => raw_run_opts.shooting_warp_beta,
        :search_use_parameter_homotopy => raw_run_opts.use_parameter_homotopy,
        :search_polish_solver_solutions => raw_run_opts.polish_solver_solutions,
        :search_polish_solutions => raw_run_opts.polish_solutions,
    )
end

function main()
    mkpath(OUTPUT_ROOT)
    artifact = build_artifact(CASE_ID)
    render_summary_tsv(joinpath(OUTPUT_ROOT, "summary.tsv"), artifact)
    render_summary_markdown(joinpath(OUTPUT_ROOT, "summary.md"), artifact)
    println("Wrote crauste shared-search rerun artifact to:")
    println("  " * joinpath(OUTPUT_ROOT, "summary.md"))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
