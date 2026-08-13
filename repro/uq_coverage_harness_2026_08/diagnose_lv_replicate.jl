# Single verbose LV replicate: why is every nonlinear-model UQ report
# :degenerate with sd(z) ≈ 0 (σ̂ orders of magnitude too wide)?
# Prints conditioning, S norms, Σ_d diagonal by (obs, order), max_cv chain.

using ODEParameterEstimation
using LinearAlgebra
using Random
using Statistics
include(joinpath(@__DIR__, "coverage_driver.jl"))

Random.seed!(7101)
pep = ODEParameterEstimation.lotka_volterra()
opts = EstimationOptions(datasize = 121, time_interval = [0.0, 20.0],
	noise_level = 0.01, nooutput = true, diagnostics = false)
pep_data = ODEParameterEstimation.sample_problem_data(pep, opts)

setup = ODEParameterEstimation.setup_parameter_estimation(
	pep_data; interpolator = ODEParameterEstimation.agp_gpr_uq, nooutput = true)
t_vec = pep_data.data_sample["t"]
t_eval = t_vec[setup.time_index_set[1]]
println("t_eval = ", t_eval, "  (index ", setup.time_index_set[1], " of ", length(t_vec), ")")
println("good_deriv_level = ", setup.good_deriv_level)

est = nls_polish_estimate(pep_data, t_eval)
println("\nestimate vs truth:")
for (p, v) in est.parameters
	println("  ", p, " = ", round(v; sigdigits = 6), "   (true ", pep_data.p_true[p], ")")
end
for (s, v) in est.states
	println("  ", s, "(t0) = ", round(v; sigdigits = 6), "   (true ", pep_data.ic[s], ")")
end

# Estimate-conditioned sensitivity — warns VISIBLE this time
sens = ODEParameterEstimation.diagnose_sensitivity(
	pep_data; setup_data = setup, t_eval = t_eval, estimate_result = est)

println("\nvalue_source = ", sens.value_source)
println("jacobian_cond (at estimate) = ", sens.jacobian_cond)
S = sens.data_sensitivity_matrix
println("S size = ", size(S), "   norm = ", norm(S))
println("unknown labels: ", sens.data_sensitivity_unknown_labels)
println("data labels:    ", sens.data_sensitivity_data_labels)
println("per-column |S| max:")
for (j, dl) in enumerate(sens.data_sensitivity_data_labels)
	println("  ", rpad(dl, 12), round(maximum(abs, @view S[:, j]); sigdigits = 4))
end

r = ODEParameterEstimation.diagnose_uncertainty(pep_data, setup, t_eval, sens)
uq_local = first(r)
println("\nΣ_d diagonal (data variance by label):")
for (j, dl) in enumerate(uq_local.data_labels)
	println("  ", rpad(dl, 12), round(uq_local.data_covariance[j, j]; sigdigits = 4))
end
println("\nlocal param_std (pre-physicalization):")
for (j, pl) in enumerate(uq_local.param_labels)
	println("  ", rpad(pl, 12), round(uq_local.param_std[j]; sigdigits = 4))
end
println("local max_cv = ", uq_local.max_cv, "   status = ", uq_local.status)

uq = ODEParameterEstimation.physicalize_uncertainty_report(pep_data, est, uq_local)
println("\nphysicalized param_std vs value:")
for (j, pl) in enumerate(uq.param_labels)
	println("  ", rpad(pl, 12), "σ̂ = ", round(uq.param_std[j]; sigdigits = 4))
end
println("physical max_cv = ", uq.max_cv, "   status = ", uq.status)
println("\nDIAG_DONE")
