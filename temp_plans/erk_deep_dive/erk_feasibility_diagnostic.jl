#!/usr/bin/env julia
#
# ERK Polynomial System Feasibility Diagnostic v2
# ================================================
# Uses the PRODUCTION code path (construct_equation_system_from_si_template)
# to answer:
#   1. Does the true solution satisfy the production polynomial system?
#   2. Can HC.jl find the true solution with *perfect* interpolants?
#   3. How does AGPRobust interpolation compare?
#
# Key difference from v1: v1 manually classified variables (got 33 eq / 45 var,
# underdetermined by 12). v2 calls the actual production function which correctly
# reduces to 33 eq / 33 var via DD.obs_lhs-based substitution.
#
# Run: julia temp_plans/erk_deep_dive/erk_feasibility_diagnostic.jl

using ODEParameterEstimation
using ModelingToolkit
using DifferentialEquations
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics

println("=" ^ 72)
println("  ERK FEASIBILITY DIAGNOSTIC v2 — PRODUCTION CODE PATH")
println("=" ^ 72)
println()
flush(stdout)

# ─────────────────────────────────────────────────────────────────────
# PerfectInterpolant: Returns exact derivatives via TaylorDiff
# ─────────────────────────────────────────────────────────────────────
# Stores Taylor coefficients c[k+1] = f^(k)(t0) / k!
# Evaluates as polynomial via Horner's method.
# When TaylorDiff.derivative evaluates this at t0, the k-th derivative
# is exactly k! * c[k+1] = f^(k)(t0).

struct PerfectInterpolant
	t0::Float64
	coeffs::Vector{Float64}  # coeffs[k+1] = f^(k)(t0) / k!
end

function (p::PerfectInterpolant)(t)
	dt = t - p.t0
	# Horner's method for polynomial evaluation
	result = p.coeffs[end]
	for k in (length(p.coeffs) - 1):-1:1
		result = result * dt + p.coeffs[k]
	end
	return result
end

# ═════════════════════════════════════════════════════════════════════
# STEP 1: ERK Model Setup + Data Generation
# ═════════════════════════════════════════════════════════════════════
println("STEP 1: Setting up ERK model and generating data...")
flush(stdout)

@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
D = Differential(t)

states = [S0, C1, C2, S1, S2, E]
parameters = [kf1, kr1, kc1, kf2, kr2, kc2]

eqs = [
	D(S0) ~ -kf1 * E * S0 + kr1 * C1,
	D(C1) ~ kf1 * E * S0 - (kr1 + kc1) * C1,
	D(C2) ~ kc1 * C1 - (kr2 + kc2) * C2 + kf2 * E * S1,
	D(S1) ~ -kf2 * E * S1 + kr2 * C2,
	D(S2) ~ kc2 * C2,
	D(E) ~ -kf1 * E * S0 + kr1 * C1 - kf2 * E * S1 + (kr2 + kc2) * C2,
]

measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]

p_true_vals = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]
ic_vals = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]
time_interval = [0.0, 20.0]
datasize = 2001

state_names = ["S0", "C1", "C2", "S1", "S2", "E"]
obs_state_indices = [1, 4, 5]  # S0=1, S1=4, S2=5 in state vector

p_true_dict = Dict(parameters .=> p_true_vals)
ic_dict = Dict(states .=> ic_vals)

println("  Parameters: kf1=$(p_true_vals[1]), kr1=$(p_true_vals[2]), kc1=$(p_true_vals[3]), " *
		"kf2=$(p_true_vals[4]), kr2=$(p_true_vals[5]), kc2=$(p_true_vals[6])")
println("  ICs: S0=$(ic_vals[1]), C1=$(ic_vals[2]), C2=$(ic_vals[3]), " *
		"S1=$(ic_vals[4]), S2=$(ic_vals[5]), E=$(ic_vals[6])")

# Generate data sample (2001 points, same as production)
@named erk_model = ODESystem(eqs, t, states, parameters)
data_sample = ODEParameterEstimation.sample_data(
	erk_model, measured_quantities, time_interval,
	p_true_dict, ic_dict, datasize;
	solver = AutoVern9(Rodas4P()),
)
println("  Data sample: $(length(data_sample["t"])) points over $time_interval")

# High-accuracy ODE solution for ground truth (dense output)
sys_complete = complete(erk_model)
prob = ODEProblem(
	sys_complete,
	merge(Dict(ModelingToolkit.unknowns(sys_complete) .=> ic_vals),
		Dict(ModelingToolkit.parameters(sys_complete) .=> p_true_vals)),
	time_interval,
)
sol = solve(prob, AutoVern9(Rodas4P()); abstol = 1e-14, reltol = 1e-14, dense = true)

println("  STEP 1 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 2: Production Setup — SIAN Analysis + Interpolants
# ═════════════════════════════════════════════════════════════════════
println("STEP 2: Running production setup (SIAN + AGPRobust interpolants + point selection)...")
flush(stdout)

# Create PEP through the production path
ordered_model, mq = create_ordered_ode_system(
	"ERK_diag_v2", states, parameters, eqs, measured_quantities,
)
pep = ParameterEstimationProblem(
	"ERK_diag_v2", ordered_model, mq, data_sample, time_interval,
	nothing,
	OrderedDict(parameters .=> p_true_vals),
	OrderedDict(states .=> ic_vals),
	0,
)

# setup_parameter_estimation: runs SIAN, creates AGPRobust interpolants, picks eval point
setup_data = ODEParameterEstimation.setup_parameter_estimation(
	pep;
	max_num_points = 1,
	point_hint = 0.5,
	interpolator = ODEParameterEstimation.agp_gpr_robust,
)

t_eval_idx = setup_data.time_index_set[1]
t_eval = data_sample["t"][t_eval_idx]

println("  SIAN derivative levels: $(setup_data.good_deriv_level)")
println("  Unidentifiable params: $(setup_data.all_unidentifiable)")
println("  DD.obs_lhs levels: $(length(setup_data.good_DD.obs_lhs))")
println("  Time index: $t_eval_idx  =>  t_eval = $t_eval")
println("  # varlist entries: $(length(setup_data.good_varlist))")
println("  STEP 2 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 3: Ground-Truth Derivatives via Taylor Coefficient Recursion
# ═════════════════════════════════════════════════════════════════════
println("STEP 3: Computing ground-truth derivatives at t=$t_eval via Taylor recursion...")
flush(stdout)

state_at_t = sol(t_eval)
max_deriv_order = 20  # generous — SIAN needs ~13-14

n_states = 6
taylor_coeffs = zeros(Float64, n_states, max_deriv_order + 1)  # [state, order+1]

# Order 0: state values at t_eval
for i in 1:n_states
	taylor_coeffs[i, 1] = state_at_t[i]
end

# Taylor product: (a*b)_k = sum_{j=0}^{k} a_j * b_{k-j}
function taylor_product_coeff(a_coeffs, b_coeffs, k)
	s = 0.0
	for j in 0:k
		s += a_coeffs[j+1] * b_coeffs[k-j+1]
	end
	return s
end

# Iteratively compute Taylor coefficients via ODE RHS recursion
# For ODE x' = f(x), Taylor coeff x_{k+1} = f_k / (k+1)
for k in 0:(max_deriv_order - 1)
	S0c = taylor_coeffs[1, 1:k+1]
	C1c = taylor_coeffs[2, 1:k+1]
	C2c = taylor_coeffs[3, 1:k+1]
	S1c = taylor_coeffs[4, 1:k+1]
	S2c = taylor_coeffs[5, 1:k+1]
	Ec = taylor_coeffs[6, 1:k+1]
	kf1v, kr1v, kc1v, kf2v, kr2v, kc2v = p_true_vals

	ES0_k = taylor_product_coeff(Ec, S0c, k)
	ES1_k = taylor_product_coeff(Ec, S1c, k)

	f_k = zeros(6)
	f_k[1] = -kf1v * ES0_k + kr1v * C1c[k+1]
	f_k[2] = kf1v * ES0_k - (kr1v + kc1v) * C1c[k+1]
	f_k[3] = kc1v * C1c[k+1] - (kr2v + kc2v) * C2c[k+1] + kf2v * ES1_k
	f_k[4] = -kf2v * ES1_k + kr2v * C2c[k+1]
	f_k[5] = kc2v * C2c[k+1]
	f_k[6] = -kf1v * ES0_k + kr1v * C1c[k+1] - kf2v * ES1_k + (kr2v + kc2v) * C2c[k+1]

	for i in 1:n_states
		taylor_coeffs[i, k+2] = f_k[i] / (k + 1)
	end
end

# Convert Taylor coefficients to derivatives: x^(k) = k! * x_k
truth_state_derivs = Vector{Vector{Float64}}(undef, 6)
for si in 1:6
	truth_state_derivs[si] = Float64[]
	for k in 0:max_deriv_order
		push!(truth_state_derivs[si], Float64(taylor_coeffs[si, k+1] * factorial(big(k))))
	end
end

# Observable derivatives = state derivatives for the observed states
truth_obs_derivs = Vector{Vector{Float64}}(undef, 3)
for (oi, si) in enumerate(obs_state_indices)
	truth_obs_derivs[oi] = truth_state_derivs[si]
end

# Cross-check low orders against ODE interpolant
println("  Cross-check (orders 0-3) Taylor vs ODE interpolant at t=$t_eval:")
for oi in 1:3
	obs_name = ["y0(S0)", "y1(S1)", "y2(S2)"][oi]
	si = obs_state_indices[oi]
	for k in 0:3
		taylor_val = truth_obs_derivs[oi][k+1]
		ode_val = try
			ODEParameterEstimation.nth_deriv(tt -> sol(tt)[si], k, t_eval)
		catch
			NaN
		end
		match = abs(taylor_val) > 1e-10 ?
				abs((ode_val - taylor_val) / taylor_val) : abs(ode_val - taylor_val)
		@printf("    %s order %d: taylor=%15.8e  ode=%15.8e  rel_diff=%.2e\n",
			obs_name, k, taylor_val, ode_val, match)
	end
end
println("  STEP 3 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 4: Build PerfectInterpolant Objects
# ═════════════════════════════════════════════════════════════════════
println("STEP 4: Building PerfectInterpolants at t=$t_eval...")
flush(stdout)

# Key must match what construct_equation_system_from_si_template uses:
#   obs_rhs = ModelingToolkit.diff2term(obs_eqn.rhs)
# For y0~S0, diff2term(S0) = S0 (identity on non-derivatives)
perfect_interps = Dict()
for (i, mq_eq) in enumerate(pep.measured_quantities)
	obs_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
	si = obs_state_indices[i]
	# Taylor coefficients for this observable (c[k+1] = f^(k)/k! already in taylor_coeffs)
	coeffs = collect(taylor_coeffs[si, 1:max_deriv_order+1])
	perfect_interps[obs_rhs] = PerfectInterpolant(t_eval, coeffs)
end

# Verify PerfectInterpolant gives correct derivatives via nth_deriv
println("  Verification: PerfectInterpolant vs Truth via nth_deriv:")
max_perf_err = 0.0
for (i, mq_eq) in enumerate(pep.measured_quantities)
	obs_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
	pi = perfect_interps[obs_rhs]
	for k in [0, 1, 2, 5, 10, 15]
		perf_val = ODEParameterEstimation.nth_deriv(x -> pi(x), k, t_eval)
		truth_val = truth_obs_derivs[i][k+1]
		rel_err = abs(truth_val) > 1e-15 ? abs((perf_val - truth_val) / truth_val) : abs(perf_val)
		global max_perf_err = max(max_perf_err, rel_err)
		@printf("    obs%d order %2d: perfect=%15.8e  truth=%15.8e  rel_err=%.2e\n",
			i, k, perf_val, truth_val, rel_err)
	end
end
if max_perf_err < 1e-10
	println("  >> PerfectInterpolant is EXACT (max rel_err=", @sprintf("%.2e", max_perf_err), ")")
else
	println("  >> WARNING: PerfectInterpolant has errors up to ", @sprintf("%.2e", max_perf_err))
end
println("  STEP 4 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 5: Derivative Comparison — Perfect vs AGPRobust vs Truth
# ═════════════════════════════════════════════════════════════════════
println("STEP 5: Derivative accuracy comparison at t=$t_eval...")
flush(stdout)

println("\n  " * "-" ^ 105)
@printf("  %-5s %-5s %20s %20s %20s %12s %12s\n",
	"Obs", "Order", "Truth", "Perfect", "AGPRobust", "Perf err%", "AGPR err%")
println("  " * "-" ^ 105)

for (i, mq_eq) in enumerate(pep.measured_quantities)
	obs_name = ["y0", "y1", "y2"][i]
	obs_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
	pi = perfect_interps[obs_rhs]
	agpr_interp = setup_data.interpolants[obs_rhs]

	for k in 0:15
		truth_val = truth_obs_derivs[i][k+1]
		perf_val = try
			ODEParameterEstimation.nth_deriv(x -> pi(x), k, t_eval)
		catch
			NaN
		end
		agpr_val = try
			ODEParameterEstimation.nth_deriv(x -> agpr_interp(x), k, t_eval)
		catch
			NaN
		end
		perf_err = abs(truth_val) > 1e-15 ? abs((perf_val - truth_val) / truth_val) * 100 : abs(perf_val)
		agpr_err = abs(truth_val) > 1e-15 ? abs((agpr_val - truth_val) / truth_val) * 100 : abs(agpr_val)
		@printf("  %-5s %5d %20.8e %20.8e %20.8e %11.4f%% %11.4f%%\n",
			obs_name, k, truth_val, perf_val, agpr_val, perf_err, agpr_err)
	end
end
println("  STEP 5 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 6: Get SIAN Template (cached) + Build System with Perfect Data
# ═════════════════════════════════════════════════════════════════════
println("STEP 6: Getting SIAN template + building equation system with PERFECT data...")
flush(stdout)

# Call get_si_equation_system once, cache for both perfect and AGPRobust calls
si_template_eqs, si_deriv_dict, si_unident, _si_id_funcs =
	ODEParameterEstimation.get_si_equation_system(
		pep.model, pep.measured_quantities, pep.data_sample;
		DD = setup_data.good_DD, infolevel = 1,
	)

cached_si_template = (
	equations = si_template_eqs,
	deriv_dict = si_deriv_dict,
	unidentifiable = si_unident,
)

println("  SIAN template: $(length(si_template_eqs)) equations")
println("  Derivative dict: $si_deriv_dict")
println("  Max derivative order: $(isempty(si_deriv_dict) ? 0 : maximum(values(si_deriv_dict)))")

# Build equations with PERFECT interpolants via the production function
eqs_perfect, vars_perfect = ODEParameterEstimation.construct_equation_system_from_si_template(
	pep.model.system,
	pep.measured_quantities,
	pep.data_sample,
	setup_data.good_deriv_level,
	setup_data.good_udict,
	setup_data.good_varlist,
	setup_data.good_DD;
	interpolator = ODEParameterEstimation.agp_gpr_robust,  # unused — precomputed provided
	time_index_set = setup_data.time_index_set,
	precomputed_interpolants = perfect_interps,
	diagnostics = true,
	si_template = cached_si_template,
)

println("\n  PERFECT DATA system: $(length(eqs_perfect)) equations, $(length(vars_perfect)) variables")
is_square = length(eqs_perfect) == length(vars_perfect)
println("  Square: ", is_square ? "YES" : "NO ($(length(eqs_perfect)) eq, $(length(vars_perfect)) var)")
println("  Variables: ", [string(v) for v in vars_perfect])

# Solve with HC.jl (solve_with_hc has internal error handling — never throws)
println("\n  Solving with HC.jl (perfect data)...")
flush(stdout)
_result_perfect = ODEParameterEstimation.solve_with_hc(
	eqs_perfect, vars_perfect; display_system = true,
)
solutions_perfect = _result_perfect[1]
println("  HC.jl found $(length(solutions_perfect)) solutions")

println("  STEP 6 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 7: Build System with AGPRobust Data
# ═════════════════════════════════════════════════════════════════════
println("STEP 7: Building equation system with AGPRobust data...")
flush(stdout)

eqs_agpr, vars_agpr = ODEParameterEstimation.construct_equation_system_from_si_template(
	pep.model.system,
	pep.measured_quantities,
	pep.data_sample,
	setup_data.good_deriv_level,
	setup_data.good_udict,
	setup_data.good_varlist,
	setup_data.good_DD;
	interpolator = ODEParameterEstimation.agp_gpr_robust,
	time_index_set = setup_data.time_index_set,
	precomputed_interpolants = setup_data.interpolants,
	diagnostics = true,
	si_template = cached_si_template,
)

println("\n  AGPRobust DATA system: $(length(eqs_agpr)) equations, $(length(vars_agpr)) variables")

# Solve with HC.jl (solve_with_hc has internal error handling — never throws)
println("  Solving with HC.jl (AGPRobust data)...")
flush(stdout)
_result_agpr = ODEParameterEstimation.solve_with_hc(eqs_agpr, vars_agpr)
solutions_agpr = _result_agpr[1]
println("  HC.jl found $(length(solutions_agpr)) solutions")

println("  STEP 7 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 8: Residual Check — Does True Solution Satisfy the System?
# ═════════════════════════════════════════════════════════════════════
println("STEP 8: Substituting TRUE values into perfect-data system...")
flush(stdout)

# Build substitution dict: map each variable to its true value
param_name_to_val = Dict(
	"kf1" => p_true_vals[1], "kr1" => p_true_vals[2], "kc1" => p_true_vals[3],
	"kf2" => p_true_vals[4], "kr2" => p_true_vals[5], "kc2" => p_true_vals[6],
)
state_name_to_idx = Dict(
	"S0" => 1, "C1" => 2, "C2" => 3, "S1" => 4, "S2" => 5, "E" => 6,
)

sub_dict = Dict()
unmapped_vars = []

println("  Mapping $(length(vars_perfect)) variables to true values:")
for v in vars_perfect
	vname = string(v)
	parsed = ODEParameterEstimation.parse_derivative_variable_name(vname)

	if !isnothing(parsed)
		base_name, deriv_order = parsed
		if haskey(param_name_to_val, base_name)
			if deriv_order == 0
				sub_dict[v] = param_name_to_val[base_name]
				@printf("    %-20s -> param %s = %.6f\n", vname, base_name, sub_dict[v])
			else
				sub_dict[v] = 0.0  # params are constant
				@printf("    %-20s -> d^%d(%s)/dt^%d = 0\n", vname, deriv_order, base_name, deriv_order)
			end
		elseif haskey(state_name_to_idx, base_name)
			si = state_name_to_idx[base_name]
			if deriv_order + 1 <= length(truth_state_derivs[si])
				sub_dict[v] = truth_state_derivs[si][deriv_order+1]
				@printf("    %-20s -> d^%d(%s)/dt^%d = %.6e\n",
					vname, deriv_order, base_name, deriv_order, sub_dict[v])
			else
				sub_dict[v] = NaN
				push!(unmapped_vars, (v, vname, "order $deriv_order > max $(max_deriv_order)"))
			end
		else
			push!(unmapped_vars, (v, vname, "unknown base '$base_name'"))
		end
	else
		push!(unmapped_vars, (v, vname, "parse failed"))
	end
end

if !isempty(unmapped_vars)
	println("\n  UNMAPPED variables ($(length(unmapped_vars))):")
	for (v, vname, reason) in unmapped_vars
		println("    $vname — $reason")
	end
end

# Evaluate residuals equation by equation
residuals = Float64[]
println("\n  Residuals (equation by equation):")
for (i, eq) in enumerate(eqs_perfect)
	val = try
		Float64(Symbolics.value(Symbolics.substitute(eq, sub_dict)))
	catch e
		@printf("    Eq%2d: SUBSTITUTION FAILED: %s\n", i, string(e)[1:min(80, length(string(e)))])
		NaN
	end
	push!(residuals, val)
	flag = abs(val) > 1e-6 ? " <-- LARGE" : ""
	@printf("    Eq%2d: |residual| = %20.10e%s\n", i, abs(val), flag)
end

valid_residuals = filter(!isnan, residuals)
max_resid = isempty(valid_residuals) ? NaN : maximum(abs.(valid_residuals))
println("\n  MAX |residual|: ", @sprintf("%.10e", max_resid))
if max_resid < 1e-6
	println("  >> TRUE SOLUTION SATISFIES THE SYSTEM (residuals ~ 0)")
elseif max_resid < 1e-2
	println("  >> Residuals small-ish — possible numerical precision issue")
else
	println("  >> TRUE SOLUTION DOES NOT SATISFY THE SYSTEM!")
end
println("  STEP 8 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 9: Solution Analysis — Compare HC.jl results to truth
# ═════════════════════════════════════════════════════════════════════
println("STEP 9: Comparing HC.jl solutions to true values...")
flush(stdout)

function analyze_solutions(solutions, label, vars, sub_dict)
	println("\n  --- $label ---")
	println("  # solutions: $(length(solutions))")

	if isempty(solutions)
		println("  NO SOLUTIONS from HC.jl")
		return Inf
	end

	# Build true-value vector in variable order
	true_vec = Float64[get(sub_dict, v, NaN) for v in vars]
	var_names = [string(v) for v in vars]

	best_dist = Inf
	best_idx = 0
	for (i, s) in enumerate(solutions)
		dist = norm(s .- true_vec)
		rel_err = norm((s .- true_vec) ./ max.(abs.(true_vec), 1e-10))
		@printf("    Solution %2d: L2_dist=%.4e, rel_L2_err=%.4e\n", i, dist, rel_err)
		if dist < best_dist
			best_dist = dist
			best_idx = i
		end
	end

	# Print best solution in detail
	println("\n    CLOSEST solution (#$best_idx):")
	s = solutions[best_idx]
	for (j, vn) in enumerate(var_names)
		s_val = s[j]
		t_val = true_vec[j]
		err_pct = abs(t_val) > 1e-10 ? abs((s_val - t_val) / t_val) * 100 : abs(s_val)
		@printf("      %-20s: sol=%15.6e  true=%15.6e  err=%8.2f%%\n", vn, s_val, t_val, err_pct)
	end

	return best_dist
end

best_dist_perfect = analyze_solutions(solutions_perfect, "PERFECT DATA", vars_perfect, sub_dict)
best_dist_agpr = analyze_solutions(solutions_agpr, "AGPRobust DATA", vars_agpr, sub_dict)

println("\n  STEP 9 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════
# STEP 10: Summary
# ═════════════════════════════════════════════════════════════════════
println("=" ^ 72)
println("  DIAGNOSTIC SUMMARY (v2 — Production Code Path)")
println("=" ^ 72)
println()

println("1. SYSTEM SIZE (production path):")
@printf("   Equations: %d\n", length(eqs_perfect))
@printf("   Variables: %d\n", length(vars_perfect))
println("   Square: ", is_square ? "YES" : "NO")
println()

println("2. RESIDUAL CHECK (true solution + perfect data):")
@printf("   Max |residual|: %.4e\n", max_resid)
if max_resid < 1e-6
	println("   -> True solution IS a root of the production system")
else
	println("   -> PROBLEM: true solution does NOT satisfy the system")
end
println()

println("3. HC.jl WITH PERFECT DATA:")
@printf("   # solutions: %d\n", length(solutions_perfect))
@printf("   Closest distance to truth: %.4e\n", best_dist_perfect)
if !isempty(solutions_perfect) && best_dist_perfect < 1e-3
	println("   -> HC.jl RECOVERS the true solution with perfect data")
elseif !isempty(solutions_perfect)
	println("   -> HC.jl finds solutions but NONE are close to truth")
else
	println("   -> HC.jl finds NO solutions")
end
println()

println("4. HC.jl WITH AGPRobust DATA:")
@printf("   # solutions: %d\n", length(solutions_agpr))
@printf("   Closest distance to truth: %.4e\n", best_dist_agpr)
println()

println("5. DERIVATIVE ACCURACY SUMMARY (key orders at t=$t_eval):")
for (oi, obs_name) in enumerate(["y0", "y1", "y2"])
	obs_rhs = ModelingToolkit.diff2term(pep.measured_quantities[oi].rhs)
	agpr_interp = setup_data.interpolants[obs_rhs]
	for k in [0, 5, 10, 13]
		if k + 1 <= length(truth_obs_derivs[oi])
			truth = truth_obs_derivs[oi][k+1]
			agpr_val = try
				ODEParameterEstimation.nth_deriv(x -> agpr_interp(x), k, t_eval)
			catch
				NaN
			end
			agpr_err = abs(truth) > 1e-15 ? abs((agpr_val - truth) / truth) * 100 : abs(agpr_val)
			@printf("   %s order %2d: AGPR err=%8.3f%%\n", obs_name, k, agpr_err)
		end
	end
end
println()

# ─── Final Conclusion ───
println("-" ^ 72)
if max_resid < 1e-6 && !isempty(solutions_perfect)
	if best_dist_perfect < 1e-3
		println("CONCLUSION: System is FEASIBLE — HC.jl finds the true solution with perfect data.")
		if isempty(solutions_agpr) || best_dist_agpr > 10.0
			println("  -> INTERPOLATION is the bottleneck (AGPRobust derivatives too inaccurate).")
		elseif best_dist_agpr < 1e-1
			println("  -> AGPRobust solutions are reasonably close — interpolation is adequate.")
		else
			println("  -> AGPRobust solutions exist but are far from truth — interpolation degrades quality.")
		end
	else
		println("CONCLUSION: System is correct but HC.jl MISSES the true root even with perfect data.")
		println("  -> Path-tracking / total-degree homotopy coverage problem.")
	end
elseif max_resid < 1e-6 && isempty(solutions_perfect)
	println("CONCLUSION: System is correct (true solution satisfies it) but HC.jl finds 0 solutions.")
	println("  -> Polynomial structure/degree prevents total-degree homotopy from working.")
elseif max_resid >= 1e-6
	println("CONCLUSION: SYSTEM IS STRUCTURALLY WRONG — true solution doesn't satisfy it.")
	println("  -> Fundamental issue with SIAN template or variable mapping.")
end
println("-" ^ 72)
println()
println("Done!")
flush(stdout)
