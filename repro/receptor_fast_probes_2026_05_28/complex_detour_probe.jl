# Complex fixed-endpoint detour probes for receptor parameter homotopy.
#
# Environment knobs:
#   ODEPE_RECEPTOR_FAST_ETAS=1e-3,1e-2,1e-1,0.3
#   ODEPE_RECEPTOR_FAST_SEEDS=1,2,3,4,5,6,7,8,9,10
#   ODEPE_RECEPTOR_FAST_WAYPOINTS=1,3
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/complex_detour_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using LinearAlgebra
using Printf
using Random

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
    out = output_path("complex_detour.jsonl")
    S = receptor_setup()
    pidx = shooting_indices(S)
    P = oracle_params_for_indices(S, pidx)
    ps = parameterized_system(S; scale = true, scale_params = P)
    seeds = env_list("ODEPE_RECEPTOR_FAST_SEEDS", collect(1:10); parse_item = x -> parse(Int, x))
    etas = env_list("ODEPE_RECEPTOR_FAST_ETAS", [1e-3, 1e-2, 1e-1, 0.3]; parse_item = x -> parse(Float64, x))
    waypoint_counts = env_list("ODEPE_RECEPTOR_FAST_WAYPOINTS", [1, 3]; parse_item = x -> parse(Int, x))
    do_generic_seed = env_bool("ODEPE_RECEPTOR_FAST_GENERIC_COMPLEX_SEED", false)
    records = Dict{String, Any}[]

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "shooting_indices" => pidx,
            "shooting_times" => [Float64(S.t_vector[i]) for i in pidx],
            "etas" => etas,
            "seeds" => seeds,
            "waypoint_counts" => waypoint_counts,
            "scale_range" => collect(extrema(ps.scales)),
        ))

        for segment in 1:(length(P) - 1)
            source_fresh = fresh_solve(ps.system, ComplexF64.(P[segment]))
            starts = source_fresh.finite
            write_jsonl(io, Dict(
                "case" => "source_fresh",
                "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                "point" => pidx[segment],
                "seconds" => source_fresh.seconds,
                "n_finite" => length(source_fresh.finite),
                "n_real" => length(source_fresh.real),
                "histogram" => source_fresh.histogram,
            ))

            # Straight baseline for the same segment and same source set.
            straight = track_solve(ps.system, starts, ComplexF64.(P[segment]), ComplexF64.(P[segment + 1]))
            straight_metrics = classify_solutions(S, straight.real, ps.scales, P[segment + 1])
            rec = Dict{String, Any}(
                "case" => "straight",
                "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                "seconds" => straight.seconds,
                "started" => straight.started,
                "success" => straight.success,
                "n_finite" => length(straight.finite),
                "n_real" => length(straight.real),
                "histogram" => straight.histogram,
            )
            merge!(rec, straight_metrics)
            write_jsonl(io, rec)
            push!(records, rec)

            for nmid in waypoint_counts, eta in etas, seed in seeds
                waypoints = complex_waypoints(P[segment], P[segment + 1];
                    eta = eta, n_midpoints = nmid, seed = seed)
                final_sols, legs, seconds = track_waypoints(ps.system, starts, waypoints)
                real_final = [s for s in final_sols if maximum(abs.(imag.(s))) <= 1e-6]
                metrics = classify_solutions(S, real_final, ps.scales, P[segment + 1])
                rec = Dict{String, Any}(
                    "case" => "complex_detour",
                    "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                    "eta" => eta,
                    "seed" => seed,
                    "n_midpoints" => nmid,
                    "seconds" => seconds,
                    "started" => length(starts),
                    "success" => isempty(legs) ? 0 : legs[end]["success"],
                    "n_finite" => length(final_sols),
                    "n_real" => length(real_final),
                    "legs" => legs,
                )
                merge!(rec, metrics)
                write_jsonl(io, rec)
                push!(records, rec)
            end
        end

        if do_generic_seed
            seed = env_int("ODEPE_RECEPTOR_FAST_GENERIC_SEED", 20260528)
            rng = MersenneTwister(seed)
            pmean = ComplexF64.(reduce(+, P) ./ length(P))
            direction = randn(rng, length(pmean))
            pgen = pmean .+ 0.1im .* (abs.(pmean) .+ 1.0) .* direction
            gfresh = fresh_solve(ps.system, pgen)
            write_jsonl(io, Dict(
                "case" => "generic_complex_fresh",
                "seed" => seed,
                "seconds" => gfresh.seconds,
                "n_finite" => length(gfresh.finite),
                "histogram" => gfresh.histogram,
            ))
            for (j, ptarget) in enumerate(P)
                waypoints = complex_waypoints(pgen, ptarget; eta = 0.1, n_midpoints = 1, seed = seed + j)
                final_sols, legs, seconds = track_waypoints(ps.system, gfresh.finite, waypoints)
                real_final = [s for s in final_sols if maximum(abs.(imag.(s))) <= 1e-6]
                metrics = classify_solutions(S, real_final, ps.scales, ptarget)
                rec = Dict{String, Any}(
                    "case" => "generic_complex_to_real",
                    "target_point" => pidx[j],
                    "seed" => seed,
                    "seconds" => seconds,
                    "n_finite" => length(final_sols),
                    "n_real" => length(real_final),
                    "legs" => legs,
                )
                merge!(rec, metrics)
                write_jsonl(io, rec)
                push!(records, rec)
            end
        end
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
