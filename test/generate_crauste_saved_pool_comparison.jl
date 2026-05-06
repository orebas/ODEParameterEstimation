using CSV
using Dates
using ODEParameterEstimation
using OrderedCollections
using Printf

const ODEPE = ODEParameterEstimation
const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const CASE_ID = get(ENV, "ODEPE_CRAUSTE_CASE_ID", "crauste_3_1em8")
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "crauste_saved_pool_comparison", CASE_ID)
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

case_dir_for_variant(case_id::AbstractString, variant::AbstractString) =
    joinpath(BENCHMARK_ROOT, "filetree", variant, String(case_id))

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
        return Dict{Symbol, Any}(
            :median_rel_err => Float64(row.MedianRelErr),
            :mean_rel_err => Float64(row.MeanRelErr),
            :max_rel_err => Float64(row.MaxRelErr),
            :rmse => Float64(row.RMSE),
            :success => Bool(row.Success),
        )
    end
    return nothing
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

function _fmt_pct(x)
    return ODEPE._fmt_percent(x)
end

function _format_float(x; digits::Int = 4)
    if x isa Nothing
        return "N/A"
    elseif x isa Symbol
        return String(x)
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

function _mode_options(mode::Symbol)
    base = (
        version_label = mode,
        frontier_growth_factor = 2.0,
        max_admitted_merged_seeds = 64,
        block_support_point_count = BLOCK_SUPPORT_POINTS,
        block_support_combo_count = BLOCK_SUPPORT_COMBOS,
        post_polish_metric = :trajectory_hybrid,
    )
    if mode == :frontier_raw_only
        return ODEPE.TryhardFinalistOptions(; base..., include_block_seeds = false, include_branch_seeds = false, include_synthesized_seeds = false)
    elseif mode == :frontier_raw_plus_block
        return ODEPE.TryhardFinalistOptions(; base..., include_block_seeds = true, include_branch_seeds = false, include_synthesized_seeds = false)
    elseif mode == :frontier_raw_plus_block_branch
        return ODEPE.TryhardFinalistOptions(; base..., include_block_seeds = true, include_branch_seeds = true, include_synthesized_seeds = false)
    elseif mode == :frontier_full
        return ODEPE.TryhardFinalistOptions(; base..., include_block_seeds = true, include_branch_seeds = true, include_synthesized_seeds = true)
    end
    error("Unsupported frontier mode $mode")
end

function run_frontier_mode(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
    shared_context,
    mode::Symbol,
)
    report = ODEPE.research_tryhard_finalists(
        pep;
        est_opts = run_opts,
        raw_candidates = raw_candidates,
        context = shared_context,
        tryhard_opts = _mode_options(mode),
    )
    selected_metrics = ODEPE._candidate_truth_metrics(pep, report.best_result)
    best_idx, best_metrics, best_rmse = best_finalist_truth(pep, report)
    selection = report.selection_summary
    return Dict{Symbol, Any}(
        :mode => mode,
        :report => report,
        :selected_metrics => selected_metrics,
        :best_in_set_index => best_idx,
        :best_in_set_metrics => best_metrics,
        :best_in_set_rmse => best_rmse,
        :selection_seconds => get(selection, :selection_seconds, Inf),
        :generator_seconds_total => get(selection, :generator_seconds_total, 0.0),
        :block_report_seconds => get(selection, :block_report_seconds, 0.0),
        :branch_report_seconds => get(selection, :branch_report_seconds, 0.0),
        :synth_report_seconds => get(selection, :synth_report_seconds, 0.0),
        :seed_prep_seconds => get(selection, :seed_prep_seconds, 0.0),
        :winner_sources => get(selection, :winner_sources, "none"),
        :finalist_count => length(report.finalists),
        :merged_seed_count => get(selection, :merged_seed_count, length(report.merged_seed_rows)),
        :polished_seed_count => get(selection, :polished_seed_count, count(row -> !isnothing(row[:polished_candidate]), report.polished_seed_rows)),
        :polish_error_count => get(selection, :polish_error_count, 0),
        :polish_maxiters_count => get(selection, :polish_maxiters_count, 0),
        :frontier_limit => get(selection, :frontier_limit, length(report.merged_seed_rows)),
        :hard_limit => get(selection, :hard_limit, 0),
    )
end

function build_artifact(case_id::AbstractString)
    spec = parse_case_spec(case_id)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    datasize = isnothing(pep.data_sample) || !haskey(pep.data_sample, "t") ? 0 : length(pep.data_sample["t"])

    polish_run_opts = ODEPE.merge_options(
        isnothing(polish_case.benchmark_opts) ? ODEPE.EstimationOptions() : polish_case.benchmark_opts;
        datasize = datasize,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = true,
    )

    raw_import_timed = @timed ODEPE._load_benchmark_result_candidates(pep, polish_run_opts, nopolish_case.case_dir)
    saved_nopolish_candidates = raw_import_timed.value
    saved_polish_candidates = ODEPE._load_benchmark_result_candidates(pep, polish_run_opts, polish_case.case_dir)
    saved_amigo_metrics = load_selected_metrics(spec, "amigo2_run")
    saved_nopolish_metrics = load_selected_metrics(spec, "odepe_nopolish")
    saved_polish_metrics = load_selected_metrics(spec, "odepe_polish")
    _, raw_best_fit_candidate = ODEPE._best_fit_raw_candidate(saved_nopolish_candidates)
    raw_best_fit_metrics = ODEPE._candidate_truth_metrics(pep, raw_best_fit_candidate)
    _, _, raw_best_in_set_rmse = best_truth_candidate(pep, saved_nopolish_candidates)
    _, _, saved_polish_best_in_set_rmse = best_truth_candidate(pep, saved_polish_candidates)

    stock_report = build_local_stock_polish_report(pep, saved_nopolish_candidates, polish_run_opts)
    context_timed = @timed ODEPE._build_consensus_context(pep, polish_run_opts)
    shared_context = context_timed.value

    frontier_modes = [
        :frontier_raw_only,
        :frontier_raw_plus_block,
        :frontier_raw_plus_block_branch,
        :frontier_full,
    ]
    frontier_reports = OrderedDict{Symbol, Dict{Symbol, Any}}()
    for mode in frontier_modes
        frontier_reports[mode] = run_frontier_mode(pep, saved_nopolish_candidates, polish_run_opts, shared_context, mode)
    end

    return Dict{Symbol, Any}(
        :case_id => String(case_id),
        :spec => spec,
        :saved_amigo_metrics => saved_amigo_metrics,
        :saved_nopolish_metrics => saved_nopolish_metrics,
        :saved_polish_metrics => saved_polish_metrics,
        :saved_polish_best_in_set_rmse => saved_polish_best_in_set_rmse,
        :raw_import_seconds => raw_import_timed.time,
        :shared_context_seconds => context_timed.time,
        :raw_candidate_count => length(saved_nopolish_candidates),
        :raw_best_fit_metrics => raw_best_fit_metrics,
        :raw_best_in_set_rmse => raw_best_in_set_rmse,
        :stock_report => stock_report,
        :frontier_reports => frontier_reports,
    )
end

function render_summary_tsv(path::String, artifact::Dict{Symbol, Any})
    open(path, "w") do io
        println(io, join([
            "case_id",
            "arm",
            "selected_rmse",
            "best_in_set_rmse",
            "raw_candidate_count",
            "merged_seed_count",
            "polished_seed_count",
            "finalist_count",
            "selection_seconds",
            "generator_seconds_total",
            "block_report_seconds",
            "branch_report_seconds",
            "synth_report_seconds",
            "seed_prep_seconds",
            "polish_error_count",
            "polish_maxiters_count",
            "winner_sources",
        ], '\t'))
        println(io, join([
            artifact[:case_id],
            "stock_polish",
            string(get(artifact[:stock_report][:selected_metrics], :combined_rel_rmse, Inf)),
            string(artifact[:stock_report][:best_in_set_rmse]),
            string(artifact[:raw_candidate_count]),
            string(artifact[:stock_report][:analyzed_candidate_count]),
            string(artifact[:stock_report][:analyzed_candidate_count]),
            string(artifact[:stock_report][:analyzed_candidate_count]),
            string(artifact[:stock_report][:selection_seconds]),
            "0.0",
            "0.0",
            "0.0",
            "0.0",
            string(artifact[:stock_report][:build_polish_context_seconds]),
            "0",
            "0",
            "stock_pool",
        ], '\t'))
        for (mode, report) in artifact[:frontier_reports]
            println(io, join([
                artifact[:case_id],
                String(mode),
                string(get(report[:selected_metrics], :combined_rel_rmse, Inf)),
                string(report[:best_in_set_rmse]),
                string(artifact[:raw_candidate_count]),
                string(report[:merged_seed_count]),
                string(report[:polished_seed_count]),
                string(report[:finalist_count]),
                string(report[:selection_seconds]),
                string(report[:generator_seconds_total]),
                string(report[:block_report_seconds]),
                string(report[:branch_report_seconds]),
                string(report[:synth_report_seconds]),
                string(report[:seed_prep_seconds]),
                string(report[:polish_error_count]),
                string(report[:polish_maxiters_count]),
                string(report[:winner_sources]),
            ], '\t'))
        end
    end
end

function render_summary_markdown(path::String, artifact::Dict{Symbol, Any})
    open(path, "w") do io
        println(io, "# Crauste Saved-Pool Comparison\n")
        println(io, "- Case: `$(artifact[:case_id])`")
        println(io, "- Generated: `$(Dates.now())`")
        println(io, "- Benchmark root: `$(BENCHMARK_ROOT)`")
        println(io, "- Shared raw pool: saved bilby `odepe_nopolish/result.csv` candidates")
        println(io, "- Local comparison basis: stock polish vs frontier modes on the same imported pool\n")

        println(io, "## Saved Benchmark References\n")
        println(io, "| Method | Selected RMSE | Selected Max Rel Err | Success |")
        println(io, "| --- | ---: | ---: | ---: |")
        println(io, "| `amigo2_run` | $(_fmt_pct(get(artifact[:saved_amigo_metrics], :rmse, Inf))) | $(_fmt_pct(get(artifact[:saved_amigo_metrics], :max_rel_err, Inf))) | $(get(artifact[:saved_amigo_metrics], :success, false)) |")
        println(io, "| `odepe_nopolish` | $(_fmt_pct(get(artifact[:saved_nopolish_metrics], :rmse, Inf))) | $(_fmt_pct(get(artifact[:saved_nopolish_metrics], :max_rel_err, Inf))) | $(get(artifact[:saved_nopolish_metrics], :success, false)) |")
        println(io, "| `odepe_polish` | $(_fmt_pct(get(artifact[:saved_polish_metrics], :rmse, Inf))) | $(_fmt_pct(get(artifact[:saved_polish_metrics], :max_rel_err, Inf))) | $(get(artifact[:saved_polish_metrics], :success, false)) |")
        println(io)

        println(io, "## Imported Raw Pool\n")
        println(io, "- Imported candidate count: $(artifact[:raw_candidate_count])")
        println(io, "- Import runtime: $(_format_float(artifact[:raw_import_seconds]; digits = 3)) s")
        println(io, "- Shared context build runtime: $(_format_float(artifact[:shared_context_seconds]; digits = 3)) s")
        println(io, "- Best-fit imported candidate RMSE: $(_fmt_pct(get(artifact[:raw_best_fit_metrics], :combined_rel_rmse, Inf)))")
        println(io, "- Best imported candidate in set RMSE: $(_fmt_pct(artifact[:raw_best_in_set_rmse]))")
        println(io, "- Saved `odepe_polish` best imported RMSE: $(_fmt_pct(artifact[:saved_polish_best_in_set_rmse]))\n")

        println(io, "## Same-Pool Local Comparison\n")
        println(io, "| Arm | Selected RMSE | Best In Set RMSE | Merged Seeds | Polished Seeds | Finalists | Runtime |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
        println(io, "| `stock_polish` | $(_fmt_pct(get(artifact[:stock_report][:selected_metrics], :combined_rel_rmse, Inf))) | $(_fmt_pct(artifact[:stock_report][:best_in_set_rmse])) | $(artifact[:stock_report][:analyzed_candidate_count]) | $(artifact[:stock_report][:analyzed_candidate_count]) | $(artifact[:stock_report][:analyzed_candidate_count]) | $(_format_float(artifact[:stock_report][:selection_seconds]; digits = 3)) s |")
        for (mode, report) in artifact[:frontier_reports]
            println(io, "| `$(mode)` | $(_fmt_pct(get(report[:selected_metrics], :combined_rel_rmse, Inf))) | $(_fmt_pct(report[:best_in_set_rmse])) | $(report[:merged_seed_count]) | $(report[:polished_seed_count]) | $(report[:finalist_count]) | $(_format_float(report[:selection_seconds]; digits = 3)) s |")
        end
        println(io)

        println(io, "## Frontier Timing Breakdown\n")
        println(io, "| Mode | Block | Branch | Synth | Seed Prep | Total Generator | Total Selection | Polish Errors | Maxiters Errors |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for (mode, report) in artifact[:frontier_reports]
            println(io, "| `$(mode)` | $(_format_float(report[:block_report_seconds]; digits = 3)) s | $(_format_float(report[:branch_report_seconds]; digits = 3)) s | $(_format_float(report[:synth_report_seconds]; digits = 3)) s | $(_format_float(report[:seed_prep_seconds]; digits = 3)) s | $(_format_float(report[:generator_seconds_total]; digits = 3)) s | $(_format_float(report[:selection_seconds]; digits = 3)) s | $(report[:polish_error_count]) | $(report[:polish_maxiters_count]) |")
        end
        println(io)

        println(io, "## Conclusions\n")
        for (mode, report) in artifact[:frontier_reports]
            println(
                io,
                "- `$(mode)` vs stock best-in-set: `$(_compare(report[:best_in_set_rmse], artifact[:stock_report][:best_in_set_rmse]))`; vs saved `odepe_polish` best-in-set: `$(_compare(report[:best_in_set_rmse], artifact[:saved_polish_best_in_set_rmse]))`.",
            )
        end
    end
end

function main()
    mkpath(OUTPUT_ROOT)
    artifact = build_artifact(CASE_ID)
    render_summary_tsv(joinpath(OUTPUT_ROOT, "summary.tsv"), artifact)
    render_summary_markdown(joinpath(OUTPUT_ROOT, "summary.md"), artifact)
    println("Wrote crauste saved-pool comparison artifact to:")
    println("  " * joinpath(OUTPUT_ROOT, "summary.md"))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
