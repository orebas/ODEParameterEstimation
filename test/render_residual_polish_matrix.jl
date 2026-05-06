using Dates

function load_tsv(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && error("No data in $(path)")
    headers = split(first(lines), '\t')
    rows = Dict{String, String}[]
    for line in Iterators.drop(lines, 1)
        isempty(strip(line)) && continue
        fields = split(line, '\t')
        row = Dict{String, String}()
        for (h, v) in zip(headers, fields)
            row[h] = v
        end
        push!(rows, row)
    end
    return headers, rows
end

fmt_pct(v::AbstractString) = isfinite(tryparse(Float64, v) === nothing ? Inf : tryparse(Float64, v)) ?
    string(round(100 * parse(Float64, v); digits = 2), "%") : "Inf"

function column_label(col::AbstractString)
    mapping = Dict(
        "saved_amigo_rmse" => "saved amigo",
        "saved_polish_rmse" => "saved odepe_polish",
        "scalar_linear_best_rmse" => "scalar linear",
        "scalar_log_best_rmse" => "scalar log",
        "residual_lm_linear_best_rmse" => "LM linear",
        "residual_lm_log_best_rmse" => "LM log",
        "residual_trustregion_linear_best_rmse" => "TrustRegion linear",
        "residual_trustregion_log_best_rmse" => "TrustRegion log",
        "residual_lso_lm_linear_best_rmse" => "LSO LM linear",
        "residual_lso_lm_log_best_rmse" => "LSO LM log",
        "residual_lso_dogleg_linear_best_rmse" => "LSO dogleg linear",
        "residual_lso_dogleg_log_best_rmse" => "LSO dogleg log",
        "residual_fastlm_linear_best_rmse" => "FastLM linear",
        "residual_fastlm_log_best_rmse" => "FastLM log",
    )
    return get(mapping, col, col)
end

function render_matrix(tsv_path::AbstractString, md_path::AbstractString)
    _, rows = load_tsv(tsv_path)
    ordered_cols = [
        "saved_amigo_rmse",
        "saved_polish_rmse",
        "scalar_linear_best_rmse",
        "scalar_log_best_rmse",
        "residual_lm_linear_best_rmse",
        "residual_lm_log_best_rmse",
        "residual_trustregion_linear_best_rmse",
        "residual_trustregion_log_best_rmse",
        "residual_lso_lm_linear_best_rmse",
        "residual_lso_lm_log_best_rmse",
        "residual_lso_dogleg_linear_best_rmse",
        "residual_lso_dogleg_log_best_rmse",
        "residual_fastlm_linear_best_rmse",
        "residual_fastlm_log_best_rmse",
    ]

    open(md_path, "w") do io
        println(io, "# Residual Polish Matrix\n")
        println(io, "- Generated: `$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))`")
        println(io, "- Source TSV: `$(tsv_path)`")
        println(io, "- Values: best-in-set benchmark RMSE")
        println(io, "- Lower is better\n")

        header = vcat(["case"], map(column_label, ordered_cols))
        aligns = vcat(["---"], fill("---:", length(ordered_cols)))
        println(io, "| $(join(header, " | ")) |")
        println(io, "| $(join(aligns, " | ")) |")
        for row in rows
            vals = [row["case_id"]]
            append!(vals, [fmt_pct(get(row, c, "Inf")) for c in ordered_cols])
            println(io, "| `$(vals[1])` | $(join(vals[2:end], " | ")) |")
        end

        println(io, "\n## Notes\n")
        println(io, "- This matrix shows both scalar baselines and every residual solver in both coordinate systems.")
        println(io, "- It is a readability companion to `summary.md`, not a recomputation.")
    end
end

function main()
    root = get(
        ENV,
        "ODEPE_RESIDUAL_OUTPUT_ROOT",
        joinpath(@__DIR__, "..", "artifacts", "diagnostics", "residual_polish_ablation_fdclean_expanded"),
    )
    tsv_path = joinpath(root, "summary.tsv")
    md_path = joinpath(root, "summary_matrix.md")
    render_matrix(tsv_path, md_path)
    println("Wrote matrix summary to $(md_path)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
