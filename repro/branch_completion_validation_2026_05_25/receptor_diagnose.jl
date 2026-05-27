# Deep dive on receptor: are the derivatives accurate? how many orders needed?
# And the decisive split — does the system solve with PERFECT (oracle) derivatives
# but fail with AAAD (=> interpolation problem), or fail even with perfect data
# (=> structural). Single evaluation point, 0 noise.
using ODEParameterEstimation
using Printf
const OPE = ODEParameterEstimation

pep = OPE.receptor_subtype_binding_branch()
opts = EstimationOptions(datasize = 101, noise_level = 0.0,
    interpolator = InterpolatorAAAD, interpolators = [InterpolatorAAAD],
    system_solver = SolverHC, use_si_template = true, nooutput = true)
spep = sample_problem_data(pep, opts)

println("="^72)
println("1. DERIVATIVE ACCURACY  (AAAD, single point, 0 noise)")
println("="^72)
da = diagnose_derivative_accuracy(spep; interpolator = OPE.aaad, interpolator_name = "aaad")
@printf("t_eval = %.4f    max_required_order = %d\n", da.t_eval, da.max_required_order)
@printf("WORST: obs=%s  order=%d  rel_error=%.3e\n", da.worst_obs, da.worst_order, da.worst_rel_error)
println("per (observable, derivative order):")
for e in sort(da.entries, by = x -> (x.obs, x.order))
    @printf("  %-8s ord %d   true=% .6e   interp=% .6e   rel_err=%.3e\n",
        e.obs, e.order, e.true_val, e.interp_val, e.rel_error)
end

println("\n", "="^72)
println("2. POLYNOMIAL SYSTEM:  PERFECT (oracle) vs PRODUCTION (AAAD) derivatives")
println("="^72)
ps = diagnose_polynomial_system(spep; interpolator = OPE.aaad)
@printf("system: %d eqs, %d vars, square=%s\n", ps.n_equations, ps.n_variables, ps.is_square)
@printf("PERFECT (oracle) data : %d real roots | resid@truth=%.3e | closest-to-truth dist=%.3e\n",
    ps.n_solutions_perfect, ps.true_residual_perfect, ps.closest_distance_perfect)
@printf("PRODUCTION (AAAD) data: %d real roots | resid@truth=%.3e | closest-to-truth dist=%.3e\n",
    ps.n_solutions_production, ps.true_residual_production, ps.closest_distance_production)

println("\ndata variables — oracle (true) vs AAAD (prod):")
for (l, dt, dp) in zip(ps.data_var_labels, ps.data_var_true, ps.data_var_prod)
    re = abs(dt) > 1e-12 ? abs(dp - dt) / abs(dt) : abs(dp - dt)
    @printf("  %-12s true=% .6e   prod=% .6e   rel_err=%.3e\n", l, dt, dp, re)
end

# Where does the production solution diverge from truth, per variable?
println("\nclosest production root vs truth, per variable:")
for (n, xt, xh) in zip(ps.variable_names, ps.true_values, ps.closest_solution_production)
    flag = (abs(xt) > 1e-9 && abs(xh - xt) / abs(xt) > 0.05) ? "  <== off" : ""
    @printf("  %-10s true=% .5e   HC=% .5e%s\n", n, xt, xh, flag)
end
println("\nDONE")
