# Test point selection strategies for multi-point template
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("test/test_point_selection.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Printf
using OrderedCollections

function test_strategies(name, pep; n_data = 201, t_interval = nothing, noise_level = 0.01)
    println("\n", "=" ^ 70)
    @printf("%s — n=%d, noise=%.2f\n", name, n_data, noise_level)
    println("=" ^ 70)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]

    pep_data = ODEParameterEstimation.sample_problem_data(pep,
        EstimationOptions(datasize = n_data, time_interval = ti, noise_level = noise_level, nooutput = true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try
        ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    catch
        (pep_data, nothing)
    end

    setup = ODEParameterEstimation.setup_parameter_estimation(pep_work;
        interpolator = ODEParameterEstimation.aaad_gpr_pivot, nooutput = true)

    model = pep_work.model.system; mq = pep_work.measured_quantities
    ordered_model = ODEParameterEstimation.OrderedODESystem(
        model, ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model))
    si_tmpl, _ = ODEParameterEstimation.prepare_si_template_with_structural_fix(
        ordered_model, mq, pep_work.data_sample, setup.good_DD, false;
        states = ModelingToolkit.unknowns(model), params = ModelingToolkit.parameters(model), infolevel = 0)

    mpt = build_multipoint_template(pep_work, setup, si_tmpl; n_points = 2, diagnostics = false)
    if length(mpt.stripped_equations) != length(mpt.solve_vars)
        println("  NOT SQUARE — skipping")
        return
    end

    template_DD = hasproperty(si_tmpl, :template_DD) ? si_tmpl.template_DD : setup.good_DD
    t_vec = pep_work.data_sample["t"]
    n_t = length(t_vec)

    real_params = OrderedDict{String, Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end

    function score_pairs(pairs_label, pairs)
        evals = MultiPointEvaluation[]
        for pair in pairs
            try
                ev = evaluate_multipoint_template(mpt, pair, setup.interpolants, pep_work.data_sample)
                all(isfinite, ev.data_values) && push!(evals, ev)
            catch; end
        end

        if isempty(evals)
            @printf("  %-25s: NO valid pairs\n", pairs_label)
            return Inf
        end

        t0 = time()
        solutions_by_pair = try
            solve_multipoint_parameterized(mpt, evals;
                options = Dict(:show_progress => false, :real_tol => 1e-6))
        catch e
            @printf("  %-25s: SOLVE FAILED: %s\n", pairs_label, sprint(showerror, e)[1:min(60, end)])
            return Inf
        end
        solve_time = time() - t0

        best_err = Inf
        total_sols = sum(length(s) for s in solutions_by_pair)
        for pair_sols in solutions_by_pair
            for sol in pair_sols
                pvals = Float64[sol[i] for i in mpt.param_var_indices]
                me = 0.0
                for (j, pn) in enumerate(mpt.param_names)
                    haskey(real_params, pn) && (me = max(me, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
                end
                best_err = min(best_err, me)
            end
        end

        pair_strs = [string(round.(t_vec[p]; digits=2)) for p in pairs[1:min(3, end)]]
        @printf("  %-25s: err=%.6f  %d sols  %.1fs  pairs=%s%s\n",
            pairs_label, best_err, total_sols, solve_time,
            join(pair_strs, ", "), length(pairs) > 3 ? "..." : "")
        return best_err
    end

    # Strategy 1: Spread (baseline)
    pairs_spread = select_time_point_pairs(n_t, 6, 2; strategy = :spread, margin = 0.1)
    score_pairs("spread (baseline)", pairs_spread)

    # Strategy 2: Random
    pairs_random = select_time_point_pairs(n_t, 6, 2; strategy = :random, margin = 0.1)
    score_pairs("random", pairs_random)

    # Strategy 3: GP quality
    pairs_gp = try
        select_time_point_pairs_gp_quality(n_t, 6, 2,
            setup.interpolants, mq, template_DD, t_vec; margin = 0.1, max_order = 2)
    catch e
        println("  GP quality selection failed: ", sprint(showerror, e)[1:min(60, end)])
        Vector{Vector{Int}}()
    end
    !isempty(pairs_gp) && score_pairs("gp_quality", pairs_gp)

    # Strategy 4: Sensitivity (D-optimal inspired)
    pairs_sens = try
        select_time_point_pairs_sensitivity(mpt, 6,
            setup.interpolants, pep_work.data_sample; margin = 0.1, n_candidates = 40)
    catch e
        println("  Sensitivity selection failed: ", sprint(showerror, e)[1:min(60, end)])
        Vector{Vector{Int}}()
    end
    !isempty(pairs_sens) && score_pairs("sensitivity", pairs_sens)

    # Strategy 5: Homotopy-probed
    pairs_hom = try
        select_time_point_pairs_homotopy_probed(mpt, 6,
            setup.interpolants, pep_work.data_sample; margin = 0.1, n_candidates = 20)
    catch e
        println("  Homotopy-probed selection failed: ", sprint(showerror, e)[1:min(60, end)])
        Vector{Vector{Int}}()
    end
    !isempty(pairs_hom) && score_pairs("homotopy_probed", pairs_hom)
end

# ═══════════════════════════════════════════════════════════════════════
println("=" ^ 70)
println("Point Selection Strategy Comparison")
println("=" ^ 70)

test_strategies("lotka_volterra", ODEParameterEstimation.lotka_volterra(); noise_level = 0.01)
test_strategies("simple", ODEParameterEstimation.simple(); t_interval = [0.0, 1.0], noise_level = 0.01)
test_strategies("seir", ODEParameterEstimation.seir(); noise_level = 0.01)

println("\n", "=" ^ 70)
println("Done!")
println("=" ^ 70)
