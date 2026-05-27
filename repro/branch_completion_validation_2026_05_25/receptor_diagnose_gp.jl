# Does receptor survive with the GP interpolator (vs AAAD)? Same single-point
# diagnostic, interpolator = agp_gpr_robust. 0 noise.
using ODEParameterEstimation
using Printf
const OPE = ODEParameterEstimation

pep = OPE.receptor_subtype_binding_branch()
opts = EstimationOptions(datasize = 101, noise_level = 0.0,
    system_solver = SolverHC, use_si_template = true, nooutput = true)
spep = sample_problem_data(pep, opts)

println("="^72)
println("DERIVATIVE ACCURACY  (GP = agp_gpr_robust, single point, 0 noise)")
println("="^72)
da = diagnose_derivative_accuracy(spep; interpolator = OPE.agp_gpr_robust, interpolator_name = "agp_gpr_robust")
@printf("t_eval = %.4f    max_required_order = %d\n", da.t_eval, da.max_required_order)
@printf("WORST: obs=%s  order=%d  rel_error=%.3e\n", da.worst_obs, da.worst_order, da.worst_rel_error)
for e in sort(da.entries, by = x -> (x.obs, x.order))
    @printf("  %-8s ord %d   rel_err=%.3e   (true=% .4e  interp=% .4e)\n",
        e.obs, e.order, e.rel_error, e.true_val, e.interp_val)
end

println("\n", "="^72)
println("POLYNOMIAL SYSTEM with GP derivatives")
println("="^72)
ps = diagnose_polynomial_system(spep; interpolator = OPE.agp_gpr_robust)
@printf("PERFECT : %d real roots | closest-to-truth dist=%.3e\n", ps.n_solutions_perfect, ps.closest_distance_perfect)
@printf("GP(prod): %d real roots | closest-to-truth dist=%.3e | resid@truth=%.3e\n",
    ps.n_solutions_production, ps.closest_distance_production, ps.true_residual_production)
println("\nclosest GP root vs truth (params + low-order states only):")
for (n, xt, xh) in zip(ps.variable_names, ps.true_values, ps.closest_solution_production)
    occursin("_0", n) || occursin("_1", n) || continue   # params/ICs and first derivs
    flag = (abs(xt) > 1e-9 && abs(xh - xt) / abs(xt) > 0.05) ? "  <== off" : ""
    @printf("  %-10s true=% .5e   GP=% .5e%s\n", n, xt, xh, flag)
end
println("\nDONE")
