# Script-local trim-policy probes for the receptor SIAN full equation set.
#
# Default mode only computes selected equation sets/ranks. Set
# ODEPE_RECEPTOR_TRIM_SOLVE=1 to run HC fresh/track probes for each selected trim.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/trim_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using Printf

function selected_feature_summary(S, selected, features)
    selected_features = features[selected]
    data_orders = [f.max_data_order for f in selected_features if f.data_present]
    return Dict{String, Any}(
        "selected_equation_indices" => selected,
        "n_selected" => length(selected),
        "max_data_order_used" => isempty(data_orders) ? -1 : maximum(data_orders),
        "data_equation_count" => count(f -> f.data_present, selected_features),
        "support_proxy_max" => maximum(f.solve_var_count for f in selected_features),
        "support_proxy_median" => sort([f.solve_var_count for f in selected_features])[cld(length(selected_features), 2)],
    )
end

function solve_trim_case(S, equations, P)
    ps = parameterized_system(S, equations; scale = true, scale_params = P)
    fr = fresh_solve(ps.system, ComplexF64.(P[1]))
    tr = track_solve(ps.system, fr.finite, ComplexF64.(P[1]), ComplexF64.(P[2]))
    return ps, fr, tr
end

function optional_int_list(name, default)
    if haskey(ENV, name)
        raw = lowercase(strip(ENV[name]))
        raw in ("", "none", "false", "off") && return Int[]
    end
    return env_list(name, default; parse_item = x -> parse(Int, x))
end

function main()
    out = output_path("trim_probe.jsonl")
    S = receptor_setup()
    pidx = shooting_indices(S)
    P = oracle_params_for_indices(S, pidx)
    J = rank_matrix(S)
    random_seeds = optional_int_list("ODEPE_RECEPTOR_TRIM_RANDOM_SEEDS", collect(1:20))
    caps = optional_int_list("ODEPE_RECEPTOR_TRIM_PIN_CAPS", collect(0:4))
    selected_labels = Set(env_list("ODEPE_RECEPTOR_TRIM_CASES", String[]; parse_item = string))
    do_solve = env_bool("ODEPE_RECEPTOR_TRIM_SOLVE", false)
    compute_mv = env_bool("ODEPE_RECEPTOR_FAST_MIXED_VOLUME", false)
    records = Dict{String, Any}[]

    cases = Tuple{Symbol, Int, Union{Nothing, Int}, String}[]
    push!(cases, (:current, 1, nothing, "current"))
    push!(cases, (:pins_low_order_first, 1, nothing, "pins_low_order_first"))
    push!(cases, (:support_first, 1, nothing, "support_first"))
    for cap in caps
        push!(cases, (:pins_low_order_first, 1, cap, "pins_cap_$cap"))
    end
    for seed in random_seeds
        push!(cases, (:random, seed, nothing, "random_$seed"))
    end
    if !isempty(selected_labels)
        cases = [case for case in cases if case[4] in selected_labels]
    end

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "n_full_equations" => length(S.full_equations),
            "n_solve_vars" => length(S.solve_vars),
            "do_solve" => do_solve,
            "compute_mixed_volume" => compute_mv,
            "random_seeds" => random_seeds,
            "pin_caps" => caps,
        ))

        for (policy, seed, cap, label) in cases
            trim = select_trim(S, policy; seed = seed, max_pin_order = cap, J = J)
            rec = Dict{String, Any}(
                "case" => label,
                "policy" => string(policy),
                "seed" => seed,
                "max_pin_order_cap" => isnothing(cap) ? nothing : cap,
                "rank" => trim.rank,
                "rank_complete" => trim.rank == length(S.solve_vars),
                "emergency_high_order_equations" => trim.emergency,
            )
            merge!(rec, selected_feature_summary(S, trim.selected, trim.features))

            if compute_mv || do_solve
                try
                    ps = parameterized_system(S, trim.equations; scale = true, scale_params = P)
                    rec["scale_range"] = collect(extrema(ps.scales))
                    compute_mv && (rec["mixed_volume"] = safe_mixed_volume(ps.system))
                catch err
                    rec["system_build_error"] = sprint(showerror, err)
                end
            end

            if do_solve && get(rec, "rank_complete", false)
                try
                    ps, fr, tr = solve_trim_case(S, trim.equations, P)
                    fresh_metrics = classify_solutions(S, fr.real, ps.scales, P[1])
                    track_metrics = classify_solutions(S, tr.real, ps.scales, P[2])
                    rec["fresh_seconds"] = fr.seconds
                    rec["fresh_n_finite"] = length(fr.finite)
                    rec["fresh_n_real"] = length(fr.real)
                    rec["fresh_histogram"] = fr.histogram
                    rec["fresh_truth_present"] = fresh_metrics["truth_present"]
                    rec["fresh_swap_present"] = fresh_metrics["swap_present"]
                    rec["track_seconds"] = tr.seconds
                    rec["track_started"] = tr.started
                    rec["track_success"] = tr.success
                    rec["track_n_finite"] = length(tr.finite)
                    rec["track_n_real"] = length(tr.real)
                    rec["track_histogram"] = tr.histogram
                    rec["track_truth_present"] = track_metrics["truth_present"]
                    rec["track_swap_present"] = track_metrics["swap_present"]
                    rec["track_max_full_residual"] = track_metrics["max_full_residual"]
                catch err
                    rec["solve_error"] = sprint(showerror, err)
                end
            end

            write_jsonl(io, rec)
            push!(records, rec)
        end
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
