# Repeated-noise campaign for the research-only model-assisted correction.
#
# This wrapper reuses the exact per-cell implementation in
# run_model_assisted_panel.jl while making seed identity independent of case
# ordering and process partitioning. That lets expensive models run in
# separate resumable processes without changing the scientific sample.

include(joinpath(@__DIR__, "run_model_assisted_panel.jl"))

function _mac_replicate_seeds()
    explicit = _campaign_list("seeds", "")
    if !isempty(explicit)
        seeds = parse.(Int, explicit)
        length(unique(seeds)) == length(seeds) || throw(ArgumentError(
            "--seeds entries must be unique",
        ))
        return seeds
    end
    replicates = parse(Int, _campaign_arg("replicates", "10"))
    replicates > 0 || throw(ArgumentError("--replicates must be positive"))
    seed_start = parse(Int, _campaign_arg("seed-start", "8163100"))
    return collect((seed_start + 1):(seed_start + replicates))
end

function main_model_assisted_replicates()
    case_ids = _campaign_list(
        "cases",
        "lotka_volterra_5_1em6,fitzhugh_nagumo_9_1em6,slow_fast_5_1em6,vanderpol_2_1em4",
    )
    unknown = setdiff(case_ids, collect(keys(PEB_AUDITED_CASES)))
    isempty(unknown) || throw(ArgumentError(
        "unknown audited cases: $(join(unknown, ", "))",
    ))
    noises = parse.(Float64, _campaign_list("noises", "1e-6"))
    all(noise -> isfinite(noise) && noise >= 0, noises) || throw(ArgumentError(
        "all noise levels must be finite and non-negative",
    ))
    seeds = _mac_replicate_seeds()
    max_observations = parse(Int, _campaign_arg("max-observations", "0"))
    shooting_points = parse(Int, _campaign_arg("shooting-points", "20"))
    max_pairs = parse(Int, _campaign_arg("max-pairs", "15"))
    run_polish = _mac_bool_arg("polish", false)
    polish_maxtime = parse(Float64, _campaign_arg("polish-maxtime", "120.0"))
    cell_index = parse(Int, _campaign_arg("cell-index-offset", "0"))
    force = _mac_bool_arg("force", false)
    peb_root = normpath(_campaign_arg("peb-root", _default_peb_root()))
    out_name = _campaign_arg(
        "out",
        "model_assisted_replicates_$(Dates.format(now(), "yyyymmdd_HHMMSS"))",
    )
    out_dir = isabspath(out_name) ? out_name : joinpath(@__DIR__, "results", out_name)
    mkpath(out_dir)

    println("PEB root: ", peb_root)
    println("Output: ", out_dir)
    println("Cases: ", join(case_ids, ", "), " | noises: ", noises,
        " | seeds: ", first(seeds), "..", last(seeds),
        " | polish: ", run_polish)
    payloads = Dict{String, Any}[]
    for case_id in case_ids, seed in seeds, noise in noises
        cell_index += 1
        push!(payloads, _run_model_assisted_cell(
            case_id, PEB_AUDITED_CASES[case_id], noise, seed, cell_index;
            peb_root, out_dir, max_observations, shooting_points, max_pairs,
            run_polish, polish_maxtime, force,
        ))
    end
    _print_model_assisted_summary(payloads)
    println("Results saved under ", out_dir)
    return payloads
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_model_assisted_replicates()
end
