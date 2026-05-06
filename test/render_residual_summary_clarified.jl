using CSV
using Printf

const DEFAULT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "residual_polish_ablation_ungated_expanded")

function _safe_float(x)
    if x isa Real
        return Float64(x)
    end
    try
        return parse(Float64, String(x))
    catch
        return Inf
    end
end

function _fmt_pct(x)
    if !isfinite(x)
        return "Inf"
    elseif abs(x) >= 1000 || (0 < abs(x) < 1e-4)
        return @sprintf("%.4e%%", 100x)
    else
        return @sprintf("%.2f%%", 100x)
    end
end

function _load_rows(tsv_path::AbstractString)
    return [Dict(Symbol(name) => row[name] for name in propertynames(row)) for row in CSV.File(tsv_path; delim = '\t')]
end

function _parse_selected_metrics(summary_md_path::AbstractString)
    selected = Dict{String, Dict{String, String}}()
    current_case = nothing
    current_arm = nothing
    for line in eachline(summary_md_path)
        if (m = match(r"^### `(.+)`$", line)) !== nothing
            current_case = m.captures[1]
            selected[current_case] = Dict{String, String}()
            current_arm = nothing
        elseif !isnothing(current_case) && (m = match(r"^- (.+):$", line)) !== nothing
            current_arm = m.captures[1]
        elseif !isnothing(current_case) && !isnothing(current_arm) && (m = match(r"^  - selected benchmark RMSE: (.+)$", line)) !== nothing
            selected[current_case][current_arm] = m.captures[1]
        end
    end
    return selected
end

function _write_best_table(io, title::AbstractString, rows, refs_and_cols)
    println(io, "## $(title)\n")
    header = ["Case", "Imported best", "Saved `amigo2`", "Saved `odepe_polish`"]
    append!(header, first.(refs_and_cols))
    println(io, "| $(join(header, " | ")) |")
    println(io, "| $(join(fill("---:", length(header)) |> x -> (x[1] = "---"; x), " | ")) |")
    for row in rows
        cells = String[
            "`$(row[:case_id])`",
            _fmt_pct(_safe_float(row[:imported_best_benchmark_rmse])),
            _fmt_pct(_safe_float(row[:saved_amigo_rmse])),
            _fmt_pct(_safe_float(row[:saved_polish_rmse])),
        ]
        for (_, key) in refs_and_cols
            push!(cells, _fmt_pct(_safe_float(row[key])))
        end
        println(io, "| $(join(cells, " | ")) |")
    end
    println(io)
end

function _first_selected_value(case_selected::Dict{String, String}, labels::Vector{String})
    for label in labels
        haskey(case_selected, label) && return case_selected[label]
    end
    return "N/A"
end

function _write_selected_table(io, title::AbstractString, rows, selected_map, arm_labels)
    println(io, "## $(title)\n")
    header = ["Case", "Saved `amigo2`", "Saved `odepe_polish`"]
    append!(header, first.(arm_labels))
    println(io, "| $(join(header, " | ")) |")
    println(io, "| $(join(fill("---:", length(header)) |> x -> (x[1] = "---"; x), " | ")) |")
    for row in rows
        case_id = String(row[:case_id])
        case_selected = get(selected_map, case_id, Dict{String, String}())
        cells = String[
            "`$(case_id)`",
            _fmt_pct(_safe_float(row[:saved_amigo_rmse])),
            _fmt_pct(_safe_float(row[:saved_polish_rmse])),
        ]
        for (_, labels) in arm_labels
            push!(cells, _first_selected_value(case_selected, labels))
        end
        println(io, "| $(join(cells, " | ")) |")
    end
    println(io)
end

function main()
    root = get(ENV, "ODEPE_RESIDUAL_SUMMARY_ROOT", DEFAULT_ROOT)
    tsv_path = joinpath(root, "summary.tsv")
    md_path = joinpath(root, "summary.md")
    out_path = joinpath(root, "summary_clarified.md")
    rows = _load_rows(tsv_path)
    selected_map = _parse_selected_metrics(md_path)

    original_cols = [
        ("Scalar original-space", :scalar_linear_best_rmse),
        ("Residual LM original-space", :residual_lm_linear_best_rmse),
        ("FastShortcut original-space", :residual_fastshortcut_linear_best_rmse),
        ("TrustRegion original-space", :residual_trustregion_linear_best_rmse),
        ("LeastSquaresOptim LM original-space", :residual_lso_lm_linear_best_rmse),
        ("LeastSquaresOptim Dogleg original-space", :residual_lso_dogleg_linear_best_rmse),
        ("FastLevenbergMarquardt original-space", :residual_fastlm_linear_best_rmse),
    ]
    log_cols = [
        ("Scalar log-space", :scalar_log_best_rmse),
        ("Residual LM log-space", :residual_lm_log_best_rmse),
        ("FastShortcut log-space", :residual_fastshortcut_log_best_rmse),
        ("TrustRegion log-space", :residual_trustregion_log_best_rmse),
        ("LeastSquaresOptim LM log-space", :residual_lso_lm_log_best_rmse),
        ("LeastSquaresOptim Dogleg log-space", :residual_lso_dogleg_log_best_rmse),
        ("FastLevenbergMarquardt log-space", :residual_fastlm_log_best_rmse),
    ]
    selected_original = [
        ("Scalar original-space", ["scalar linear", "scalar original-space"]),
        ("Residual LM original-space", ["residual LM linear", "residual LM original-space"]),
        ("FastShortcut original-space", ["residual FastShortcut linear", "residual FastShortcut original-space"]),
        ("TrustRegion original-space", ["residual TrustRegion linear", "residual TrustRegion original-space"]),
        ("LeastSquaresOptim LM original-space", ["residual LeastSquaresOptim LM linear", "residual LeastSquaresOptim LM original-space"]),
        ("LeastSquaresOptim Dogleg original-space", ["residual LeastSquaresOptim Dogleg linear", "residual LeastSquaresOptim Dogleg original-space"]),
        ("FastLevenbergMarquardt original-space", ["residual FastLevenbergMarquardt linear", "residual FastLevenbergMarquardt original-space"]),
    ]
    selected_log = [
        ("Scalar log-space", ["scalar log-positive", "scalar log-space"]),
        ("Residual LM log-space", ["residual LM log-positive", "residual LM log-space"]),
        ("FastShortcut log-space", ["residual FastShortcut log-positive", "residual FastShortcut log-space"]),
        ("TrustRegion log-space", ["residual TrustRegion log-positive", "residual TrustRegion log-space"]),
        ("LeastSquaresOptim LM log-space", ["residual LeastSquaresOptim LM log-positive", "residual LeastSquaresOptim LM log-space"]),
        ("LeastSquaresOptim Dogleg log-space", ["residual LeastSquaresOptim Dogleg log-positive", "residual LeastSquaresOptim Dogleg log-space"]),
        ("FastLevenbergMarquardt log-space", ["residual FastLevenbergMarquardt log-positive", "residual FastLevenbergMarquardt log-space"]),
    ]

    open(out_path, "w") do io
        println(io, "# Residual Polish Ablation: Clarified Views\n")
        println(io, "- Source summary: `$(md_path)`")
        println(io, "- Source table: `$(tsv_path)`")
        println(io, "- Purpose: separate benchmark-like `best-in-set` reporting from operational `fit-selected` reporting, and rename `linear` / `log-positive` to clearer coordinate terms.\n")
        println(io, "## Terminology\n")
        println(io, "- `original-space`: the old `linear` setting. Optimize directly in the original coordinates.")
        println(io, "- `log-space`: the old `log-positive` setting. Optimize in `log(x)` and evaluate the objective in `x`.")
        println(io, "- `best-in-set`: benchmark-like oracle selection. This is the closest like-for-like view against the bilby benchmark, because the benchmark uses oracle selection via `select_best_estimation(...)` in `summarize_results.py`.")
        println(io, "- `fit-selected`: operational selection. This is what the current local pipeline would return when it chooses a winner by fit among analyzed candidates.\n")
        _write_best_table(io, "Best-In-Set / Oracle View: Original-Space Arms", rows, original_cols)
        _write_best_table(io, "Best-In-Set / Oracle View: Log-Space Arms", rows, log_cols)
        _write_selected_table(io, "Fit-Selected / Operational View: Original-Space Arms", rows, selected_map, selected_original)
        _write_selected_table(io, "Fit-Selected / Operational View: Log-Space Arms", rows, selected_map, selected_log)
    end
    println("Wrote clarified residual summary to $(out_path)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
