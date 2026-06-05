# Baseline receptor parameter-homotopy probe.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/baseline_homotopy_probe.jl
#
# Writes JSONL records to out/baseline_homotopy.jsonl.

include("common.jl")
using .ReceptorFastProbes
using Dates
using Printf

function record_fresh!(io, records, S, ps, scales, label, point_i, p)
    fr = fresh_solve(ps.system, ComplexF64.(p))
    metrics = classify_solutions(S, fr.real, scales, p)
    rec = Dict{String, Any}(
        "case" => label,
        "kind" => "fresh",
        "point" => point_i,
        "time" => Float64(S.t_vector[point_i]),
        "seconds" => fr.seconds,
        "ntracked" => fr.ntracked,
        "n_finite" => length(fr.finite),
        "n_real" => length(fr.real),
        "histogram" => fr.histogram,
    )
    merge!(rec, metrics)
    write_jsonl(io, rec)
    push!(records, rec)
    return fr
end

function record_track!(io, records, S, ps, scales, label, src_i, dst_i, p0, p1, starts)
    tr = track_solve(ps.system, starts, ComplexF64.(p0), ComplexF64.(p1))
    metrics = classify_solutions(S, tr.real, scales, p1)
    rec = Dict{String, Any}(
        "case" => label,
        "kind" => "track",
        "segment" => "$(src_i)->$(dst_i)",
        "source_point" => src_i,
        "target_point" => dst_i,
        "source_time" => Float64(S.t_vector[src_i]),
        "target_time" => Float64(S.t_vector[dst_i]),
        "seconds" => tr.seconds,
        "started" => tr.started,
        "success" => tr.success,
        "n_finite" => length(tr.finite),
        "n_real" => length(tr.real),
        "histogram" => tr.histogram,
    )
    merge!(rec, metrics)
    write_jsonl(io, rec)
    push!(records, rec)
    return tr
end

function main()
    out = output_path("baseline_homotopy.jsonl")
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
            "n_equations" => length(S.equations),
            "n_solve_vars" => length(S.solve_vars),
            "scale_range" => collect(extrema(ps.scales)),
            "mixed_volume" => env_bool("ODEPE_RECEPTOR_FAST_MIXED_VOLUME", false) ?
                safe_mixed_volume(ps.system) : nothing,
        ))

        fresh = Dict{Int, Any}()
        for (j, point_i) in enumerate(pidx)
            fresh[point_i] = record_fresh!(io, records, S, ps, ps.scales,
                "baseline", point_i, P[j])
        end

        for j in 1:(length(pidx) - 1)
            src_i = pidx[j]
            dst_i = pidx[j + 1]
            starts = fresh[src_i].finite
            record_track!(io, records, S, ps, ps.scales, "baseline",
                src_i, dst_i, P[j], P[j + 1], starts)
        end

        for j in length(pidx):-1:2
            src_i = pidx[j]
            dst_i = pidx[j - 1]
            starts = fresh[src_i].finite
            record_track!(io, records, S, ps, ps.scales, "reverse",
                src_i, dst_i, P[j], P[j - 1], starts)
        end
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
