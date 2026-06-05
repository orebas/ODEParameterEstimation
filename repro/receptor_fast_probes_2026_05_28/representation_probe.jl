# Receptor representation probes.
#
# Tests whether a simple coordinate change around the observed sum improves the
# symbolic template before touching production model-rewrite code.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/representation_probe.jl
#
# Optional:
#   ODEPE_RECEPTOR_REP_SOLVE=1

include("common.jl")
using .ReceptorFastProbes
using Dates
using Printf

function maybe_solve_first_point!(rec, S)
    env_bool("ODEPE_RECEPTOR_REP_SOLVE", false) || return rec
    pidx = shooting_indices(S)
    P = oracle_params_for_indices(S, pidx)
    ps = parameterized_system(S; scale = true, scale_params = P)
    fr = fresh_solve(ps.system, ComplexF64.(P[1]))
    metrics = classify_solutions(S, fr.real, ps.scales, P[1])
    rec["fresh_point"] = pidx[1]
    rec["fresh_seconds"] = fr.seconds
    rec["fresh_n_finite"] = length(fr.finite)
    rec["fresh_n_real"] = length(fr.real)
    rec["fresh_histogram"] = fr.histogram
    merge!(rec, Dict("fresh_" * k => v for (k, v) in metrics))
    return rec
end

function _series_by_observable_name(S, name::AbstractString)
    for mq in S.measured_quantities
        lhs_name = replace(string(mq.lhs), "(t)" => "")
        if lhs_name == name && haskey(S.spep.data_sample, mq.rhs)
            return S.spep.data_sample[mq.rhs]
        end
    end
    for (k, v) in S.spep.data_sample
        key = replace(string(k), "(t)" => "")
        if key == name || occursin(name, key)
            return v
        end
    end
    error("could not find observable series for $name; keys=$(collect(keys(S.spep.data_sample)))")
end

function conservation_record(S)
    y1 = _series_by_observable_name(S, "y1")
    y2 = _series_by_observable_name(S, "y2")
    total = y1 .+ y2
    return Dict{String, Any}(
        "case" => "conservation_observable_check",
        "status" => "diagnostic_only",
        "max_abs_total_drift" => maximum(abs.(total .- total[1])),
        "total_ligand_from_data" => Float64(total[1]),
        "automation_candidate" => maximum(abs.(total .- total[1])) <= 1e-9,
        "note" => "If y1+y2 is constant, a future automated rewrite can replace the observed sum state with total-y1; this script does not change the production system.",
    )
end

function main()
    out = output_path("representation_probe.jsonl")
    kinds = [:original, :sum_ca, :sum_diff]
    records = Dict{String, Any}[]
    compute_mv = env_bool("ODEPE_RECEPTOR_FAST_MIXED_VOLUME", false)

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "model_kinds" => string.(kinds),
            "compute_mixed_volume" => compute_mv,
            "do_solve" => env_bool("ODEPE_RECEPTOR_REP_SOLVE", false),
        ))

        original_for_conservation = nothing
        for kind in kinds
            rec = Dict{String, Any}("case" => "representation", "model_kind" => string(kind))
            try
                S = receptor_setup(model_kind = kind)
                kind == :original && (original_for_conservation = S)
                merge!(rec, summarize_template(S; compute_mixed_volume = compute_mv))
                maybe_solve_first_point!(rec, S)
            catch err
                rec["error"] = sprint(showerror, err)
            end
            write_jsonl(io, rec)
            push!(records, rec)
        end

        if !isnothing(original_for_conservation)
            rec = conservation_record(original_for_conservation)
            write_jsonl(io, rec)
            push!(records, rec)
        end
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
