# Test multi-point parameter homotopy and broader model coverage
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("test/test_multipoint_homotopy.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Test
using Printf
using OrderedCollections

function test_model(name, pep; n_data = 201, t_interval = nothing, n_points = 2)
    println("\n--- $name (n=$n_data, $n_points pts) ---")

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]

    pep_data = ODEParameterEstimation.sample_problem_data(pep,
        EstimationOptions(datasize = n_data, time_interval = ti, noise_level = 0.0, nooutput = true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try
        ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    catch
        (pep_data, nothing)
    end

    setup = ODEParameterEstimation.setup_parameter_estimation(pep_work;
        interpolator = ODEParameterEstimation.aaad_gpr_pivot, nooutput = true)

    model = pep_work.model.system
    mq = pep_work.measured_quantities
    ordered_model = ODEParameterEstimation.OrderedODESystem(
        model, ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model))
    si_tmpl, _ = ODEParameterEstimation.prepare_si_template_with_structural_fix(
        ordered_model, mq, pep_work.data_sample, setup.good_DD, false;
        states = ModelingToolkit.unknowns(model), params = ModelingToolkit.parameters(model), infolevel = 0)

    # Build template
    mpt = build_multipoint_template(pep_work, setup, si_tmpl; n_points = n_points, diagnostics = false)
    @printf("  Template: %d eqs, %d solve, %d data, square=%s\n",
        length(mpt.stripped_equations), length(mpt.solve_vars), length(mpt.data_vars),
        length(mpt.stripped_equations) == length(mpt.solve_vars))

    if length(mpt.stripped_equations) != length(mpt.solve_vars)
        println("  SKIP: not square")
        return (name = name, err_direct = Inf, err_homotopy = Inf, n_pairs = 0)
    end

    # True params
    real_params = OrderedDict{String, Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end

    n_t = length(pep_work.data_sample["t"])

    # Direct solve at one pair
    t_indices_1 = [round(Int, n_t * 0.25), round(Int, n_t * 0.75)]
    eval_1 = evaluate_multipoint_template(mpt, t_indices_1, setup.interpolants, pep_work.data_sample)
    sols_direct = solve_multipoint_direct(eval_1)

    best_direct = Inf
    for sol in sols_direct
        pvals = Float64[sol[i] for i in mpt.param_var_indices]
        me = 0.0
        for (j, pn) in enumerate(mpt.param_names)
            haskey(real_params, pn) && (me = max(me, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
        end
        best_direct = min(best_direct, me)
    end
    @printf("  Direct: %d solutions, best err=%.6f\n", length(sols_direct), best_direct)

    # Parameter homotopy across multiple pairs
    pairs = select_time_point_pairs(n_t, 4, n_points)
    evals = [evaluate_multipoint_template(mpt, pair, setup.interpolants, pep_work.data_sample) for pair in pairs]
    sols_homotopy = solve_multipoint_parameterized(mpt, evals)

    best_homotopy = Inf
    total_sols = 0
    for (pidx, pair_sols) in enumerate(sols_homotopy)
        total_sols += length(pair_sols)
        for sol in pair_sols
            pvals = Float64[sol[i] for i in mpt.param_var_indices]
            me = 0.0
            for (j, pn) in enumerate(mpt.param_names)
                haskey(real_params, pn) && (me = max(me, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
            end
            best_homotopy = min(best_homotopy, me)
        end
    end
    @printf("  Homotopy: %d pairs → %d total solutions, best err=%.6f\n",
        length(pairs), total_sols, best_homotopy)

    return (name = name, err_direct = best_direct, err_homotopy = best_homotopy, n_pairs = length(pairs))
end

# ═══════════════════════════════════════════════════════════════════════
println("=" ^ 70)
println("Multi-Point Template: Parameter Homotopy + Model Coverage")
println("=" ^ 70)

results = []

@testset "MultiPoint Parameter Homotopy" begin
    r = test_model("simple", ODEParameterEstimation.simple(); t_interval = [0.0, 1.0])
    @test r.err_direct < 0.01
    push!(results, r)

    r = test_model("lotka_volterra", ODEParameterEstimation.lotka_volterra())
    @test r.err_direct < 0.01
    push!(results, r)

    r = test_model("fitzhugh_nagumo", ODEParameterEstimation.fitzhugh_nagumo())
    push!(results, r)

    r = test_model("biohydrogenation", ODEParameterEstimation.biohydrogenation(); t_interval = [0.0, 1.0])
    push!(results, r)

    r = test_model("seir", ODEParameterEstimation.seir())
    push!(results, r)
end

println("\n\n", "=" ^ 70)
println("SUMMARY")
println("=" ^ 70)
@printf("%-20s  %10s  %10s  %6s\n", "Model", "Direct", "Homotopy", "Pairs")
println("-" ^ 55)
for r in results
    @printf("%-20s  %10.6f  %10.6f  %6d\n", r.name, r.err_direct, r.err_homotopy, r.n_pairs)
end
println("=" ^ 70)
