# Optimized Parameter Estimation with Precomputed Derivatives
# This implements a more efficient workflow that computes symbolic derivatives once
# and reuses them across multiple shooting points

# Parent module functions will be available when this file is included

# ============================================================================
# Data Structures
# ============================================================================

"""
	PrecomputedDerivatives

Stores precomputed symbolic derivatives of state and observation equations.
"""
struct PrecomputedDerivatives
	# State equation derivatives (RHS only)
	state_derivatives::Vector{Vector{Any}}  # state_derivatives[i][j] = (j-1)-th derivative of state i RHS

	# Observation equation derivatives  
	obs_derivatives::Vector{Vector{Any}}    # obs_derivatives[i][j] = (j-1)-th derivative of obs i RHS

	# Variable dependencies
	state_deriv_vars::Vector{Vector{Set{Any}}}  # Variables in each derivative
	obs_deriv_vars::Vector{Vector{Set{Any}}}

	# Metadata
	max_deriv_level::Int
	num_states::Int
	num_obs::Int
	num_params::Int
end

"""
	EquationTemplate

Template for the equation system that can be reused across shooting points.
"""
struct EquationTemplate
	# Equations from observations (will use interpolation)
	obs_equations::Vector{Tuple{Any, Any, Int, Int}}  # (LHS symbol, RHS expr, obs_idx, deriv_level)

	# Pure state derivative equations
	state_equations::Vector{Tuple{Any, Any}}     # (LHS, RHS)

	# Variables to solve for
	solve_variables::Vector{Any}

	# Fixed unidentifiable parameters
	fixed_params::OrderedDict{Any, Float64}

	# All unidentifiable parameters (including those not fixed)
	all_unidentifiable::Set{Any}

	# Required derivative levels for each observable
	deriv_levels::OrderedDict{Int, Int}

	# Metadata
	num_equations::Int
	num_variables::Int
end

# ============================================================================
# Phase 1: Derivative Precomputation
# ============================================================================

"""
	_compute_derivatives_for_expressions(expressions, max_level)

Helper function to compute derivatives for a list of expressions.
"""
function _compute_derivatives_for_expressions(expressions, max_level)
	all_derivs = Vector{Vector{Any}}(undef, length(expressions))
	for (i, rhs) in enumerate(expressions)
		derivs = Any[rhs]
		for level in 1:max_level
			d = expand_derivatives(D(derivs[end]))
			d = ModelingToolkit.diff2term(d)
			push!(derivs, d)
		end
		all_derivs[i] = derivs
	end
	return all_derivs
end

"""
	precompute_all_derivatives(model::OrderedODESystem, measured_quantities::Vector)

Precompute all symbolic derivatives of state and observation equations.
"""
function precompute_all_derivatives(model::OrderedODESystem, measured_quantities::Vector)
	t, eqns, states, params = unpack_ODE(model.system)

	# Determine max derivative level
	num_states = length(states)
	num_params = length(params)
	max_level = max(2, min(num_states + num_params, 8))

	@debug "Precomputing derivatives up to level $max_level for $num_states states and $(length(measured_quantities)) observations"

	# Use helper function to compute derivatives
	state_rhses = [eq.rhs for eq in eqns]
	state_derivatives = _compute_derivatives_for_expressions(state_rhses, max_level)
	@debug "Computed derivatives for $(num_states) states"

	obs_rhses = [mq.rhs for mq in measured_quantities]
	obs_derivatives = _compute_derivatives_for_expressions(obs_rhses, max_level)
	@debug "Computed derivatives for $(length(measured_quantities)) observables"

	# Extract variables from each expression
	state_deriv_vars = extract_all_variables(state_derivatives)
	obs_deriv_vars = extract_all_variables(obs_derivatives)

	return PrecomputedDerivatives(
		state_derivatives, obs_derivatives,
		state_deriv_vars, obs_deriv_vars,
		max_level, num_states, length(measured_quantities), num_params,
	)
end

"""
	extract_all_variables(derivatives::Vector{Vector{Any}})

Extract all variables appearing in each derivative expression.
"""
function extract_all_variables(derivatives::Vector{Vector{Any}})
	vars = Vector{Vector{Set{Any}}}()

	for state_derivs in derivatives
		state_vars = Vector{Set{Any}}()
		for expr in state_derivs
			push!(state_vars, extract_variables(expr))
		end
		push!(vars, state_vars)
	end

	return vars
end

"""
	extract_variables(expr)

Extract all variables from a single expression using Symbolics.get_variables.
Normalizes function-type derivative variables to plain symbols.
"""
function extract_variables(expr)
	vars = Set{Any}()
	try
		# Symbolics.get_variables is the robust way to do this
		sym_vars = Symbolics.get_variables(expr)
		for v in sym_vars
			# Check if it's a function-type derivative variable (contains ˍ and ends with (t))
			v_str = string(v)
			if occursin("ˍ", v_str) && endswith(v_str, "(t)")
				# It's a derivative variable in function form - convert to plain symbol
				# Remove the (t) suffix
				plain_name = v_str[1:(end-3)]
				plain_var = Symbolics.variable(Symbol(plain_name))
				push!(vars, plain_var)
			else
				# Not a derivative variable or already plain - keep as is
				push!(vars, v)
			end
		end
	catch e
		@debug "Could not extract variables from expression of type $(typeof(expr)): $e"
	end
	return vars
end

"""
	normalize_derivative_variables(expr)

Replace function-type derivative variables with plain symbols in an expression.
"""
function normalize_derivative_variables(expr)
	# Get all variables in the expression
	vars = Symbolics.get_variables(expr)

	# Build substitution dictionary
	sub_dict = OrderedDict()
	for v in vars
		v_str = string(v)
		if occursin("ˍ", v_str) && endswith(v_str, "(t)")
			# It's a derivative variable in function form
			plain_name = v_str[1:(end-3)]
			plain_var = Symbolics.variable(Symbol(plain_name))
			sub_dict[v] = plain_var
		end
	end

	# Apply substitutions if any
	if !isempty(sub_dict)
		return Symbolics.substitute(expr, sub_dict)
	else
		return expr
	end
end

# ============================================================================
# Phase 2: Identifiability Analysis and Template Creation
# ============================================================================

"""
	find_all_roots_polynomial_roots(rur, variables)
	
Find all roots (including complex) of a RUR using PolynomialRoots.jl
Returns solutions in the same format as RS.rs_isolate for compatibility.
"""
function find_all_roots_polynomial_roots(rur, variables)
	# Use PolynomialRoots (already imported at module level)

	# Extract the univariate polynomial from RUR
	univariate_poly = rur[1]

	# Convert coefficients to Complex{Float64} for PolynomialRoots
	coeffs = Complex{Float64}[]
	for coeff in univariate_poly
		push!(coeffs, Complex(Float64(coeff), 0.0))
	end

	# Find ALL roots (complex and real)
	all_roots = PolynomialRoots.roots(coeffs)

	if isempty(all_roots)
		return []
	end

	# Reconstruct full solutions from univariate roots
	solutions = []

	for root in all_roots
		# Skip roots with very large imaginary parts (likely spurious)
		if abs(imag(root)) > 1e6
			continue
		end

		# Compute derivative of f1 at root for reconstruction
		f1 = univariate_poly
		f1_deriv = sum((i-1) * f1[i] * root^(i-2) for i in 2:length(f1))

		# Skip if derivative is too small (multiple root or numerical issue)
		if abs(f1_deriv) < 1e-14
			continue
		end

		# Reconstruct solution for all variables
		solution = Float64[]

		# For each variable, use the corresponding polynomial in the RUR
		for (idx, var) in enumerate(variables)
			if idx + 1 <= length(rur)
				poly = rur[idx+1]
				value = sum(poly[i] * root^(i-1) for i in 1:length(poly))
				reconstructed = value / f1_deriv

				# Use real part if imaginary part is negligible
				if abs(imag(reconstructed)) < 1e-10
					push!(solution, real(reconstructed))
				else
					# For complex solutions, use the real part (this may need refinement)
					push!(solution, real(reconstructed))
				end
			else
				# If we don't have enough polynomials, use a default value
				push!(solution, 0.0)
			end
		end

		push!(solutions, solution)
	end

	return solutions
end

# ============================================================================

"""
	try_rur_solve(equations, variables)
	
Attempt to solve the system using RUR and return status.
Returns: (:success, solutions), (:no_solutions, []), or (:not_zero_dim, [])
"""
function try_rur_solve(equations, variables)
	try
		# Clear denominators from all equations first
		cleared_equations = clear_denoms(equations, variables)

		# Use robust conversion from robust_conversion.jl
		R, aa_system, var_map = robust_exprs_to_AA_polys(cleared_equations, variables)

		# Try RUR
		rur, sep = RationalUnivariateRepresentation.zdim_parameterization(aa_system, get_separating_element = true)

		# If we get here, system is zero-dimensional - try to find ALL solutions (including complex)
		# Using PolynomialRoots instead of RS to handle complex solutions
		try
			# Use PolynomialRoots to find all roots (complex and real)
			solutions = find_all_roots_polynomial_roots(rur, variables)

			if isempty(solutions)
				return (:no_solutions, [])
			else
				return (:success, solutions)
			end
		catch e
			# Fallback to RS if PolynomialRoots fails
			@debug "PolynomialRoots failed, falling back to RS: $e"
			sol = RS.rs_isolate(rur, sep, output_precision = Int32(20))

			if isempty(sol)
				return (:no_solutions, [])
			else
				# Convert solutions
				solutions = []
				for s in sol
					real_sol = [convert(Float64, real(v[1])) for v in s]
					push!(solutions, real_sol)
				end
				return (:success, solutions)
			end
		end

	catch e
		error_msg = string(e)
		if occursin("zerodimensional ideal", error_msg) || occursin("not zero-dimensional", error_msg)
			return (:not_zero_dim, [])
		elseif occursin("no solutions", error_msg)
			return (:no_solutions, [])
		else
			@warn "RUR solve failed with unexpected error: $e"
			return (:error, [])
		end
	end
end

"""
	build_test_equation_system(precomputed, deriv_levels, fixed_params, model, measured_quantities, random_hyperplanes)
	
Build equation system for testing with RUR (without interpolation).
"""
function build_test_equation_system(
	precomputed::PrecomputedDerivatives,
	deriv_levels::OrderedDict{Int, Int},
	fixed_params::OrderedDict{Any, Float64},
	model::OrderedODESystem,
	measured_quantities::Vector,
	random_hyperplanes::Vector{Any} = [];
	use_random_rhs::Bool = true,  # New parameter to use random RHS values
)
	t, eqns, states, params = unpack_ODE(model.system)

	equations = Any[]

	# Add observation equations with their derivatives
	for (obs_idx, max_level) in deriv_levels
		if obs_idx <= precomputed.num_obs
			for level in 0:max_level
				if level + 1 <= length(precomputed.obs_derivatives[obs_idx])
					eq = precomputed.obs_derivatives[obs_idx][level+1]

					# Normalize derivative variables to plain symbols
					eq = normalize_derivative_variables(eq)

					# Substitute fixed parameters
					if !isempty(fixed_params)
						eq = Symbolics.substitute(eq, fixed_params)
					end

					if use_random_rhs
						# For generic position testing, replace LHS with random value
						# This ensures we're testing if the system CAN have solutions
						# with generic (non-special) values
						# Use larger range to avoid numerical issues with small values
						eq = eq - (rand() * 10 - 5)  # Random value between -5 and 5
					end

					push!(equations, eq)
				end
			end
		end
	end

	# Add state derivative equations
	# We ALWAYS need at least level 1 (the basic ODEs) even if observables are at level 0
	max_deriv_needed = maximum(values(deriv_levels); init = 0)
	min_state_level = max(1, max_deriv_needed)  # At least 1 for basic ODEs
	D = Differential(t)
	for state_idx in 1:precomputed.num_states
		for level in 1:min(min_state_level, precomputed.max_deriv_level-1)
			if level <= length(precomputed.state_derivatives[state_idx])
				state = states[state_idx]

				# Create LHS variable for the derivative - always use plain symbols
				state_name = string(state)
				if endswith(state_name, "(t)")
					state_base = state_name[1:(end-3)]
				else
					state_base = state_name
				end
				# Create plain symbol without (t) for consistency
				lhs = Symbolics.variable(Symbol(state_base * "ˍ" * "t"^level))

				rhs = precomputed.state_derivatives[state_idx][level]

				# Normalize derivative variables to plain symbols
				rhs = normalize_derivative_variables(rhs)

				# Substitute fixed parameters in RHS
				if !isempty(fixed_params)
					rhs = Symbolics.substitute(rhs, fixed_params)
				end

				# Always include the actual equation structure for state derivatives
				# The ODEs define the relationships between variables
				push!(equations, lhs - rhs)
			end
		end
	end

	# Collect all variables
	all_vars = Set{Any}()
	for eq in equations
		union!(all_vars, extract_variables(eq))
	end

	# Remove fixed parameters from solve variables
	solve_variables = [v for v in all_vars if !haskey(fixed_params, v)]

	# Don't add fixed parameter equations - they've already been substituted

	# Add random hyperplanes if any
	for hyperplane in random_hyperplanes
		push!(equations, hyperplane)
	end

	# Don't clear denominators here - the solver will handle it
	return equations, solve_variables
end

"""
	analyze_identifiability(precomputed, model, measured_quantities, data_sample)

Perform adaptive identifiability analysis using RUR feedback to guide equation design.
"""
function analyze_identifiability(
	precomputed::PrecomputedDerivatives,
	model::OrderedODESystem,
	measured_quantities::Vector,
	data_sample::Union{OrderedDict, Nothing} = nothing;
	use_adaptive::Bool = true,
	max_iterations::Int = 20,
	debug_cas_diagnostics::Bool = false,
)
	t, eqns, states, params = unpack_ODE(model.system)

	if !use_adaptive
		# Fallback to OLD workflow
		@debug "Using OLD workflow's multipoint_local_identifiability_analysis"

		deriv_levels_old, unident_dict, ident_vars, DD =
			multipoint_local_identifiability_analysis(
				model.system,
				measured_quantities,
				3, 1e-12, 1e-12,
			)

		fixed_params = OrderedDict{Any, Float64}()
		for (param, value) in unident_dict
			fixed_params[param] = Float64(value)
		end

		# Return all_unidentifiable from DD
		return deriv_levels_old, fixed_params, ident_vars, DD.all_unidentifiable
	end

	# ADAPTIVE APPROACH with RUR feedback
	@info "Using adaptive identifiability analysis with RUR feedback"

	# Step 1: Start with OLD workflow's recommendations
	println("Step 1: Getting baseline from OLD identifiability analysis...")

	deriv_levels_old, unident_dict, ident_vars, DD =
		multipoint_local_identifiability_analysis(
			model.system,
			measured_quantities,
			3, 1e-12, 1e-12,
		)

	# Store all unidentifiable parameters from the analysis
	all_unidentifiable = DD.all_unidentifiable

	deriv_levels = OrderedDict(deriv_levels_old)
	fixed_params = OrderedDict{Any, Float64}()
	for (param, value) in unident_dict
		fixed_params[param] = Float64(value)
	end

	println("  Initial derivative levels: $deriv_levels")
	println("  Fixed parameters: $(keys(fixed_params))")
	println("  All unidentifiable parameters: $all_unidentifiable")

	random_hyperplanes = Any[]

	# Step 2: Iterative refinement based on RUR feedback
	# IMPORTANT: We use random RHS values during adaptive analysis to ensure we're testing
	# the solvability of the system in generic position. This avoids special cases where
	# symbolic equations might have solutions but numerical substitutions become inconsistent
	# due to overdetermination and precision issues.
	for iter in 1:max_iterations
		println("\nIteration $iter:")

		# Build current equation system with random RHS for generic position testing
		equations, variables = build_test_equation_system(
			precomputed, deriv_levels, fixed_params, model, measured_quantities, random_hyperplanes;
			use_random_rhs = true,  # Use random values to ensure generic position
		)

		println("  System: $(length(equations)) equations, $(length(variables)) variables")
		if debug_cas_diagnostics
			println("\nDEBUG: Full equation system for adaptive analysis:")
		end
		for (i, eq) in enumerate(equations)
			println("    Equation $i: $eq")
		end
		println("\n  Variables being solved for: $variables")

		# Try to solve with RUR
		status, solutions = try_rur_solve(equations, variables)

		println("  RUR result: $status")

		if status == :success
			println("  ✅ SUCCESS! Found $(length(solutions)) solution(s)")
			return deriv_levels, fixed_params, ident_vars, all_unidentifiable

		elseif status == :no_solutions
			# System is overconstrained - reduce derivative levels
			println("  System overconstrained (no solutions) - reducing derivative levels...")

			# Find the observable with highest derivative level and reduce it
			reduced = false
			sorted_obs = sort(collect(deriv_levels), by = x->x[2], rev = true)

			for (obs_idx, level) in sorted_obs
				if level > 0
					deriv_levels[obs_idx] = level - 1
					println("    Reduced observable $obs_idx from level $level to $(level-1)")
					reduced = true
					break
				end
			end

			if !reduced
				# If we can't reduce further, try adding a small random perturbation
				# to make the system generic (avoid special cases)
				println("  ⚠️  Cannot reduce derivatives further - adding noise for genericity")
				noise_hyperplane = sum([rand() * v for v in variables]) - rand()
				push!(random_hyperplanes, noise_hyperplane)
				println("    Added noise hyperplane #$(length(random_hyperplanes))")
			end

		elseif status == :not_zero_dim
			# System is underconstrained - try to add more equations
			println("  System not zero-dimensional - trying to add derivatives...")

			improved = false

			# Try increasing each observable's derivative level one at a time
			for obs_idx in 1:precomputed.num_obs
				current_level = get(deriv_levels, obs_idx, 0)

				if current_level < precomputed.max_deriv_level - 1
					deriv_levels[obs_idx] = current_level + 1

					println("    Trying observable $obs_idx at level $(current_level + 1)...")

					# Test the new system with random RHS for generic position
					test_equations, test_variables = build_test_equation_system(
						precomputed, deriv_levels, fixed_params, model, measured_quantities, random_hyperplanes;
						use_random_rhs = true,
					)
					test_status, test_solutions = try_rur_solve(test_equations, test_variables)

					if test_status == :success
						println("      ✅ Success with this increase!")
						return deriv_levels, fixed_params, ident_vars, all_unidentifiable
					elseif test_status == :not_zero_dim
						println("      Still underconstrained but keeping increase")
						improved = true
					else
						println("      Made system overconstrained - rolling back")
						deriv_levels[obs_idx] = current_level
					end
				end
			end

			# If no derivative increase helped, add a random hyperplane
			if !improved
				println("  No derivative increases helped - adding random hyperplane...")
				coeffs = [rand() for _ in variables]
				# Ensure we handle both plain symbols and function-type symbols
				hyperplane_terms = []
				for i in 1:length(variables)
					var = variables[i]
					# If it's a function-type symbol, unwrap it
					if isa(var, Symbolics.BasicSymbolic{Symbolics.FnType})
						# Create a plain symbol version for multiplication
						var_name = string(var)
						if endswith(var_name, "(t)")
							var_name = var_name[1:(end-3)]
						end
						var = Symbolics.variable(Symbol(var_name))
					end
					push!(hyperplane_terms, coeffs[i] * var)
				end
				hyperplane = sum(hyperplane_terms) - rand()
				push!(random_hyperplanes, hyperplane)
				println("    Added hyperplane #$(length(random_hyperplanes))")
			end

		else
			println("  ❌ Unexpected solver status: $status")
			return deriv_levels, fixed_params, ident_vars, all_unidentifiable
		end
	end

	println("\n⚠️  Maximum iterations reached")
	return deriv_levels, fixed_params, ident_vars, all_unidentifiable
end

"""
	create_equation_template(precomputed, deriv_levels, fixed_params, model, measured_quantities)

Create a reusable equation template based on the identifiability analysis.
"""
function create_equation_template(
	precomputed::PrecomputedDerivatives,
	deriv_levels::OrderedDict{Int, Int},
	fixed_params::OrderedDict{Any, Float64},
	ident_vars::Vector,  # Identifiable variables from analysis
	all_unidentifiable::Set{Any},  # All unidentifiable parameters
	model::OrderedODESystem,
	measured_quantities::Vector;
	debug_cas_diagnostics::Bool = false,
)
	t, eqns, states, params = unpack_ODE(model.system)

	obs_equations = Tuple{Any, Any, Int, Int}[]
	state_equations = Tuple{Any, Any}[]

	# Create observation equations (these will use interpolation)
	for (obs_idx, max_level) in deriv_levels
		mq = measured_quantities[obs_idx]
		obs_name = mq.lhs

		for level in 0:max_level
			# Don't create a new variable for LHS - just use a symbol as placeholder
			# The actual value will come from interpolation
			lhs_sym = Symbol("interp_$(obs_name)_d$(level)")

			# RHS is the symbolic expression
			rhs = precomputed.obs_derivatives[obs_idx][level+1]

			# Normalize derivative variables to plain symbols
			rhs = normalize_derivative_variables(rhs)

			# Substitute fixed parameters in RHS
			if !isempty(fixed_params)
				rhs = Symbolics.substitute(rhs, fixed_params)
			end

			push!(obs_equations, (lhs_sym, rhs, obs_idx, level))
		end
	end

	# Create state derivative equations
	# These relate derivatives of states through the ODEs
	# CRITICAL FIX: We ALWAYS need at least the basic ODEs (level 1) even if observable deriv_levels are 0
	# deriv_levels = 0 means we observe the state directly without derivatives
	# but we still need dx/dt = f(x,p) equations to constrain the system!
	max_obs_deriv_needed = maximum(values(deriv_levels); init = 0)

	# We need state equations at least up to level 1 (basic ODEs)
	# If observables need higher derivatives, we need those too
	min_state_level = max(1, max_obs_deriv_needed)

	if debug_cas_diagnostics
		println("DEBUG create_equation_template:")
	end
	println("  deriv_levels = $deriv_levels")
	println("  max_obs_deriv_needed = $max_obs_deriv_needed")
	println("  min_state_level = $min_state_level (at least 1 for basic ODEs)")
	println("  precomputed.max_deriv_level = $(precomputed.max_deriv_level)")

	for state_idx in 1:precomputed.num_states
		state = states[state_idx]

		# NOTE: We need equations for ALL states, even unidentifiable ones!
		# The ODEs for unidentifiable states like x1 and x2 contain crucial
		# relationships with parameters (e.g., x1' = -a*x1, x2' = b*x2)
		# that are needed to recover parameters a and b.

		# Use min_state_level to ensure we have at least the basic ODEs
		level_range = 1:min(min_state_level, precomputed.max_deriv_level-1)

		if state in all_unidentifiable
			println("  State $state_idx ($state): creating equations for levels $level_range (unidentifiable but needed)")
		else
			println("  State $state_idx ($state): creating equations for levels $level_range")
		end
		for level in level_range
			# Create proper symbolic variable for state derivatives - always use plain symbols
			# Strip (t) from state name and add derivative suffixes
			state_name = string(state)
			if endswith(state_name, "(t)")
				state_base = state_name[1:(end-3)]  # Remove "(t)"
			else
				state_base = state_name
			end
			# Create variable with ˍ notation for derivatives (matching ModelingToolkit convention)
			# Create plain symbol without (t) for consistency
			lhs = Symbolics.variable(Symbol(state_base * "ˍ" * "t"^level))

			# RHS comes from the precomputed derivatives
			# For level 1: we want the RHS of the ODE (index 1)
			# For level 2: we want the first derivative of the RHS (index 2), etc.
			rhs = precomputed.state_derivatives[state_idx][level]

			# Normalize derivative variables to plain symbols
			rhs = normalize_derivative_variables(rhs)

			# Substitute fixed parameters in RHS
			if !isempty(fixed_params)
				rhs = Symbolics.substitute(rhs, fixed_params)
			end

			push!(state_equations, (lhs, rhs))
		end
	end

	# Use the identifiable variables from the analysis as our base
	# This already includes all identifiable parameters and states
	solve_vars_set = Set{Any}(ident_vars)

	if debug_cas_diagnostics
		println("\nDEBUG: Building variable list for template...")
	end
	println("  Starting with $(length(ident_vars)) identifiable variables from analysis:")
	println("    $ident_vars")

	# Add derivative variables that appear in our equations
	# These are needed to solve the system but aren't in the base ident_vars
	derivative_vars_added = 0

	# From state equations - add LHS derivatives
	for (lhs, rhs) in state_equations
		if !(lhs in solve_vars_set)
			push!(solve_vars_set, lhs)
			derivative_vars_added += 1
		end
		# Also check RHS for any derivative variables
		rhs_vars = extract_variables(rhs)
		for v in rhs_vars
			if !(v in solve_vars_set) && !haskey(fixed_params, v)
				push!(solve_vars_set, v)
				derivative_vars_added += 1
			end
		end
	end

	println("  Added $derivative_vars_added derivative variables from state equations")

	# Convert set to array for the template
	solve_variables = collect(solve_vars_set)

	# Add equations for fixed parameters
	fixed_param_equations = []
	for (param, value) in fixed_params
		# Add equation: param = value
		push!(fixed_param_equations, (param, value))
	end

	num_equations = length(obs_equations) + length(state_equations) + length(fixed_param_equations)
	num_variables = length(solve_variables)

	if debug_cas_diagnostics
		println("\nDEBUG: Final template summary:")
	end
	println("  Observation equations: $(length(obs_equations))")
	if !isempty(obs_equations)
		for (i, eq) in enumerate(obs_equations)
			println("    Obs eq $i: $eq")
		end
	end
	println("  State equations: $(length(state_equations))")
	if !isempty(state_equations)
		for (i, (lhs, rhs)) in enumerate(state_equations)
			println("    State eq $i: $lhs = $rhs")
		end
	end
	println("  Fixed parameter equations: $(length(fixed_param_equations))")
	for (param, val) in fixed_param_equations
		println("    Fixed: $param = $val")
	end
	println("  Total equations: $num_equations")
	println("  Solve variables: $num_variables")
	println("  Variables are: $(solve_variables)")

	@debug "Created template with $num_equations equations and $num_variables variables"

	return EquationTemplate(
		obs_equations,
		state_equations,
		solve_variables,
		fixed_params,
		all_unidentifiable,
		deriv_levels,
		num_equations,
		num_variables,
	)
end

# ============================================================================
# Phase 3: Solving at Shooting Points
# ============================================================================

"""
	build_equations_at_time_point(template, time_point, interpolants, measured_quantities)

Build the actual equation system at a specific time point by substituting interpolated values.
"""
function build_equations_at_time_point(
	template::EquationTemplate,
	time_point::Float64,
	interpolants::Dict,
	measured_quantities::Vector;
	debug_cas_diagnostics::Bool = false,
)
	equations = Any[]

	# Substitute interpolated values into observation equations
	for (lhs_sym, rhs_expr, obs_idx, deriv_level) in template.obs_equations
		# Get the observable RHS from measured_quantities (interpolants are keyed by RHS)
		if obs_idx <= length(measured_quantities)
			obs_rhs = measured_quantities[obs_idx].rhs

			# Get interpolated derivative value if we have interpolants
			if !isempty(interpolants)
				if haskey(interpolants, obs_rhs)
					interp_func = interpolants[obs_rhs]
					interp_value = nth_deriv_at(interp_func, deriv_level, time_point)
					push!(equations, rhs_expr - interp_value)
				else
					# Try with the LHS wrapped
					obs_lhs_wrapped = Symbolics.wrap(measured_quantities[obs_idx].lhs)
					if haskey(interpolants, obs_lhs_wrapped)
						interp_func = interpolants[obs_lhs_wrapped]
						interp_value = nth_deriv_at(interp_func, deriv_level, time_point)
						push!(equations, rhs_expr - interp_value)
					else
						# No interpolant - just use the equation as is for testing
						push!(equations, rhs_expr)
					end
				end
			else
				# No interpolants provided - just use the equation as is
				push!(equations, rhs_expr)
			end
		end
	end

	# Add state derivative equations (these don't need interpolation)
	for (lhs, rhs) in template.state_equations
		push!(equations, lhs - rhs)
	end

	# Don't clear denominators here - the solver will handle it

	# Debug output showing the complete instantiated system
	if debug_cas_diagnostics
		println("\nDEBUG: Complete instantiated equation system at t=$time_point:")
	end
	println("  Total equations: $(length(equations))")
	for (i, eq) in enumerate(equations)
		println("    Equation $i: $eq")
	end

	return equations
end

"""
	solve_at_shooting_point(template, precomputed, interpolants, time_point, time_index, solver_func)

Instantiate the template with interpolated values and solve at a single shooting point.
"""
function solve_at_shooting_point(
	template::EquationTemplate,
	precomputed::PrecomputedDerivatives,
	interpolants::Dict,
	time_point::Float64,
	time_index::Int,
	solver_func::Function;
	measured_quantities::Vector = Vector(),
	debug_cas_diagnostics::Bool = false,
)
	# Build the actual equation system with denominators cleared
	equations = build_equations_at_time_point(template, time_point, interpolants, measured_quantities;
		debug_cas_diagnostics = debug_cas_diagnostics)

	if debug_cas_diagnostics
		println("\nDEBUG: Solving system at time point $time_point:")
	end
	println("  Number of equations: $(length(equations))")
	println("  Number of variables: $(length(template.solve_variables))")
	println("  Variables being solved for: $(template.solve_variables)")

	# Solve the system
	try
		solutions, hc_vars, trivial_dict, trimmed_vars = solver_func(equations, template.solve_variables)
		if debug_cas_diagnostics
			println("  DEBUG: Solver returned $(length(solutions)) solution(s)")
		end
		if !isempty(solutions) && !isempty(solutions[1])
			if debug_cas_diagnostics
				println("  DEBUG: First solution sample: $(solutions[1][1:min(3, length(solutions[1]))])")
			end
		end
		return solutions, trivial_dict
	catch e
		@warn "Failed to solve at time point $time_point: $e"
		return [], OrderedDict()
	end
end

# ============================================================================
# Phase 4: Main Workflow
# ============================================================================

"""
	optimized_multishot_parameter_estimation(PEP; kwargs...)

Optimized parameter estimation using precomputed derivatives.
Drop-in replacement for multishot_parameter_estimation.
"""
function optimized_multishot_parameter_estimation(
	PEP::ParameterEstimationProblem;
	system_solver = solve_with_rs_new,
	max_num_points = 1,  # Ignored - we don't do multipoint
	interpolator = nothing,  # Will use default if not specified
	nooutput = false,
	diagnostics = false,
	diagnostic_data = nothing,
	polish_solutions = false,
	polish_maxiters = 20,
	polish_method = NewtonTrustRegion,
	shooting_points = 10,
	debug_solver = false,
	debug_cas_diagnostics = false,
	debug_dimensional_analysis = false,
)
	# Check input validity
	if isnothing(PEP.data_sample)
		error("No data sample provided in the ParameterEstimationProblem")
	end

	# Set default interpolator if not provided
	if isnothing(interpolator)
		interpolator = aaad_gpr_pivot
	end

	# DEBUG: Show the original ODE system
	if debug_cas_diagnostics
		println("\nDEBUG: Original ODE System:")
	end
	t, eqns, states, params = unpack_ODE(PEP.model.system)
	println("  Parameters: ", params)
	println("  State variables: ", states)
	println("  ODE equations:")
	for (i, eq) in enumerate(eqns)
		println("    $i. $eq")
	end
	println("  Measured quantities:")
	for (i, mq) in enumerate(PEP.measured_quantities)
		println("    $i. $(mq.lhs) = $(mq.rhs)")
	end
	println()

	# PHASE 1: Precompute all derivatives once
	if !nooutput
		println("Phase 1: Precomputing derivatives...")
	end
	precomputed = precompute_all_derivatives(PEP.model, PEP.measured_quantities)

	# PHASE 2: Analyze identifiability and create template
	if !nooutput
		println("Phase 2: Analyzing identifiability...")
	end
	deriv_levels, fixed_params, ident_vars, all_unidentifiable = analyze_identifiability(
		precomputed, PEP.model, PEP.measured_quantities, PEP.data_sample;
		debug_cas_diagnostics = debug_cas_diagnostics,
	)

	template = create_equation_template(
		precomputed, deriv_levels, fixed_params, ident_vars, all_unidentifiable, PEP.model, PEP.measured_quantities;
		debug_cas_diagnostics = debug_cas_diagnostics,
	)

	if !nooutput
		println("Created template with $(template.num_equations) equations, $(template.num_variables) variables")
		if !isempty(fixed_params)
			println("Fixed parameters: $(fixed_params)")
		end
	end

	# Create interpolants for the data
	t_vector = PEP.data_sample["t"]
	interpolants = create_interpolants(
		PEP.measured_quantities, PEP.data_sample, t_vector, interpolator,
	)

	# PHASE 3: Solve at each shooting point
	all_solutions = []
	all_trivial_dicts = []

	# Create shooting points across time interval
	n_points = min(shooting_points, length(t_vector))
	# Handle edge case when t_vector has only 2 points
	if length(t_vector) <= 2
		point_indices = [1]  # Just use the first point
	elseif n_points == 1
		point_indices = [1]  # Use first point (t=0)
	elseif n_points == 2
		point_indices = [1, length(t_vector)]  # Use both endpoints
	else
		# Include both endpoints and distribute remaining points evenly
		point_indices = round.(Int, range(1, length(t_vector), length = n_points))
	end

	if !nooutput
		println("Phase 3: Solving at $n_points shooting points...")
	end

	for (i, idx) in enumerate(point_indices)
		time_point = t_vector[idx]

		if !nooutput && diagnostics
			println("  Solving at point $i/$n_points (t = $time_point)")
		end

		# Solve at this point
		solutions, trivial_dict = solve_at_shooting_point(
			template, precomputed, interpolants,
			time_point, idx, system_solver,
			measured_quantities = PEP.measured_quantities,
			debug_cas_diagnostics = debug_cas_diagnostics,
		)

		# Process each solution
		for (sol_idx, sol) in enumerate(solutions)
			# Convert solution vector to dict if needed
			sol_dict = if isa(sol, Dict)
				sol
			else
				# Map solution vector to variables
				OrderedDict(zip(template.solve_variables, sol))
			end

			# Convert solution to proper format
			result = process_single_solution(
				sol_dict, template, PEP, time_point, idx, trivial_dict,
			)

			if !isnothing(result)
				push!(all_solutions, result)
			end
		end

		if !isempty(trivial_dict)
			push!(all_trivial_dicts, trivial_dict)
		end
	end

	if !nooutput
		println("Found $(length(all_solutions)) solutions total")
	end

	# Merge trivial dictionaries
	merged_trivial = OrderedDict()
	for td in all_trivial_dicts
		merge!(merged_trivial, td)
	end

	# PHASE 4: Polish if requested
	if polish_solutions && !isempty(all_solutions)
		if !nooutput
			println("Phase 4: Polishing solutions...")
		end

		polished = []
		for (i, candidate) in enumerate(all_solutions)
			try
				polished_result, opt_result = polish_solution_using_optimization(
					candidate, PEP,
					solver = PEP.solver,
					opt_method = polish_method,
					opt_maxiters = polish_maxiters,
				)

				if polished_result.err < candidate.err
					push!(polished, polished_result)
				else
					push!(polished, candidate)
				end
			catch e
				@debug "Failed to polish solution $i: $e"
				push!(polished, candidate)
			end
		end
		all_solutions = polished
	end

	# Return in the expected format
	# IMPORTANT: Return all_unidentifiable from the identifiability analysis, not just fixed_params keys
	return (all_solutions, fixed_params, merged_trivial, all_unidentifiable)
end

# ============================================================================
# Helper Functions
# ============================================================================

"""
	process_single_solution(sol, template, PEP, time_point, time_index, trivial_dict)

Convert a raw solution into a ParameterEstimationResult.
"""
function process_single_solution(
	sol::Dict,
	template::EquationTemplate,
	PEP::ParameterEstimationProblem,
	time_point::Float64,
	time_index::Int,
	trivial_dict::Dict,
)
	t, eqns, states, params = unpack_ODE(PEP.model.system)

	# Extract parameters and states from solution
	param_values = OrderedDict()
	state_values = OrderedDict()

	# Get parameters
	for p in params
		if haskey(template.fixed_params, p)
			param_values[p] = template.fixed_params[p]
		elseif haskey(sol, p)
			param_values[p] = real(sol[p])
		elseif haskey(trivial_dict, p)
			param_values[p] = real(trivial_dict[p])
		else
			@debug "Parameter $p not found in solution"
			return nothing
		end
	end

	# Get states at the time point
	for s in states
		if haskey(sol, s)
			state_values[s] = real(sol[s])
		elseif haskey(trivial_dict, s)
			state_values[s] = real(trivial_dict[s])
		elseif haskey(template.fixed_params, s)
			# Some states may be fixed due to unidentifiability
			state_values[s] = template.fixed_params[s]
		else
			@debug "State $s not found in solution"
			return nothing
		end
	end

	# Backward integrate to get initial conditions
	try
		# Use the existing model from PEP
		t_vector = PEP.data_sample["t"]
		tspan = (time_point, t_vector[1])

		u0_map = OrderedDict(states .=> collect(values(state_values)))
		p_map = OrderedDict(params .=> collect(values(param_values)))

		# Use the existing completed model from PEP
		prob = ModelingToolkit.ODEProblem(PEP.model.system, merge(u0_map, p_map), tspan)
		ode_solution = ModelingToolkit.solve(prob, PEP.solver, abstol = 1e-14, reltol = 1e-14)

		# Extract initial conditions
		# Create mapping to handle state variable names
		state_param_map = OrderedDict(x => replace(string(x), "(t)" => ""
															  for x in states))

		initial_states = OrderedDict()
		for s in states
			initial_states[s] = ode_solution[Symbol(state_param_map[s])][end]
		end

		# Calculate error by forward solving and comparing to data
		forward_tspan = (t_vector[1], t_vector[end])
		forward_u0 = OrderedDict(states .=> collect(values(initial_states)))
		forward_prob = ModelingToolkit.ODEProblem(PEP.model.system, merge(forward_u0, p_map), forward_tspan)
		forward_sol = ModelingToolkit.solve(forward_prob, PEP.solver, abstol = 1e-14, reltol = 1e-14, saveat = t_vector)

		# Calculate error by comparing with data
		total_error = 0.0

		# Use the same approach as the OLD workflow in process_raw_solution
		# IMPORTANT: Use forward_sol(t_vector)[key] syntax which allows ModelingToolkit
		# to handle the mapping from measured quantities to state variables
		if forward_sol.retcode == ReturnCode.Success
			total_error = 0.0
			for (key, sample) in PEP.data_sample
				if isequal(key, "t")
					continue
				end
				# Use the same syntax as OLD workflow: ode_solution(data_sample["t"])[key]
				# This allows ModelingToolkit to handle the mapping from measured quantities to states
				total_error += norm((forward_sol(PEP.data_sample["t"])[key]) .- sample) / length(PEP.data_sample["t"])
			end
			# Normalize by total number of data entries (excluding "t")
			total_error /= length(PEP.data_sample)
		else
			total_error = 1e15  # Large error for failed solutions
		end

		# Create result
		result = ParameterEstimationResult(
			param_values,
			initial_states,
			time_point,
			total_error,
			:success,
			length(t_vector),
			time_point,
			template.fixed_params,
			template.all_unidentifiable,
			forward_sol,
		)

		return result

	catch e
		@warn "Failed to process solution: $e"
		@warn "Stacktrace:"
		for (exc, bt) in Base.catch_stack()
			showerror(stderr, exc, bt)
			println(stderr)
		end
		return nothing
	end
end

# Export the main function
export optimized_multishot_parameter_estimation
