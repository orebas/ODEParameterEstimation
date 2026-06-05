# Real straight-path subdivision probe.
#
# If real subdivisions fail but complex detours work, the obstruction is likely
# a real discriminant crossing rather than step-size budget.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/path_subdivision_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using Printf

function real_waypoints(p0, p1, n_segments::Int)
    pts = Vector{Vector{ComplexF64}}()
    for j in 0:n_segments
        s = j / n_segments
        push!(pts, (1 - s) .* ComplexF64.(p0) .+ s .* ComplexF64.(p1))
    end
    return pts
end

function track_subdivided(sys, starts, waypoints)
    current = starts
    total_seconds = 0.0
    legs = Dict{String, Any}[]
    for leg in 1:(length(waypoints) - 1)
        tr = track_solve(sys, current, waypoints[leg], waypoints[leg + 1])
        total_seconds += tr.seconds
        push!(legs, Dict(
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
    return current, legs, total_seconds
end

function main()
    out = output_path("path_subdivision.jsonl")
    S = receptor_setup()
    pidx = shooting_indices(S)
    P = oracle_params_for_indices(S, pidx)
    ps = parameterized_system(S; scale = true, scale_params = P)
    segment_counts = env_list("ODEPE_RECEPTOR_FAST_REAL_SEGMENTS", [1, 2, 4, 8]; parse_item = x -> parse(Int, x))
    records = Dict{String, Any}[]

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "shooting_indices" => pidx,
            "real_segment_counts" => segment_counts,
        ))

        for segment in 1:(length(P) - 1)
            source = fresh_solve(ps.system, ComplexF64.(P[segment]))
            for nseg in segment_counts
                final_sols, legs, seconds = track_subdivided(
                    ps.system, source.finite, real_waypoints(P[segment], P[segment + 1], nseg))
                real_final = [s for s in final_sols if maximum(abs.(imag.(s))) <= 1e-6]
                metrics = classify_solutions(S, real_final, ps.scales, P[segment + 1])
                rec = Dict{String, Any}(
                    "case" => "real_subdivision",
                    "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                    "n_segments" => nseg,
                    "seconds" => seconds,
                    "started" => length(source.finite),
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
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
