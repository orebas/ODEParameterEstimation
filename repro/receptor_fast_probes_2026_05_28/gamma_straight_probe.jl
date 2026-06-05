# True gamma-trick probe using HC.jl's StraightLineHomotopy between fixed systems.
#
# This is distinct from ParameterHomotopy. HC.jl's ParameterHomotopy uses the
# straight parameter path F(x; t*p_start + (1-t)*p_target) and has no gamma.
# This script instead tracks:
#     H(x,t) = gamma*t*F(x;p_start) + (1-t)*F(x;p_target)
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/gamma_straight_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using Printf
using Random

function trim_for_label(S, label::AbstractString)
    if label == "current"
        return (equations = S.equations, selected = S.selected_equation_indices,
            emergency = Int[], rank = length(S.solve_vars))
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

function gamma_for_seed(seed::Int)
    rng = MersenneTwister(seed)
    theta = 2 * pi * rand(rng)
    return cos(theta) + im * sin(theta)
end

function gamma_track(sys, starts, p0, p1, gamma)
    elapsed = @elapsed res = HC.solve(sys, sys, starts;
        start_parameters = p0,
        target_parameters = p1,
        gamma = gamma,
        show_progress = false)
    sets = solution_sets(res)
    return (result = res, seconds = elapsed, finite = sets.finite, real = sets.real,
        histogram = path_histogram(res),
        success = count(pr -> (try pr.return_code == :success catch; false end), HC.path_results(res)),
        started = length(starts))
end

function main()
    out = output_path("gamma_straight.jsonl")
    S = receptor_setup()
    pidx = shooting_indices(S)
    P = oracle_params_for_indices(S, pidx)
    labels = env_list("ODEPE_RECEPTOR_GAMMA_CASES", ["support_first"]; parse_item = string)
    seeds = env_list("ODEPE_RECEPTOR_FAST_SEEDS", collect(1:10); parse_item = x -> parse(Int, x))
    records = Dict{String, Any}[]

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "gamma_cases" => labels,
            "seeds" => seeds,
            "shooting_indices" => pidx,
            "shooting_times" => [Float64(S.t_vector[i]) for i in pidx],
        ))

        for label in labels
            trim = trim_for_label(S, label)
            ps = parameterized_system(S, trim.equations; scale = true, scale_params = P)
            write_jsonl(io, Dict(
                "case" => "system_metadata",
                "gamma_case" => label,
                "selected_equation_indices" => trim.selected,
                "emergency_high_order_equations" => trim.emergency,
                "mixed_volume" => safe_mixed_volume(ps.system),
                "scale_range" => collect(extrema(ps.scales)),
            ))

            for segment in 1:(length(P) - 1)
                source = fresh_solve(ps.system, ComplexF64.(P[segment]))
                source_metrics = classify_solutions(S, source.real, ps.scales, P[segment])
                write_jsonl(io, merge(Dict(
                    "case" => "source_fresh",
                    "gamma_case" => label,
                    "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                    "seconds" => source.seconds,
                    "n_finite" => length(source.finite),
                    "n_real" => length(source.real),
                    "histogram" => source.histogram,
                ), source_metrics))

                straight = track_solve(ps.system, source.finite, ComplexF64.(P[segment]), ComplexF64.(P[segment + 1]))
                straight_metrics = classify_solutions(S, straight.real, ps.scales, P[segment + 1])
                rec = merge(Dict(
                    "case" => "parameter_straight",
                    "gamma_case" => label,
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

                for seed in seeds
                    gamma = gamma_for_seed(seed)
                    tr = gamma_track(ps.system, source.finite, ComplexF64.(P[segment]), ComplexF64.(P[segment + 1]), gamma)
                    metrics = classify_solutions(S, tr.real, ps.scales, P[segment + 1])
                    rec = merge(Dict(
                        "case" => "gamma_straight",
                        "gamma_case" => label,
                        "segment" => "$(pidx[segment])->$(pidx[segment + 1])",
                        "seed" => seed,
                        "gamma" => string(gamma),
                        "seconds" => tr.seconds,
                        "started" => tr.started,
                        "success" => tr.success,
                        "n_finite" => length(tr.finite),
                        "n_real" => length(tr.real),
                        "histogram" => tr.histogram,
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
