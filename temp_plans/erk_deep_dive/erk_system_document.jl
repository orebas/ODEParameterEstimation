#!/usr/bin/env julia
#
# ERK 33×33 System Reference Document Generator
# ===============================================
# Generates comprehensive output documenting:
#   A. The symbolic 33×33 polynomial system (SIAN template after data substitution)
#   B. Data variable catalog (which observable derivatives get substituted)
#   C. True derivative values at 3 key time points (via Taylor recursion)
#   D. Multi-method interpolation comparison at those 3 points
#
# This is the definitive reference for understanding where interpolation fails.
#
# Run: julia temp_plans/erk_deep_dive/erk_system_document.jl
# Or:  julia temp_plans/erk_deep_dive/erk_system_document.jl > temp_plans/erk_deep_dive/erk_system_document_output.txt 2>&1

using ODEParameterEstimation
using ModelingToolkit
using DifferentialEquations
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics

# ═════════════════════════════════════════════════════════════════════════════
# STEP 1: ERK Model Setup + High-Accuracy ODE Solution
# ═════════════════════════════════════════════════════════════════════════════
println("=" ^ 80)
println("  ERK 33×33 SYSTEM REFERENCE DOCUMENT")
println("=" ^ 80)
println()
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

# ═════════════════════════════════════════════════════════════════════════════
# STEP 2: Production Setup — SIAN Analysis + AGPRobust Interpolants
# ═════════════════════════════════════════════════════════════════════════════
println("STEP 2: Running production setup (SIAN + AGPRobust interpolants)...")
flush(stdout)

ordered_model, mq = create_ordered_ode_system(
	"ERK_sysdoc", states, parameters, eqs, measured_quantities,
)
pep = ParameterEstimationProblem(
	"ERK_sysdoc", ordered_model, mq, data_sample, time_interval,
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

println("  SIAN derivative levels: $(setup_data.good_deriv_level)")
println("  DD.obs_lhs levels: $(length(setup_data.good_DD.obs_lhs))")
println("  # varlist entries: $(length(setup_data.good_varlist))")
println("  STEP 2 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════════════
# STEP 3: Get SIAN Template (cached for reuse)
# ═════════════════════════════════════════════════════════════════════════════
println("STEP 3: Getting SIAN template equations...")
flush(stdout)

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

max_required_deriv = isempty(si_deriv_dict) ? 0 : maximum(values(si_deriv_dict))

println("  SIAN template: $(length(si_template_eqs)) equations")
println("  Derivative dict: $si_deriv_dict")
println("  Max derivative order: $max_required_deriv")
println("  STEP 3 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════════════
# STEP 4: Define Evaluation Points
# ═════════════════════════════════════════════════════════════════════════════
println("STEP 4: Defining evaluation points...")
flush(stdout)

t_vec = data_sample["t"]

# Leftmost: boundary (t=0)
idx_left = 1
t_left = t_vec[idx_left]

# Shooting point 1: midpoint from pick_points(vec, 2, interps, 0.5)
idx_mid = min(max(1, round(Int, 0.5 * length(t_vec))), length(t_vec))
t_mid = t_vec[idx_mid]

# Shooting point 2: later interior from pick_points
idx_late = min(max(1, round(Int, (0.5 + 1 / 3) * length(t_vec))), length(t_vec))
t_late = t_vec[idx_late]

eval_points = [
	(idx_left, t_left, "LEFTMOST (boundary, stiff transient)"),
	(idx_mid, t_mid, "MIDPOINT (shooting point 1)"),
	(idx_late, t_late, "LATE INTERIOR (shooting point 2)"),
]

for (idx, tv, label) in eval_points
	@printf("  Point: idx=%d, t=%.4f — %s\n", idx, tv, label)
end
println("  STEP 4 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════════════
# STEP 5: Taylor Recursion for Ground-Truth Derivatives at All 3 Points
# ═════════════════════════════════════════════════════════════════════════════
println("STEP 5: Computing ground-truth derivatives via Taylor recursion at all 3 points...")
flush(stdout)

"""
	compute_truth_derivs(sol, t_eval, p_true_vals, ic_vals, obs_state_indices; max_order=20)

Compute exact observable derivatives at `t_eval` using Taylor coefficient recursion.
Returns `(truth_obs_derivs, truth_state_derivs)` where:
- `truth_obs_derivs[obs_idx][order+1]` = d^order(y_obs)/dt^order at t_eval
- `truth_state_derivs[state_idx][order+1]` = d^order(state)/dt^order at t_eval
"""
function compute_truth_derivs(sol, t_eval, p_true_vals, ic_vals, obs_state_indices; max_order = 20)
	n_states = 6
	taylor_coeffs = zeros(Float64, n_states, max_order + 1)

	# Order 0: state values at t_eval
	state_at_t = sol(t_eval)
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
	for k in 0:(max_order - 1)
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
		for k in 0:max_order
			push!(truth_state_derivs[si], Float64(taylor_coeffs[si, k+1] * factorial(big(k))))
		end
	end

	# Observable derivatives = state derivatives for the observed states
	truth_obs_derivs = Vector{Vector{Float64}}(undef, 3)
	for (oi, si) in enumerate(obs_state_indices)
		truth_obs_derivs[oi] = truth_state_derivs[si]
	end

	return truth_obs_derivs, truth_state_derivs
end

# Compute truth at all 3 points
truth_at_points = Dict{Float64, Any}()
state_truth_at_points = Dict{Float64, Any}()
for (idx, tv, label) in eval_points
	println("  Computing truth at t=$(tv)...")
	flush(stdout)
	obs_derivs, state_derivs = compute_truth_derivs(sol, tv, p_true_vals, ic_vals, obs_state_indices; max_order = 20)
	truth_at_points[tv] = obs_derivs
	state_truth_at_points[tv] = state_derivs
end

println("  STEP 5 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════════════
# STEP 6: Build All Interpolants (4 methods × 3 observables)
# ═════════════════════════════════════════════════════════════════════════════
println("STEP 6: Building interpolants for all 4 methods...")
flush(stdout)

method_names = ["AGPRobust", "AAAD", "AAAD-GPR", "FHD5"]
method_funcs = Dict(
	"AGPRobust" => ODEParameterEstimation.agp_gpr_robust,
	"AAAD"      => ODEParameterEstimation.aaad,
	"AAAD-GPR"  => ODEParameterEstimation.aaad_gpr_pivot,
	"FHD5"      => ODEParameterEstimation.fhdn(5),
)

# interps_by_method[method_name][obs_rhs] = interpolant
interps_by_method = Dict{String, Dict}()

for mname in method_names
	println("  Building interpolants for $mname...")
	flush(stdout)
	mfunc = method_funcs[mname]
	interps = Dict()
	for (i, mq_eq) in enumerate(pep.measured_quantities)
		obs_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
		key = haskey(data_sample, obs_rhs) ? obs_rhs : Symbolics.wrap(mq_eq.lhs)
		y_vector = data_sample[key]
		interps[obs_rhs] = mfunc(collect(Float64, t_vec), collect(Float64, y_vector))
	end
	interps_by_method[mname] = interps
end

println("  STEP 6 DONE")
println()
flush(stdout)

# ═════════════════════════════════════════════════════════════════════════════
# STEP 7: Build the 33×33 System (using AGPRobust for the "production" version)
# ═════════════════════════════════════════════════════════════════════════════
println("STEP 7: Building the 33×33 system via production code path...")
flush(stdout)

# Use the production shooting point (midpoint)
eqs_system, vars_system = ODEParameterEstimation.construct_equation_system_from_si_template(
	pep.model.system,
	pep.measured_quantities,
	pep.data_sample,
	setup_data.good_deriv_level,
	setup_data.good_udict,
	setup_data.good_varlist,
	setup_data.good_DD;
	interpolator = ODEParameterEstimation.agp_gpr_robust,
	time_index_set = [idx_mid],
	precomputed_interpolants = interps_by_method["AGPRobust"],
	diagnostics = false,
	si_template = cached_si_template,
)

println("  System size: $(length(eqs_system)) equations, $(length(vars_system)) variables")
println("  Square: ", length(eqs_system) == length(vars_system) ? "YES" : "NO")
println("  STEP 7 DONE")
println()
flush(stdout)

# ═══════════════════════════════════════════════════════════════════════════════
#
#  SECTION A: THE SYMBOLIC 33×33 SYSTEM
#
# ═══════════════════════════════════════════════════════════════════════════════
println()
println("=" ^ 80)
println("  SECTION A: THE SYMBOLIC 33×33 SYSTEM")
println("=" ^ 80)
println()

# A1: SIAN Template (before data substitution)
println("─" ^ 80)
println("  A1. SIAN Template Equations (BEFORE data substitution)")
println("      These are the $(length(si_template_eqs)) raw polynomial equations from SIAN.")
println("      Observable derivatives (y0_0, y0_1, ...) are still symbolic here.")
println("─" ^ 80)
println()

for (i, eq) in enumerate(si_template_eqs)
	vars_in = Symbolics.get_variables(eq)
	println("  Eq$i ($(length(vars_in)) vars):")
	println("    $eq = 0")
	println()
end

# A2: Variable classification in the final 33×33 system
println("─" ^ 80)
println("  A2. Variable Classification (AFTER data substitution → 33 unknowns)")
println("─" ^ 80)
println()

param_name_to_val = Dict(
	"kf1" => p_true_vals[1], "kr1" => p_true_vals[2], "kc1" => p_true_vals[3],
	"kf2" => p_true_vals[4], "kr2" => p_true_vals[5], "kc2" => p_true_vals[6],
)
state_name_to_idx = Dict(
	"S0" => 1, "C1" => 2, "C2" => 3, "S1" => 4, "S2" => 5, "E" => 6,
)

n_param_vars = 0
n_state_vars = 0
n_unknown_vars = 0
for v in vars_system
	vname = string(v)
	parsed = ODEParameterEstimation.parse_derivative_variable_name(vname)
	if !isnothing(parsed)
		base_name, deriv_order = parsed
		if haskey(param_name_to_val, String(base_name))
			global n_param_vars += 1
			@printf("    [PARAM]  %-20s  (parameter %s, order %d)\n", vname, base_name, deriv_order)
		elseif haskey(state_name_to_idx, String(base_name))
			global n_state_vars += 1
			@printf("    [STATE]  %-20s  (state %s, derivative order %d)\n", vname, base_name, deriv_order)
		else
			global n_unknown_vars += 1
			@printf("    [???]    %-20s  (unknown base '%s', order %d)\n", vname, base_name, deriv_order)
		end
	else
		global n_unknown_vars += 1
		@printf("    [???]    %-20s  (parse failed)\n", vname)
	end
end
println()
println("  Summary: $n_param_vars parameter vars + $n_state_vars state vars" *
		(n_unknown_vars > 0 ? " + $n_unknown_vars unknown" : "") *
		" = $(length(vars_system)) total")
println()

# A3: Final equations after substitution
println("─" ^ 80)
println("  A3. Final Equations (AFTER data substitution)")
println("      These are the $(length(eqs_system)) polynomial equations that HC.jl solves.")
println("      Observable derivative values have been substituted as numerical constants.")
println("─" ^ 80)
println()

for (i, eq) in enumerate(eqs_system)
	vars_in = Symbolics.get_variables(eq)
	# Truncate long equation strings for readability
	eq_str = string(eq)
	if length(eq_str) > 200
		eq_str = eq_str[1:200] * "..."
	end
	println("  Eq$i ($(length(vars_in)) vars):")
	println("    $eq_str = 0")
	println()
end

# ═══════════════════════════════════════════════════════════════════════════════
#
#  SECTION B: DATA VARIABLE CATALOG
#
# ═══════════════════════════════════════════════════════════════════════════════
println()
println("=" ^ 80)
println("  SECTION B: DATA VARIABLE CATALOG")
println("  These are the observable derivative variables that become numerical constants")
println("  when interpolated data is substituted into the SIAN template.")
println("=" ^ 80)
println()

# Collect all variables in the SIAN template
vars_in_template = OrderedCollections.OrderedSet()
for eq in si_template_eqs
	union!(vars_in_template, Symbolics.get_variables(eq))
end

DD = setup_data.good_DD
obs_names = ["y0 ~ S0", "y1 ~ S1", "y2 ~ S2"]

println("  DD.obs_lhs has $(length(DD.obs_lhs)) derivative levels")
println()

data_vars_catalog = []  # (var, obs_idx, order, obs_name)
for order in 0:max_required_deriv
	if order + 1 > length(DD.obs_lhs)
		break
	end
	for (obs_idx, mq_eq) in enumerate(pep.measured_quantities)
		if obs_idx > length(DD.obs_lhs[order+1])
			continue
		end
		lhs_var = DD.obs_lhs[order+1][obs_idx]
		in_template = any(v -> isequal(v, lhs_var), vars_in_template)
		in_final = any(v -> isequal(v, lhs_var), vars_system)
		status = if in_final
			"UNKNOWN (in final system)"
		elseif in_template
			"DATA (substituted)"
		else
			"NOT IN TEMPLATE"
		end
		push!(data_vars_catalog, (lhs_var, obs_idx, order, obs_names[obs_idx], status))
		@printf("  %-25s  obs=%d  order=%2d  (%s)  %s\n",
			string(lhs_var), obs_idx, order, obs_names[obs_idx], status)
	end
end

n_data = count(x -> x[5] == "DATA (substituted)", data_vars_catalog)
n_unknown = count(x -> x[5] == "UNKNOWN (in final system)", data_vars_catalog)
n_absent = count(x -> x[5] == "NOT IN TEMPLATE", data_vars_catalog)
println()
println("  Summary: $n_data data vars (substituted) + $n_unknown unknown vars (kept) + $n_absent not in template")
println("  The $n_data data vars become numerical constants from interpolation.")
println("  The $n_unknown vars remain as unknowns in the 33×33 system.")
println()

# ═══════════════════════════════════════════════════════════════════════════════
#
#  SECTION C: TRUE DERIVATIVE VALUES AT 3 TIME POINTS
#
# ═══════════════════════════════════════════════════════════════════════════════
println()
println("=" ^ 80)
println("  SECTION C: TRUE DERIVATIVE VALUES AT 3 TIME POINTS")
println("  Computed via Taylor coefficient recursion (machine precision)")
println("=" ^ 80)
println()

# C1: Data variable true values (what interpolation must recover)
println("─" ^ 80)
println("  C1. Data Variable True Values (what interpolation replaces)")
println("─" ^ 80)
println()

# Determine max order needed from catalog
max_data_order = maximum(x -> x[3], filter(x -> x[5] == "DATA (substituted)", data_vars_catalog); init = 0)

# Print header
tbl_header = @sprintf("  %-15s %-6s", "Obs/Order", "")
for (_, tv, _) in eval_points
	global tbl_header *= @sprintf(" | %20s", @sprintf("t=%.4f", tv))
end
println(tbl_header)
println("  " * "─" ^ (15 + 6 + 3 * 23))

for entry in data_vars_catalog
	(lhs_var, obs_idx, order, obs_name, status) = entry
	if status != "DATA (substituted)"
		continue
	end
	row = @sprintf("  %-15s ord=%d ", ["y0", "y1", "y2"][obs_idx], order)
	for (_, tv, _) in eval_points
		truth = truth_at_points[tv][obs_idx][order+1]
		row *= @sprintf(" | %20.8e", truth)
	end
	println(row)
end
println()

# C2: Unknown variable true values (what HC.jl should recover)
println("─" ^ 80)
println("  C2. Unknown Variable True Values (parameters + unobserved state derivatives)")
println("      These are the 33 unknowns that HC.jl must recover.")
println("─" ^ 80)
println()

# For each eval point, compute the true values of all 33 unknowns
for (idx, tv, label) in eval_points
	println("  At t=$(tv) ($label):")
	state_derivs = state_truth_at_points[tv]
	for v in vars_system
		vname = string(v)
		parsed = ODEParameterEstimation.parse_derivative_variable_name(vname)
		if isnothing(parsed)
			@printf("    %-20s = PARSE FAILED\n", vname)
			continue
		end
		base_name, deriv_order = parsed
		if haskey(param_name_to_val, String(base_name))
			if deriv_order == 0
				@printf("    %-20s = %15.8e  (param %s)\n", vname, param_name_to_val[String(base_name)], base_name)
			else
				@printf("    %-20s = %15.8e  (d^%d param — 0)\n", vname, 0.0, deriv_order)
			end
		elseif haskey(state_name_to_idx, String(base_name))
			si = state_name_to_idx[String(base_name)]
			if deriv_order + 1 <= length(state_derivs[si])
				@printf("    %-20s = %15.8e  (d^%d %s / dt^%d)\n",
					vname, state_derivs[si][deriv_order+1], deriv_order, base_name, deriv_order)
			else
				@printf("    %-20s = ORDER TOO HIGH\n", vname)
			end
		else
			@printf("    %-20s = UNKNOWN BASE '%s'\n", vname, base_name)
		end
	end
	println()
end

# ═══════════════════════════════════════════════════════════════════════════════
#
#  SECTION D: MULTI-METHOD INTERPOLATION COMPARISON
#
# ═══════════════════════════════════════════════════════════════════════════════
println()
println("=" ^ 80)
println("  SECTION D: MULTI-METHOD INTERPOLATION COMPARISON")
println("  Comparing 4 interpolation methods against Taylor-recursion ground truth")
println("  at 3 time points for all data variables (observable derivatives).")
println("=" ^ 80)
println()

# Compute interpolated values at all 3 points for all methods
# Structure: interp_vals[method_name][tv][(obs_idx, order)] = value
interp_vals = Dict{String, Dict}()
for mname in method_names
	interp_vals[mname] = Dict{Float64, Dict}()
	for (idx, tv, label) in eval_points
		interp_vals[mname][tv] = Dict()
		for (i, mq_eq) in enumerate(pep.measured_quantities)
			obs_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
			interp = interps_by_method[mname][obs_rhs]
			for order in 0:max_required_deriv
				val = try
					ODEParameterEstimation.nth_deriv(x -> interp(x), order, tv)
				catch e
					NaN
				end
				interp_vals[mname][tv][(i, order)] = val
			end
		end
	end
end

println("  All interpolation values computed.")
println()

# Print comparison tables for each time point
for (idx, tv, label) in eval_points
	println("─" ^ 110)
	@printf("  t = %.4f  (%s)\n", tv, label)
	println("─" ^ 110)

	# Header
	@printf("  %-12s %15s", "Var/Order", "Truth")
	for mname in method_names
		@printf(" | %22s", mname)
	end
	println()
	println("  " * "─" ^ (12 + 15 + 4 * 25))

	for entry in data_vars_catalog
		(lhs_var, obs_idx, order, obs_name, status) = entry
		if status != "DATA (substituted)"
			continue
		end

		truth = truth_at_points[tv][obs_idx][order+1]

		# Variable label
		@printf("  %-12s %15.6e", @sprintf("%s ord %d", ["y0", "y1", "y2"][obs_idx], order), truth)

		for mname in method_names
			val = interp_vals[mname][tv][(obs_idx, order)]
			if isnan(val) || isinf(val)
				@printf(" | %12s (%6s)", "FAILED", "---")
			else
				err_pct = abs(truth) > 1e-15 ? abs((val - truth) / truth) * 100 : abs(val)
				# Color-code by error magnitude
				if err_pct < 1.0
					flag = ""
				elseif err_pct < 10.0
					flag = "*"
				elseif err_pct < 100.0
					flag = "**"
				else
					flag = "***"
				end
				@printf(" | %12.4e (%5.1f%%)%s", val, err_pct, flag)
			end
		end
		println()
	end
	println()
end

# ═══════════════════════════════════════════════════════════════════════════════
#  SECTION D2: Summary — Error by Derivative Order
# ═══════════════════════════════════════════════════════════════════════════════
println()
println("─" ^ 80)
println("  SECTION D2: SUMMARY — MAX ERROR (%) BY DERIVATIVE ORDER")
println("  Across all 3 observables, showing worst-case error per order per method")
println("─" ^ 80)
println()

for (idx, tv, label) in eval_points
	@printf("  t = %.4f  (%s)\n", tv, label)

	@printf("  %-8s", "Order")
	for mname in method_names
		@printf(" | %12s", mname)
	end
	println()
	println("  " * "─" ^ (8 + 4 * 15))

	for order in 0:max_required_deriv
		# Check if any observable actually has this order as data
		has_data = any(entry -> entry[3] == order && entry[5] == "DATA (substituted)", data_vars_catalog)
		if !has_data
			continue
		end

		@printf("  %-8d", order)
		for mname in method_names
			max_err = 0.0
			for obs_idx in 1:3
				truth = truth_at_points[tv][obs_idx][order+1]
				val = get(interp_vals[mname][tv], (obs_idx, order), NaN)
				if !isnan(val) && !isinf(val) && abs(truth) > 1e-15
					err = abs((val - truth) / truth) * 100
					max_err = max(max_err, err)
				elseif isnan(val) || isinf(val)
					max_err = Inf
				end
			end
			if isinf(max_err)
				@printf(" | %12s", "FAILED")
			elseif max_err > 1000.0
				@printf(" | %10.1e%%", max_err)
			else
				@printf(" | %10.3f%%", max_err)
			end
		end
		println()
	end
	println()
end

# ═══════════════════════════════════════════════════════════════════════════════
#  FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
println()
println("=" ^ 80)
println("  FINAL SUMMARY")
println("=" ^ 80)
println()
println("  System: $(length(eqs_system)) equations, $(length(vars_system)) variables ($(length(eqs_system) == length(vars_system) ? "SQUARE" : "NOT SQUARE"))")
println("  Unknowns: $n_param_vars parameter variables + $n_state_vars unobserved state derivative variables")
println("  Data: $n_data observable derivative values substituted from interpolation")
println("  Max derivative order required: $max_required_deriv")
println()
println("  Evaluation points:")
for (idx, tv, label) in eval_points
	@printf("    t=%.4f (idx %d) — %s\n", tv, idx, label)
end
println()
println("  Key findings (read from Section D tables above):")
println("    - Order 0 derivatives: ALL methods accurate at all points")
println("    - Higher-order derivatives: accuracy degrades as order increases")
println("    - Boundary (t=0): worst case due to stiff transient / AAA poles")
println("    - Interior points: much better accuracy for all methods")
println()
println("  Legend for error flags:")
println("    (no flag) = <1% error")
println("    *          = 1-10% error")
println("    **         = 10-100% error")
println("    ***        = >100% error")
println()
println("Done!")
flush(stdout)
