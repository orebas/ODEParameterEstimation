# Selective-fallback and physical-root tracking probe.
#
# Tests whether production's "solution count dropped => fresh fallback" is too
# conservative for receptor, where many lost paths may be spurious.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/fallback_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using Printf

function physical_full_valid_starts(S, starts, scales, p; residual_tol = env_float("ODEPE_RECEPTOR_FAST_RESIDUAL_TOL", 1e-6))
    keep = Int[]
    for (i, sol) in enumerate(starts)
        x_true = unscale_solution(scales, sol)
        full_res = try full_residual_norms(S, x_true, p).maxabs catch; Inf end
        if is_physical_solution(S, x_true) && full_res <= residual_tol
            push!(keep, i)
        end
    end
    return keep
end

function lost_start_summary(S, starts, scales, prs, p_source)
    lost = Int[]
    lost_physical = 0
    lost_truth = 0
    lost_swap = 0
    for (i, pr) in enumerate(prs)
        code = try pr.return_code catch; :unknown end
        code == :success && continue
        push!(lost, i)
        x_true = unscale_solution(scales, starts[i])
        is_physical_solution(S, x_true) && (lost_physical += 1)
        errs = branch_errors(S, x_true)
        errs.truth <= env_float("ODEPE_RECEPTOR_FAST_BRANCH_TOL", 1e-2) && (lost_truth += 1)
        errs.swap <= env_float("ODEPE_RECEPTOR_FAST_BRANCH_TOL", 1e-2) && (lost_swap += 1)
    end
    return Dict(
        "lost_count" => length(lost),
        "lost_physical_source_count" => lost_physical,
        "lost_truth_source_count" => lost_truth,
        "lost_swap_source_count" => lost_swap,
    )
end

function main()
    out = output_path("fallback_probe.jsonl")
    S = receptor_setup()
    pidx = shooting_indices(S)
    P = oracle_params_for_indices(S, pidx)
    ps = parameterized_system(S; scale = true, scale_params = P)
    records = Dict{String, Any}[]

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "shooting_indices" => pidx,
            "shooting_times" => [Float64(S.t_vector[i]) for i in pidx],
            "scale_range" => collect(extrema(ps.scales)),
        ))

        for segment in 1:(length(P) - 1)
            source = fresh_solve(ps.system, ComplexF64.(P[segment]))
            starts_all = source.finite
            keep = physical_full_valid_starts(S, starts_all, ps.scales, P[segment])
            starts_physical = starts_all[keep]

            all_track = track_solve(ps.system, starts_all, ComplexF64.(P[segment]), ComplexF64.(P[segment + 1]))
            all_metrics = classify_solutions(S, all_track.real, ps.scales, P[segment + 1])
            all_lost = lost_start_summary(S, starts_all, ps.scales, HC.path_results(all_track.result), P[segment])
            current_would_fallback = all_track.success < length(starts_all)
            selective_would_fallback =
                !(all_metrics["truth_present"] && all_metrics["swap_present"]) &&
                all_metrics["n_physical"] == 0

            rec = Dict{String, Any}(
                "case" => "all_roots_tracking",
                "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                "source_n_finite" => length(starts_all),
                "source_n_physical_full_valid" => length(starts_physical),
                "seconds" => all_track.seconds,
                "started" => all_track.started,
                "success" => all_track.success,
                "n_finite" => length(all_track.finite),
                "n_real" => length(all_track.real),
                "histogram" => all_track.histogram,
                "current_count_rule_would_fallback" => current_would_fallback,
                "selective_rule_would_fallback" => selective_would_fallback,
            )
            merge!(rec, all_metrics)
            merge!(rec, all_lost)
            write_jsonl(io, rec)
            push!(records, rec)

            physical_track = track_solve(ps.system, starts_physical, ComplexF64.(P[segment]), ComplexF64.(P[segment + 1]))
            physical_metrics = classify_solutions(S, physical_track.real, ps.scales, P[segment + 1])
            rec2 = Dict{String, Any}(
                "case" => "physical_full_valid_only_tracking",
                "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                "source_n_finite" => length(starts_all),
                "source_n_physical_full_valid" => length(starts_physical),
                "seconds" => physical_track.seconds,
                "started" => physical_track.started,
                "success" => physical_track.success,
                "n_finite" => length(physical_track.finite),
                "n_real" => length(physical_track.real),
                "histogram" => physical_track.histogram,
            )
            merge!(rec2, physical_metrics)
            write_jsonl(io, rec2)
            push!(records, rec2)
        end
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
