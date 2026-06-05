# Shooting-point and jet-scale probe.
#
# This is the cheapest way to find candidate start/target points before running
# full HC sweeps. Set ODEPE_RECEPTOR_POINT_SOLVE=1 to also fresh-solve each point.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/point_selection_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using Printf

function default_times()
    return [-0.50, -0.40, -0.32, -0.20, -0.10, 0.0, 0.20, 0.50]
end

function derivative_order_summary(S, p)
    by_order = Dict{Int, Float64}()
    for (j, dv) in enumerate(S.data_vars)
        j > length(p) && continue
        order = ReceptorFastProbes.data_var_order(dv)
        by_order[order] = max(get(by_order, order, 0.0), abs(Float64(p[j])))
    end
    return Dict(string(k) => v for (k, v) in by_order)
end

function main()
    out = output_path("point_selection.jsonl")
    S = receptor_setup()
    times = env_list("ODEPE_RECEPTOR_POINT_TIMES", default_times(); parse_item = x -> parse(Float64, x))
    do_solve = env_bool("ODEPE_RECEPTOR_POINT_SOLVE", false)
    records = Dict{String, Any}[]

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "times" => times,
            "do_solve" => do_solve,
        ))

        params_by_time = [oracle_params(S, t) for t in times]
        ps = parameterized_system(S; scale = true, scale_params = params_by_time)
        for (t, p) in zip(times, params_by_time)
            rec = Dict{String, Any}(
                "case" => "point_metric",
                "time" => t,
                "max_abs_data_value" => maximum(abs.(p)),
                "by_derivative_order" => derivative_order_summary(S, p),
            )
            if do_solve
                fr = fresh_solve(ps.system, ComplexF64.(p))
                metrics = classify_solutions(S, fr.real, ps.scales, p)
                rec["fresh_seconds"] = fr.seconds
                rec["fresh_ntracked"] = fr.ntracked
                rec["fresh_n_finite"] = length(fr.finite)
                rec["fresh_n_real"] = length(fr.real)
                rec["fresh_histogram"] = fr.histogram
                merge!(rec, Dict("fresh_" * k => v for (k, v) in metrics))
            end
            write_jsonl(io, rec)
            push!(records, rec)
        end
    end

    println("Wrote ", out)
    print_summary_table(records)
end

main()
