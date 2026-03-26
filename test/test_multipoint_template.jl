# Test multi-point template system
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("test/test_multipoint_template.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Test
using Printf
using OrderedCollections

function test_build_template(name, pep; n_data = 201, t_interval = nothing, n_points = 2)
    println("\n--- Testing build_multipoint_template: $name (n=$n_data, $n_points pts) ---")

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

    # Build the multi-point template
    mpt = build_multipoint_template(pep_work, setup, si_tmpl;
        n_points = n_points, diagnostics = true)

    # Verify basic properties
    @test mpt.n_points == n_points
    n_eqs = length(mpt.stripped_equations)
    n_solve = length(mpt.solve_vars)
    n_data = length(mpt.data_vars)
    is_square = n_eqs == n_solve

    @printf("  Stripped: %d eqs, %d solve_vars, %d data_vars\n", n_eqs, n_solve, n_data)
    @printf("  Square: %s\n", is_square)
    @printf("  Params (%d): %s\n", length(mpt.param_var_indices), join(mpt.param_names, ", "))
    @printf("  Per-point data ranges: %s\n", mpt.per_point_data_var_ranges)

    @test is_square
    @test length(mpt.param_var_indices) > 0
    @test length(mpt.eq_metadata) == n_eqs

    return (mpt = mpt, pep_work = pep_work, setup = setup)
end

function test_evaluate_and_solve(name, pep; n_data = 201, t_interval = nothing)
    println("\n--- Testing evaluate + solve: $name ---")

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
    mpt = build_multipoint_template(pep_work, setup, si_tmpl; n_points = 2, diagnostics = false)
    @test length(mpt.stripped_equations) == length(mpt.solve_vars)

    # Evaluate at probe points
    n_t = length(pep_work.data_sample["t"])
    t_indices = [round(Int, n_t * 0.25), round(Int, n_t * 0.75)]
    eval_result = evaluate_multipoint_template(mpt, t_indices, setup.interpolants, pep_work.data_sample)

    @test length(eval_result.data_values) == length(mpt.data_vars)
    @test length(eval_result.t_values) == 2
    @test all(isfinite, eval_result.data_values)
    println("  Data values: $(length(eval_result.data_values)) values, all finite: $(all(isfinite, eval_result.data_values))")

    # Direct solve
    println("  Solving...")
    solutions = solve_multipoint_direct(eval_result)
    println("  Found $(length(solutions)) solutions")

    # Score against true params
    real_params = OrderedDict{String, Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end

    best_err = Inf
    for (si, sol) in enumerate(solutions)
        pvals = Float64[sol[i] for i in mpt.param_var_indices]
        me = 0.0
        for (j, pn) in enumerate(mpt.param_names)
            haskey(real_params, pn) && (me = max(me, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
        end
        if si <= 5
            param_str = join([@sprintf("%s=%.4f", pn, pvals[j]) for (j, pn) in enumerate(mpt.param_names) if haskey(real_params, pn)], " ")
            @printf("    sol%d: %s  err=%.4f\n", si, param_str, me)
        end
        best_err = min(best_err, me)
    end
    @printf("  Best error: %.6f\n", best_err)

    return best_err
end

# ═══════════════════════════════════════════════════════════════════════
# Run tests
# ═══════════════════════════════════════════════════════════════════════

println("=" ^ 70)
println("Multi-Point Template System Tests")
println("=" ^ 70)

@testset "MultiPointTemplate build" begin
    test_build_template("lotka_volterra", ODEParameterEstimation.lotka_volterra())
    test_build_template("simple", ODEParameterEstimation.simple(); t_interval = [0.0, 1.0])
end

@testset "MultiPointTemplate evaluate + solve" begin
    err_lv = test_evaluate_and_solve("lotka_volterra", ODEParameterEstimation.lotka_volterra())
    @test err_lv < 0.01  # should recover params well with noiseless data

    err_simple = test_evaluate_and_solve("simple", ODEParameterEstimation.simple(); t_interval = [0.0, 1.0])
    @test err_simple < 0.01
end

println("\n", "=" ^ 70)
println("All multi-point template tests passed!")
println("=" ^ 70)
