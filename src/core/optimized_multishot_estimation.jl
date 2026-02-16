# Optimized Parameter Estimation with Precomputed Derivatives
# This implements a more efficient workflow that computes symbolic derivatives once
# and reuses them across multiple shooting points

# Parent module functions will be available when this file is included

# ============================================================================
# Phase Profiling Helpers
# ============================================================================

"""
	_record_phase!(f, stats, name)

Lightweight phase profiling helper. When `stats` is `nothing`, simply calls `f()`
with zero overhead. When `stats` is an OrderedDict, wraps `f()` with `@timed`
and records time, bytes, and GC time.

The `f` argument comes first to support Julia's `do` block syntax:
```julia
result = _record_phase!(phase_stats, "Phase name") do
    expensive_computation()
end
```
"""
function _record_phase!(f::Function, stats::Nothing, name::String)
	return f()
end

function _record_phase!(f::Function, stats::OrderedDict{String, NamedTuple}, name::String)
	result = @timed f()
	stats[name] = (time = result.time, bytes = result.bytes, gctime = result.gctime)
	return result.value
end

"""
	_format_bytes(bytes)

Format byte count as human-readable string (B, KiB, MiB, GiB).
"""
function _format_bytes(bytes::Number)
	if bytes < 1024
		return @sprintf("%.0f B", bytes)
	elseif bytes < 1024^2
		return @sprintf("%.1f KiB", bytes / 1024)
	elseif bytes < 1024^3
		return @sprintf("%.1f MiB", bytes / 1024^2)
	else
		return @sprintf("%.2f GiB", bytes / 1024^3)
	end
end

"""
	_print_phase_profile(stats)

Print a formatted table of phase timing and allocation statistics.
"""
function _print_phase_profile(stats::OrderedDict{String, NamedTuple})
	isempty(stats) && return

	# Compute totals
	total_time = sum(s.time for s in values(stats))
	total_bytes = sum(s.bytes for s in values(stats))
	total_gc = sum(s.gctime for s in values(stats))
	total_gc_pct = total_time > 0 ? 100.0 * total_gc / total_time : 0.0

	# Column widths
	name_w = max(47, maximum(length(k) + 4 for k in keys(stats)))  # +4 for "N. " prefix

	println()
	println("╔", "═"^name_w, "╤══════════╤═════════════╤═══════╗")
	@printf("║ %-*s│ %8s │ %11s │ %5s ║\n", name_w - 1, "Phase", "Time (s)", "Allocs", "GC %")
	println("╠", "═"^name_w, "╪══════════╪═════════════╪═══════╣")

	for (i, (name, s)) in enumerate(stats)
		gc_pct = s.time > 0 ? 100.0 * s.gctime / s.time : 0.0
		label = "$i. $name"
		@printf("║ %-*s│ %8.2f │ %11s │ %4.1f%% ║\n", name_w - 1, label, s.time, _format_bytes(s.bytes), gc_pct)
	end

	println("╠", "═"^name_w, "╪══════════╪═════════════╪═══════╣")
	@printf("║ %-*s│ %8.2f │ %11s │ %4.1f%% ║\n", name_w - 1, "TOTAL", total_time, _format_bytes(total_bytes), total_gc_pct)
	println("╚", "═"^name_w, "╧══════════╧═════════════╧═══════╝")
end

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
	fixed_params::OrderedDict{Num, Float64}

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

# ============================================================================

"""
	try_rur_solve(equations, variables)
	
Attempt to solve the system using RUR and return status.
Returns: (:success, solutions), (:no_solutions, []), or (:not_zero_dim, [])
"""

"""
	build_test_equation_system(precomputed, deriv_levels, fixed_params, model, measured_quantities, random_hyperplanes)
	
Build equation system for testing with RUR (without interpolation).
"""
function build_test_equation_system(
	precomputed::PrecomputedDerivatives,
	deriv_levels::OrderedDict{Int, Int},
	fixed_params::OrderedDict{Num, Float64},
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

		fixed_params = OrderedDict{Num, Float64}()
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
	fixed_params = OrderedDict{Num, Float64}()
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
	fixed_params::OrderedDict{Num, Float64},
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
	end

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
					# Use TaylorDiff-based nth_deriv instead of recursive ForwardDiff
					interp_value = ODEParameterEstimation.nth_deriv(x -> interp_func(x), deriv_level, time_point)
					push!(equations, rhs_expr - interp_value)
				else
					# Try with the LHS wrapped
					obs_lhs_wrapped = Symbolics.wrap(measured_quantities[obs_idx].lhs)
					if haskey(interpolants, obs_lhs_wrapped)
						interp_func = interpolants[obs_lhs_wrapped]
						# Use TaylorDiff-based nth_deriv instead of recursive ForwardDiff
						interp_value = ODEParameterEstimation.nth_deriv(x -> interp_func(x), deriv_level, time_point)
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
		println("  Total equations: $(length(equations))")
		for (i, eq) in enumerate(equations)
			println("    Equation $i: $eq")
			# Check for NaN/Inf in equation
			try
				eq_str = string(eq)
				if occursin("NaN", eq_str) || occursin("Inf", eq_str)
					println("      WARNING: Equation contains NaN or Inf!")
				end
			catch e
				@debug "Equation string conversion failed" exception = e
			end
		end
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
		println("\nDEBUG: Calling solver with:")
		println("  Solver function: $(nameof(solver_func))")
		println("  Number of equations: $(length(equations))")
		println("  Number of variables: $(length(template.solve_variables))")

		# Check equations for NaN/Inf before solving
		for (i, eq) in enumerate(equations)
			try
				# Try to evaluate the equation symbolically to detect issues
				eq_val = Symbolics.value(eq)
				if eq_val isa Number && (isnan(eq_val) || isinf(eq_val))
					println("  ERROR: Equation $i evaluates to $(eq_val)")
				end
			catch e
				@debug "Symbolic equation evaluation check skipped (expected if contains variables)" exception = e
			end
		end

		# Pass debug flag if solver supports it
		solutions, hc_vars, trivial_dict, trimmed_vars = if solver_func == solve_with_rs_new
			solver_func(equations, template.solve_variables; debug = debug_cas_diagnostics)
		else
			solver_func(equations, template.solve_variables)
		end

		if debug_cas_diagnostics
			println("  Solver returned $(length(solutions)) solution(s)")
			if !isempty(solutions)
				for (sol_idx, sol) in enumerate(solutions)
					println("  Solution $sol_idx (length=$(length(sol))):")
					for (var_idx, val) in enumerate(sol)
						if var_idx <= length(template.solve_variables)
							var_name = template.solve_variables[var_idx]
							if isnan(val) || isinf(val)
								println("    WARNING: $var_name = $val (NaN or Inf!)")
							else
								println("    $var_name = $val")
							end
						else
							println("    Index $var_idx = $val")
						end
					end
				end
			end
		end

		return solutions, trivial_dict
	catch e
		if debug_cas_diagnostics
			println("\nERROR: Failed to solve at time point $time_point")
			println("  Exception type: $(typeof(e))")
			println("  Exception message: $e")

			# Print detailed stack trace
			println("\nDetailed stack trace:")
			for (exc, bt) in Base.catch_stack()
				showerror(stdout, exc, bt)
				println()
			end

			# Print the equations that failed
			println("\nFailed equations:")
			for (i, eq) in enumerate(equations)
				println("  Equation $i: $eq")
			end
			println("\nVariables to solve: $(template.solve_variables)")
		else
			@warn "Failed to solve at time point $time_point: $e"
		end

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
function optimized_multishot_parameter_estimation(PEP::ParameterEstimationProblem, opts::EstimationOptions = EstimationOptions())
	# Check input validity
	if isnothing(PEP.data_sample)
		error("No data sample provided in the ParameterEstimationProblem")
	end

	# Auto-handle transcendental functions (sin/cos/exp) if enabled
	tr_info = nothing
	if opts.auto_handle_transcendentals
		t_var = ModelingToolkit.get_iv(PEP.model.system)
		PEP, tr_info = transform_pep_for_estimation(PEP, t_var)
		if !isnothing(tr_info) && !opts.nooutput
			println("Transcendental handling: transformed $(length(tr_info.entries)) expression(s) into polynomial form")
		end
	end

	# Extract function references from options
	system_solver = get_solver_function(opts.system_solver)
	interpolator = get_interpolator_function(opts.interpolator, opts.custom_interpolator)

	# Fast path: Use SI template exactly like the standard flow, but reuse it for all selected
	# shooting points in this run. This mirrors PE.jl construction.
	if opts.use_si_template
		# Phase profiling: initialize stats collector (nothing = disabled, zero overhead)
		phase_stats = opts.profile_phases ? OrderedDict{String, NamedTuple}() : nothing

		# Get common setup (derivative levels, udict, varlist, DD, interpolants)
		setup_data = _record_phase!(phase_stats, "Setup (identifiability + interpolants)") do
		setup_parameter_estimation(
			PEP,
			max_num_points = 1,
			point_hint = 0.5,
			nooutput = opts.nooutput,
			interpolator = interpolator,
		)
		end

		states = setup_data.states
		params = setup_data.params
		t_vector = setup_data.t_vector
		interpolants = setup_data.interpolants
		good_deriv_level = setup_data.good_deriv_level
		good_udict = setup_data.good_udict
		good_varlist = setup_data.good_varlist
		good_DD = setup_data.good_DD

		# Build the SI template ONCE using ITERATIVE PARAMETER FIXING
		# We fix ONE parameter at a time and re-run full SIAN analysis
		# until the system is determined (equations == variables)
		ordered_model = isa(PEP.model.system, OrderedODESystem) ? PEP.model.system : OrderedODESystem(PEP.model.system, states, params)

		si_template, template_equations = _record_phase!(phase_stats, "SI Template (SIAN analysis)") do
		pre_fixed_params = OrderedDict{Num, Float64}()
		max_fix_iterations = 10
		iteration = 0
		converged = false
		si_template = nothing

		while iteration < max_fix_iterations && !converged
			iteration += 1
			@info "[ITERATIVE-FIX] Iteration $iteration, fixed so far: $(keys(pre_fixed_params))"

			# Run SIAN analysis with current pre-fixed parameters
			template_equations, derivative_dict, unidentifiable, identifiable_funcs = get_si_equation_system(
				ordered_model,
				PEP.measured_quantities,
				PEP.data_sample;
				DD = good_DD,
				infolevel = opts.diagnostics ? 1 : 0,
				pre_fixed_params = pre_fixed_params,
			)

			si_template = (
				equations = template_equations,
				deriv_dict = derivative_dict,
				unidentifiable = unidentifiable,
				identifiable_funcs = identifiable_funcs,
			)

			# Count equations and variables in the current system
			# Note: We need to count only UNKNOWN variables, not data values (y_i)
			n_equations = length(template_equations)
			vars_in_system = OrderedSet{Any}()
			for eq in template_equations
				union!(vars_in_system, Symbolics.get_variables(eq))
			end

			# Build set of ALL observable derivative variables from DD structure.
			# DD.obs_lhs[order+1][obs_idx] gives the Symbolics variable for the
			# order-th derivative of observable obs_idx.  These are the exact
			# variables that si_template_integration.jl substitutes with
			# interpolated numerical values at each shooting point.
			obs_data_vars = Set{Any}()
			if !isnothing(good_DD)
				for level in good_DD.obs_lhs
					for v in level
						push!(obs_data_vars, v)
					end
				end
			end

			unknown_vars = OrderedSet{Any}()
			data_vars = OrderedSet{Any}()
			for v in vars_in_system
				if v in obs_data_vars
					push!(data_vars, v)
				else
					push!(unknown_vars, v)
				end
			end
			n_variables = length(unknown_vars)
			n_data_vars = length(data_vars)

			# Additionally classify _trfn_ variables as known data.
			# These represent sin(c*t), cos(c*t) etc. evaluated at shooting points —
			# their values are analytically computable, not free unknowns.
			trfn_var_info, real_solve_vars, trfn_only_eq_indices = classify_trfn_in_template(
				collect(unknown_vars), Set(data_vars), template_equations
			)
			n_trfn_vars = length(trfn_var_info)
			n_trfn_only_eqs = length(trfn_only_eq_indices)
			n_effective_eqs = n_equations - n_trfn_only_eqs
			n_effective_vars = n_variables - n_trfn_vars

			@info "[ITERATIVE-FIX] System status: $n_equations equations, $n_variables unknowns (+ $n_data_vars data variables)"
			if n_trfn_vars > 0
				@info "[ITERATIVE-FIX] _trfn_ vars: $n_trfn_vars known inputs, $n_trfn_only_eqs trivial equations"
				@info "[ITERATIVE-FIX] Effective system: $n_effective_eqs equations, $n_effective_vars real unknowns"
			end

			# Use effective counts for convergence check
			# (accounting for _trfn_ vars that will be pre-substituted at solve time)
			if n_effective_eqs == n_effective_vars
				@info "[ITERATIVE-FIX] CONVERGED: Determined system achieved after $iteration iteration(s)"
				converged = true
			elseif n_effective_eqs > n_effective_vars && n_effective_eqs <= n_effective_vars + 2
				# Slightly overdetermined is OK — HC handles via randomization
				@info "[ITERATIVE-FIX] CONVERGED: Nearly-determined system ($n_effective_eqs eqs, $n_effective_vars vars) after $iteration iteration(s)"
				converged = true
			elseif n_effective_eqs < n_effective_vars
				# Underdetermined (more unknowns than equations) - fix ONE parameter to reduce unknowns
				already_fixed = Set(keys(pre_fixed_params))
				param_to_fix, fix_value = select_one_parameter_to_fix(
					si_template, already_fixed, opts.diagnostics; states = states
				)

				if param_to_fix === nothing
					@warn "[ITERATIVE-FIX] No parameter available to fix, stopping iteration (still underdetermined)"
					break
				end

				@info "[ITERATIVE-FIX] Fixing parameter: $param_to_fix = $fix_value (to reduce unknowns)"
				pre_fixed_params[param_to_fix] = fix_value
				# Loop continues - will re-run SIAN with the new fixed param
			else
				# Severely overdetermined - cannot proceed
				@warn "[ITERATIVE-FIX] Overdetermined system ($n_effective_eqs eqs > $n_effective_vars vars), cannot fix by adding parameters"
				break
			end
		end

		if !converged && iteration >= max_fix_iterations
			@warn "[ITERATIVE-FIX] Did not converge after $max_fix_iterations iterations"
		end

		@info "[DEBUG-EQ-COUNT] Final SI template: $(length(si_template.equations)) equations after iterative fixing"
		template_equations = si_template.equations
		# Note: We no longer call handle_unidentifiability here since iterative fixing handles it
		(si_template, template_equations)
		end

		# Enable default system saving for SI-template path and save template once
		if opts.save_system
			vars_in_template = Symbolics.get_variables.(template_equations)
			varset = Set{Any}()
			for vs in vars_in_template
				for v in vs
					push!(varset, v)
				end
			end
			varlist_template = collect(varset)
			save_filepath_tpl = joinpath("saved_systems", "si_template_$(now()).jl")
			mkpath(dirname(save_filepath_tpl))
			save_poly_system(save_filepath_tpl, template_equations, varlist_template,
				metadata = Dict(
					"timestamp" => string(now()),
					"num_equations" => length(template_equations),
					"num_variables" => length(varlist_template),
					"description" => "StructuralIdentifiability template polynomial system",
				),
			)
			if !opts.nooutput
				@info "Saved SI template to $(save_filepath_tpl)"
			end
		end

		# Select shooting points (reuse non-SI logic)
		if opts.shooting_points == 0
			# Single midpoint
			mid = max(1, min(length(t_vector), round(Int, 0.499 * length(t_vector))))
			point_indices = [mid]
			n_points = 1
		else
			n_points = min(opts.shooting_points, length(t_vector))
			if length(t_vector) <= 2
				point_indices = [1]
			elseif n_points == 1
				point_indices = [1]
			elseif n_points == 2
				point_indices = [1, length(t_vector)]
			else
				point_indices = round.(Int, range(1, length(t_vector), length = n_points))
			end
		end

		if !opts.nooutput
			if n_points == 1
				println("Phase 3: Solving system using SI template at a single shooting point (t=$(t_vector[point_indices[1]]))...")
			elseif opts.use_parameter_homotopy && opts.system_solver == SolverHC && n_points >= 3
				println("Phase 3: Solving at $n_points shooting points using PARAMETER HOMOTOPY...")
			else
				println("Phase 3: Solving at $n_points shooting points using a reused SI template...")
			end
		end

		# Iterate through shooting points, instantiating the template and solving independently at each
		# Enable default system saving for SI-template path (matches classic flow behavior)
		all_solutions = []
		all_hc_vars = []
		all_trivial_dicts = []
		all_trimmed_vars = []
		all_forward_subst_dicts = []
		all_reverse_subst_dicts = []
		all_final_varlists = []
		solution_time_indices = Int[]

		# Check if we should use parameter homotopy
		use_param_homotopy = opts.use_parameter_homotopy && opts.system_solver == SolverHC && n_points >= 3

		_record_phase!(phase_stats, "Equation construction + Solving") do
		if use_param_homotopy
			# ============================================================================
			# PARAMETER HOMOTOPY PATH
			# Solve all shooting points together using HC parameter homotopy
			# ============================================================================
			if opts.diagnostics
				println("\n=== Using Parameter Homotopy for $(n_points) shooting points ===")
			end

			# Extract data variables from DD.obs_lhs
			# These are the observable derivative variables (y1_0, y1_1, etc.)
			data_vars = extract_data_variables_from_DD(good_DD)

			if opts.diagnostics
				println("  Data variables (HC parameters): $(length(data_vars))")
				for (i, v) in enumerate(data_vars)
					println("    $i. $v")
				end
			end

			# Get the template equations (without substituting interpolated values)
			# We need the raw template with data_vars as symbolic variables
			template_equations = si_template.equations

			# Extract solve variables (everything in template that's NOT a data var)
			all_vars_in_template = OrderedSet{Any}()
			for eq in template_equations
				union!(all_vars_in_template, Symbolics.get_variables(eq))
			end

			# Separate into solve_vars and verify data_vars are present
			data_vars_set = Set(data_vars)
			initial_solve_vars = [v for v in all_vars_in_template if !(v in data_vars_set)]

			# Move _trfn_ variables from solve_vars to data_vars.
			# These represent sin(c*t), cos(c*t) etc. — known at any time point.
			trfn_info, real_solve_vars, trfn_only_eq_indices = classify_trfn_in_template(
				initial_solve_vars, data_vars_set, template_equations
			)

			# Remove equations that only involve data_vars + _trfn_ vars (no real unknowns)
			if !isempty(trfn_only_eq_indices)
				keep_mask = trues(length(template_equations))
				for idx in trfn_only_eq_indices
					keep_mask[idx] = false
				end
				template_equations = template_equations[keep_mask]
				if !opts.nooutput
					@info "[TRFN-SOLVE] Removed $(length(trfn_only_eq_indices)) trivial _trfn_ equations, $(length(template_equations)) remaining"
				end
			end

			# Add _trfn_ vars to data_vars (they'll be evaluated numerically at each shooting point)
			trfn_vars_ordered = collect(keys(trfn_info))
			extended_data_vars = vcat(data_vars, trfn_vars_ordered)
			solve_vars = real_solve_vars

			if opts.diagnostics || !isempty(trfn_info)
				if !opts.nooutput && !isempty(trfn_info)
					@info "[TRFN-SOLVE] Moved $(length(trfn_info)) _trfn_ vars to data; $(length(solve_vars)) real solve vars, $(length(template_equations)) equations"
				end
			end

			if opts.diagnostics
				println("  Solve variables (HC variables): $(length(solve_vars))")
				for (i, v) in enumerate(solve_vars)
					println("    $i. $v")
				end
				println("  Data variables (HC parameters): $(length(extended_data_vars))")
				println("  Template equations: $(length(template_equations))")
			end

			# Build parameter values for each shooting point
			param_values_list = Vector{Vector{Float64}}()
			for point_idx in point_indices
				t_point = t_vector[point_idx]
				# Evaluate observable derivative data vars
				obs_param_values = evaluate_data_vars_at_point(
					interpolants, data_vars, good_DD, PEP.measured_quantities, t_point
				)
				# Evaluate _trfn_ vars at this time point
				trfn_values = Float64[]
				for v in trfn_vars_ordered
					func_type, frequency, deriv_order = trfn_info[v]
					val = evaluate_trfn_template_variable(string(v), t_point)
					if isnothing(val)
						# Fallback: compute directly
						if func_type == :sin
							val = _eval_sin_derivative(frequency, t_point, deriv_order)
						elseif func_type == :cos
							val = _eval_cos_derivative(frequency, t_point, deriv_order)
						else
							val = _eval_exp_derivative(frequency, t_point, deriv_order)
						end
					end
					push!(trfn_values, val)
				end
				# Concatenate: observable data + _trfn_ data
				param_values = vcat(obs_param_values, trfn_values)
				push!(param_values_list, param_values)

				if opts.diagnostics
					println("  Point $point_idx (t=$t_point): $(length(param_values)) parameter values ($(length(obs_param_values)) obs + $(length(trfn_values)) trfn)")
				end
			end

			# Use extended data_vars for HC (includes both observable derivatives and _trfn_ vars)
			data_vars = extended_data_vars

			# Solve using parameter homotopy
			solver_options = Dict(
				:show_progress => opts.hc_show_progress,
				:real_tol => opts.hc_real_tol,
				:debug => opts.diagnostics,
			)

			solutions_by_point = solve_with_hc_parameterized(
				template_equations, solve_vars, data_vars, param_values_list;
				options = solver_options
			)

			# Process results from each shooting point
			for (i, (point_idx, point_solutions)) in enumerate(zip(point_indices, solutions_by_point))
				if opts.diagnostics
					println("\n  Point $point_idx: $(length(point_solutions)) real solutions")
				end

				# Optional: polish each raw solver solution using fast NLLS if requested
				if opts.polish_solver_solutions && !isempty(point_solutions)
					# Build the instantiated system for polishing (need concrete equations)
					target_k, varlist_k = construct_equation_system_from_si_template(
						PEP.model.system,
						PEP.measured_quantities,
						PEP.data_sample,
						good_deriv_level,
						good_udict,
						good_varlist,
						good_DD;
						interpolator = interpolator,
						time_index_set = [point_idx],
						precomputed_interpolants = interpolants,
						diagnostics = false,
						si_template = si_template,
					)

					polished_point = Vector{Vector{Float64}}()
					for sol in point_solutions
						start_pt = real.(sol)
						p_solutions, _, _, _ = solve_with_robust(target_k, varlist_k;
							start_point = start_pt, polish_only = true,
							options = Dict(:abstol => 1e-12, :reltol => 1e-12, :debug => false))
						if !isempty(p_solutions)
							push!(polished_point, p_solutions[1])
						else
							push!(polished_point, sol)
						end
					end
					point_solutions = polished_point
				end

				append!(all_solutions, point_solutions)
				for _ in 1:length(point_solutions)
					push!(solution_time_indices, point_idx)
				end
			end

			# Set final varlist from template solve_vars
			all_final_varlists = solve_vars
			all_hc_vars = solve_vars
			all_trimmed_vars = solve_vars

			if opts.diagnostics
				println("\n=== Parameter Homotopy complete: $(length(all_solutions)) total solutions ===")
			end

		else
			# ============================================================================
			# STANDARD PATH (solve independently at each shooting point)
			# ============================================================================
			for point_idx in point_indices
				if opts.diagnostics
					println("\n--- Solving at shooting point index: $point_idx (t=$(t_vector[point_idx])) ---")
				end

				# Instantiate the SI template at this time point
				target_k, varlist_k = construct_equation_system_from_si_template(
					PEP.model.system,
					PEP.measured_quantities,
					PEP.data_sample,
					good_deriv_level,
					good_udict,
					good_varlist,
					good_DD;
					interpolator = interpolator,
					time_index_set = [point_idx],
					precomputed_interpolants = interpolants,
					diagnostics = opts.diagnostics,
					si_template = si_template,
				)

				final_target = target_k
				final_varlist_point = varlist_k

				# Optional: save system for debugging (mirror classic flow behavior)
				if opts.save_system
					# Save the instantiated polynomial system for this shooting point
					save_filepath = "saved_systems/system_point_$(point_idx)_$(now()).jl"
					mkpath(dirname(save_filepath))
					save_poly_system(
						save_filepath,
						final_target,
						final_varlist_point,
						metadata = Dict(
							"timestamp" => string(now()),
							"num_equations" => length(final_target),
							"num_variables" => length(final_varlist_point),
							"shooting_point_index" => point_idx,
							"time" => t_vector[point_idx],
							"deriv_level" => good_deriv_level,
							"description" => "SI-template instantiated system",
						),
					)
					# Also save a simple text version
					txt_filepath = replace(save_filepath, ".jl" => ".txt")
					open(txt_filepath, "w") do f
						println(f, "# Polynomial System (SI template)")
						println(f, "# Shooting point index: ", point_idx, ", t=", t_vector[point_idx])
						println(f, "# Equations: ", length(final_target))
						println(f, "# Variables: ", length(final_varlist_point))
						println(f, "# Variables list: ", final_varlist_point)
						println(f, "\n# Equations:")
						for (i, eq) in enumerate(final_target)
							println(f, "Eq", i, ": ", eq)
						end
					end
					@info "Saved SI-template system to $save_filepath"
				end

				# Solve for this point
				solver_options = Dict(
					:debug_solver => opts.debug_solver,
					:debug_cas_diagnostics => opts.debug_cas_diagnostics,
					:debug_dimensional_analysis => opts.debug_dimensional_analysis,
				)
				solutions, hc_vars, trivial_dict, trimmed_vars = system_solver(final_target, final_varlist_point; options = solver_options)
				println("solutions: $solutions")
				println("hc_vars: $hc_vars")
				println("trivial_dict: $trivial_dict")
				println("trimmed_vars: $trimmed_vars")

				# Optional: polish each raw solver solution using fast NLLS if requested
				if opts.polish_solver_solutions && !isempty(solutions)
					polished_point = Vector{Vector{Float64}}()
					for sol in solutions
						start_pt = real.(sol)
						p_solutions, _, _, _ = solve_with_robust(final_target, final_varlist_point; start_point = start_pt, polish_only = true, options = Dict(:abstol => 1e-12, :reltol => 1e-12, :debug => opts.diagnostics))
						if !isempty(p_solutions)
							push!(polished_point, p_solutions[1])
						else
							push!(polished_point, sol)
						end
					end
					solutions = polished_point
				end

				append!(all_solutions, solutions)
				for _ in 1:length(solutions)
					push!(solution_time_indices, point_idx)
				end
				all_hc_vars = hc_vars
				push!(all_trivial_dicts, trivial_dict)
				push!(all_forward_subst_dicts, OrderedDict{Num, Any}())
				push!(all_reverse_subst_dicts, OrderedDict{Num, Num}())
				all_trimmed_vars = trimmed_vars
				all_final_varlists = final_varlist_point
			end
		end  # end if use_param_homotopy
		end  # _record_phase! "Equation construction + Solving"

		# Merge and finalize
		solutions = all_solutions
		hc_vars = all_hc_vars
		trivial_dict = isempty(all_trivial_dicts) ? Dict{Any, Any}() : merge(all_trivial_dicts...)
		trimmed_vars = all_trimmed_vars
		forward_subst_dict = isempty(all_forward_subst_dicts) ? [OrderedDict{Num, Any}()] : [all_forward_subst_dicts[1]]
		reverse_subst_dict = isempty(all_reverse_subst_dicts) ? [OrderedDict{Num, Num}()] : [all_reverse_subst_dicts[1]]
		final_varlist = all_final_varlists

		if !opts.nooutput
			println("Found $(length(solutions)) solutions total")
		end

		# Package as solution_data compatible with process_estimation_results
		solution_data = (
			solns = solutions,
			hcvarlist = hc_vars,
			trivial_dict = trivial_dict,
			trimmed_varlist = trimmed_vars,
			forward_subst_dict = forward_subst_dict,
			reverse_subst_dict = reverse_subst_dict,
			final_varlist = final_varlist,
			good_udict = good_udict,
			solution_time_indices = solution_time_indices,
		)

		# Reuse existing processing pipeline (without polish — polish gets its own phase below)
		opts_no_polish = merge_options(opts; polish_solutions = false)
		solved_res = _record_phase!(phase_stats, "Result processing") do
		process_estimation_results(
			PEP,
			solution_data,
			setup_data;
			opts = opts_no_polish,
		)
		end

		# PHASE: Polish solutions (separate phase for profiling visibility)
		if opts.polish_solutions
			solved_res = _record_phase!(phase_stats, "Polish (BFGS)") do
				ctx = _build_polish_context(PEP; opts = opts)
				if isempty(solved_res)
					# Pareto fallback: no algebraic solutions, try one random-start BFGS
					if !opts.nooutput
						println("No algebraic solutions found. Running random-start BFGS fallback...")
					end
					p_size = ctx.n_ic + ctx.n_param
					p0 = if !isnothing(ctx.lb) && !isnothing(ctx.ub)
						ctx.lb .+ rand(p_size) .* (ctx.ub .- ctx.lb)
					else
						randn(p_size)
					end
					result, _ = _polish_single_from_context(ctx, p0;
						optimizer = LBFGS(), maxiters = opts.polish_maxiters)
					[result]
				else
					_polish_batch_from_context(ctx, solved_res; opts = opts)
				end
			end
		end

		# Print phase profiling table if enabled
		if !isnothing(phase_stats)
			_print_phase_profile(phase_stats)
		end

		# The return signature is designed for compatibility with other workflows
		return (solved_res, good_udict, trivial_dict, setup_data.all_unidentifiable)
	end

	# DEBUG: Show the original ODE System
	if opts.debug_cas_diagnostics
		println("\nDEBUG: Original ODE System:")
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
	else
		t, eqns, states, params = unpack_ODE(PEP.model.system)
	end

	# PHASE 1: Precompute all derivatives once
	if !opts.nooutput
		println("Phase 1: Precomputing derivatives...")
	end
	precomputed = precompute_all_derivatives(PEP.model, PEP.measured_quantities)

	# PHASE 2: Analyze identifiability and create template
	if !opts.nooutput
		println("Phase 2: Analyzing identifiability...")
	end
	# Determine whether to use adaptive (RUR-based) identifiability. By default,
	# enable only for the RS-based solver and disable for homotopy to avoid Groebner.
	if isnothing(use_adaptive_id)
		use_adaptive_id = (system_solver == solve_with_rs_new)
	end

	deriv_levels, fixed_params, ident_vars, all_unidentifiable = analyze_identifiability(
		precomputed, PEP.model, PEP.measured_quantities, PEP.data_sample;
		use_adaptive = use_adaptive_id,
		debug_cas_diagnostics = opts.debug_cas_diagnostics,
	)

	# Ensure OrderedDict type for create_equation_template signature
	deriv_levels = OrderedDict(deriv_levels)

	template = create_equation_template(
		precomputed, deriv_levels, fixed_params, ident_vars, all_unidentifiable, PEP.model, PEP.measured_quantities;
		debug_cas_diagnostics = opts.debug_cas_diagnostics,
	)

	if !opts.nooutput
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
	if opts.shooting_points == 0
		# Special case: single shooting point near the midpoint (match old flow intent)
		mid = max(1, min(length(t_vector), round(Int, 0.499 * length(t_vector))))
		point_indices = [mid]
		n_points = 1
	else
		n_points = min(opts.shooting_points, length(t_vector))
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
	end

	if !opts.nooutput
		println("Phase 3: Solving at $n_points shooting points...")
	end

	for (i, idx) in enumerate(point_indices)
		time_point = t_vector[idx]

		if !opts.nooutput && opts.diagnostics
			println("  Solving at point $i/$n_points (t = $time_point)")
		end

		# Solve at this point
		solutions, trivial_dict = solve_at_shooting_point(
			template, precomputed, interpolants,
			time_point, idx, system_solver,
			measured_quantities = PEP.measured_quantities,
			debug_cas_diagnostics = opts.debug_cas_diagnostics,
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

	if !opts.nooutput
		println("Found $(length(all_solutions)) solutions total")
	end

	# Merge trivial dictionaries
	merged_trivial = OrderedDict()
	for td in all_trivial_dicts
		merge!(merged_trivial, td)
	end

	# PHASE 4: Polish if requested (shared context built once, reused for all solutions)
	if opts.polish_solutions && !isempty(all_solutions)
		ctx = _build_polish_context(PEP; opts = opts)
		all_solutions = _polish_batch_from_context(ctx, all_solutions; opts = opts)
	end

	# Return in the expected format
	# IMPORTANT: Return all_unidentifiable from the identifiability analysis, not just fixed_params keys
	return (all_solutions, fixed_params, merged_trivial, all_unidentifiable)
end

# Export the main function
