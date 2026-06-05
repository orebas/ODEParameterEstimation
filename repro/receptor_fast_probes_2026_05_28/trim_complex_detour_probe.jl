# Complex detours on alternate trim systems.
#
# This combines the two strongest signals from the fast probes: low mixed-volume
# trims and fixed-endpoint complex detours.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/trim_complex_detour_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using LinearAlgebra
using Printf
using Random

function trim_for_label(S, label::AbstractString)
    if label == "current"
        return select_trim(S, :current; J = rank_matrix(S))
    elseif label == "pins_low_order_first"
        return select_trim(S, :pins_low_order_first; J = rank_matrix(S))
    elseif label == "support_first"
        return select_trim(S, :support_first; J = rank_matrix(S))
    elseif startswith(label, "pins_cap_")
        cap = parse(Int, replace(label, "pins_cap_" => ""))
        return select_trim(S, :pins_low_order_first; max_pin_order = cap, J = rank_matrix(S))
    else
        error("Unknown trim label: $label")
    end
end

function complex_waypoints(p0, p1; eta::Float64, n_midpoints::Int, seed::Int)
    rng = MersenneTwister(seed)
    waypoints = Vector{Vector{ComplexF64}}()
    push!(waypoints, ComplexF64.(p0))
    direction = randn(rng, length(p0))
    norm(direction) > 0 && (direction ./= norm(direction))
    for j in 1:n_midpoints
        s = j / (n_midpoints + 1)
        base = (1 - s) .* ComplexF64.(p0) .+ s .* ComplexF64.(p1)
        amp = eta .* (abs.(base) .+ 1.0) .* sin(pi * s)
        push!(waypoints, base .+ im .* amp .* direction)
    end
    push!(waypoints, ComplexF64.(p1))
    return waypoints
end

function track_waypoints(sys, starts, waypoints)
    current = starts
    leg_records = Dict{String, Any}[]
    total_seconds = 0.0
    for leg in 1:(length(waypoints) - 1)
        tr = track_solve(sys, current, waypoints[leg], waypoints[leg + 1])
        total_seconds += tr.seconds
        push!(leg_records, Dict(
            "leg" => leg,
            "started" => tr.started,
            "success" => tr.success,
            "n_finite" => length(tr.finite),
            "n_real" => length(tr.real),
            "seconds" => tr.seconds,
            "histogram" => tr.histogram,
        ))
        current = tr.finite
        isempty(current) && break
    end
    return current, leg_records, total_seconds
end

function main()
    out = output_path("trim_complex_detour.jsonl")
    S = receptor_setup()
    pidx = shooting_indices(S)
    P = oracle_params_for_indices(S, pidx)
    labels = env_list("ODEPE_RECEPTOR_TRIM_DETOUR_CASES",
        ["pins_low_order_first", "pins_cap_4"]; parse_item = string)
    seeds = env_list("ODEPE_RECEPTOR_FAST_SEEDS", collect(1:10); parse_item = x -> parse(Int, x))
    etas = env_list("ODEPE_RECEPTOR_FAST_ETAS", [0.03, 0.1]; parse_item = x -> parse(Float64, x))
    waypoint_counts = env_list("ODEPE_RECEPTOR_FAST_WAYPOINTS", [1, 3]; parse_item = x -> parse(Int, x))
    compute_mv = env_bool("ODEPE_RECEPTOR_FAST_MIXED_VOLUME", true)
    records = Dict{String, Any}[]

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "trim_cases" => labels,
            "shooting_indices" => pidx,
            "shooting_times" => [Float64(S.t_vector[i]) for i in pidx],
            "etas" => etas,
            "seeds" => seeds,
            "waypoint_counts" => waypoint_counts,
        ))

        for label in labels
            trim = trim_for_label(S, label)
            ps = parameterized_system(S, trim.equations; scale = true, scale_params = P)
            write_jsonl(io, Dict(
                "case" => "trim_metadata",
                "trim_case" => label,
                "rank" => trim.rank,
                "rank_complete" => trim.rank == length(S.solve_vars),
                "selected_equation_indices" => trim.selected,
                "emergency_high_order_equations" => trim.emergency,
                "mixed_volume" => compute_mv ? safe_mixed_volume(ps.system) : missing,
                "scale_range" => collect(extrema(ps.scales)),
            ))

            for segment in 1:(length(P) - 1)
                source = fresh_solve(ps.system, ComplexF64.(P[segment]))
                source_metrics = classify_solutions(S, source.real, ps.scales, P[segment])
                write_jsonl(io, merge(Dict(
                    "case" => "source_fresh",
                    "trim_case" => label,
                    "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                    "seconds" => source.seconds,
                    "n_finite" => length(source.finite),
                    "n_real" => length(source.real),
                    "histogram" => source.histogram,
                ), source_metrics))

                straight = track_solve(ps.system, source.finite, ComplexF64.(P[segment]), ComplexF64.(P[segment + 1]))
                straight_metrics = classify_solutions(S, straight.real, ps.scales, P[segment + 1])
                rec = merge(Dict(
                    "case" => "straight",
                    "trim_case" => label,
                    "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                    "seconds" => straight.seconds,
                    "started" => straight.started,
                    "success" => straight.success,
                    "n_finite" => length(straight.finite),
                    "n_real" => length(straight.real),
                    "histogram" => straight.histogram,
                ), straight_metrics)
                write_jsonl(io, rec)
                push!(records, rec)

                for nmid in waypoint_counts, eta in etas, seed in seeds
                    waypoints = complex_waypoints(P[segment], P[segment + 1];
                        eta = eta, n_midpoints = nmid, seed = seed)
                    final_sols, legs, seconds = track_waypoints(ps.system, source.finite, waypoints)
                    real_final = [s for s in final_sols if maximum(abs.(imag.(s))) <= 1e-6]
                    metrics = classify_solutions(S, real_final, ps.scales, P[segment + 1])
                    rec = merge(Dict(
                        "case" => "complex_detour",
                        "trim_case" => label,
                        "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                        "eta" => eta,
                        "seed" => seed,
                        "n_midpoints" => nmid,
                        "seconds" => seconds,
                        "started" => length(source.finite),
                        "success" => isempty(legs) ? 0 : legs[end]["success"],
                        "n_finite" => length(final_sols),
                        "n_real" => length(real_final),
                        "legs" => legs,
                    ), metrics)
                    write_jsonl(io, rec)
                    push!(records, rec)
                end
            end
        end
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
