"""
SI.jl Integration Module for ODEParameterEstimation

This module provides functions to use StructuralIdentifiability.jl 
for equation system construction instead of iterative scanning.
"""


"""
	convert_to_si_ode(ode, measured_quantities::Vector{ModelingToolkit.Equation}, inputs::Vector{Num} = Vector{Num}())

Convert ModelingToolkit ODESystem to StructuralIdentifiability.jl ODE format.
Based on ParameterEstimation.jl's preprocess_ode function.

Returns:
- si_ode: StructuralIdentifiability.ODE object
- input_symbols: Original symbolic variables
- gens: Nemo polynomial ring generators
"""
function convert_to_si_ode(
	ode,  # Will be OrderedODESystem but can't reference type here
	measured_quantities::Vector{ModelingToolkit.Equation},
	inputs = [],  # Vector{Num}
)
	@info "Converting ODESystem to SI.jl format"

	model = ode.system

	# Filter out output equations from the ODE system
	diff_eqs = filter(eq -> !(ModelingToolkit.isoutput(eq.lhs)),
		ModelingToolkit.equations(model))

	# Get symbolic components
	y_functions = [each.lhs for each in measured_quantities]
	state_vars = ModelingToolkit.unknowns(model)
	params = ModelingToolkit.parameters(model)

	# Get time variable
	t = ModelingToolkit.get_iv(model)

	# Collect all parameters including from measured quantities
	params_from_measured = ModelingToolkit.parameters(
		ModelingToolkit.ODESystem(measured_quantities, t, name = :DataSeries),
	)
	params = union(params, params_from_measured)

	# Create input symbols array
	input_symbols = vcat(state_vars, y_functions, inputs, params)

	# Create generator strings (remove (t) from variables)
	generators = string.(input_symbols)
	generators = map(g -> replace(g, "(t)" => ""), generators)

	# Create Nemo polynomial ring
	R, gens_ = Nemo.polynomial_ring(Nemo.QQ, generators)

	# Create dictionaries for state equations and output equations
	state_eqn_dict = Dict{Nemo.QQMPolyRingElem,
		Union{Nemo.QQMPolyRingElem, Nemo.Generic.FracFieldElem{Nemo.QQMPolyRingElem}}}()

	out_eqn_dict = Dict{Nemo.QQMPolyRingElem,
		Union{Nemo.QQMPolyRingElem, Nemo.Generic.FracFieldElem{Nemo.QQMPolyRingElem}}}()

	# Convert state equations
	for i in eachindex(diff_eqs)
		lhs_nemo = Symbolics.substitute(state_vars[i], input_symbols .=> gens_)
		# Route through eval_at_nemo to robustly handle constants
		rhs_nemo = eval_at_nemo(Symbolics.value(diff_eqs[i].rhs), Dict(input_symbols .=> gens_))
		# Coerce plain numbers into the Nemo polynomial ring
		if rhs_nemo isa Number
			if rhs_nemo isa AbstractFloat
				try
					rhs_nemo = R(rhs_nemo)
				catch
					rhs_nemo = R(rationalize(rhs_nemo))
				end
			else
				rhs_nemo = R(rhs_nemo)
			end
		end
		state_eqn_dict[lhs_nemo] = rhs_nemo
	end

	# Convert output equations
	for i in 1:length(measured_quantities)
		lhs_nemo = Symbolics.substitute(y_functions[i], input_symbols .=> gens_)
		rhs_nemo = eval_at_nemo(measured_quantities[i].rhs, Dict(input_symbols .=> gens_))
		# Coerce plain numbers into the Nemo polynomial ring
		if rhs_nemo isa Number
			if rhs_nemo isa AbstractFloat
				try
					rhs_nemo = R(rhs_nemo)
				catch
					rhs_nemo = R(rationalize(rhs_nemo))
				end
			else
				rhs_nemo = R(rhs_nemo)
			end
		end
		out_eqn_dict[lhs_nemo] = rhs_nemo
	end

	# Convert inputs
	inputs_ = [Symbolics.substitute(each, input_symbols .=> gens_) for each in inputs]
	if isempty(inputs_)
		inputs_ = Vector{Nemo.QQMPolyRingElem}()
	end

	# Create SI.jl ODE object
	si_ode = ODE{Nemo.QQMPolyRingElem}(state_eqn_dict, out_eqn_dict, inputs_)

	return si_ode, input_symbols, gens_
end

"""
	algebraic_independence(Et::Vector{Nemo.QQMPolyRingElem},
						   indets::Vector{Nemo.QQMPolyRingElem},
						   vals)

Returns the indices of the equations in Et to be used for polynomial solving
and the variables that form a transcendence basis.

# Arguments
- `Et::Vector{Nemo.QQMPolyRingElem}`: The equations to be solved (must come from identifiability check).
- `indets::Vector{Nemo.QQMPolyRingElem}`: The indeterminates.
- `vals::Vector{Nemo.QQMPolyRingElem}`: The values of the indeterminates sampled by identifiability algorithm.
"""
function algebraic_independence(Et::Vector{Nemo.QQMPolyRingElem},
	indets::Vector{Nemo.QQMPolyRingElem},
	vals)
	pivots = Vector{Nemo.QQMPolyRingElem}()
	Jacobian = SIAN.jacobi_matrix(Et, indets, vals)
	U = Nemo.lu(Jacobian)[end]
	#find pivot columns in u
	for row_idx in 1:size(U, 1)
		row = U[row_idx, :]
		if !all(row .== 0)
			pivot_col = findfirst(row .!= 0)
			push!(pivots, indets[pivot_col])
		end
	end
	current_idx = 1
	output_rows = Jacobian[[current_idx], :]
	current_rank = 1
	output_ids = [1]
	for current_idx in 2:length(Et)
		current = vcat(output_rows, Jacobian[[current_idx], :])
		if Nemo.rank(current) > current_rank
			output_rows = current
			push!(output_ids, current_idx)
			current_rank += 1
		end
	end
	return output_ids, setdiff(indets, pivots)
end

"""
	eval_at_nemo(expr, subs_dict)

Evaluate a Symbolics expression in the Nemo polynomial ring.
Delegates to StructuralIdentifiability's eval_at_nemo function.
"""
function eval_at_nemo(expr, subs_dict)
	# Use StructuralIdentifiability's implementation
	return StructuralIdentifiability.eval_at_nemo(expr, subs_dict)
end

"""
	get_si_equation_system(ode, measured_quantities::Vector{ModelingToolkit.Equation}, data_sample::OrderedDict; DD=nothing, kwargs...)

Get polynomial equation system from StructuralIdentifiability.jl.
This replaces the iterative equation construction in ODEPE.

Returns:
- equations: Polynomial equations in Symbolics format (template)
- derivative_vars: Dictionary mapping derivative variables to their orders
- unidentifiable: Set of unidentifiable parameters
"""
function get_si_equation_system(
	ode,  # Will be OrderedODESystem
	measured_quantities::Vector{ModelingToolkit.Equation},
	data_sample::OrderedDict;
	DD = nothing,  # DerivativeData structure for mapping
	p = 0.99,
	p_mod = 0,
	infolevel = 0,
	kwargs...,
)
	@info "Getting equation system from StructuralIdentifiability.jl"

	# Convert to SI.jl format
	si_ode, symbol_map, gens = convert_to_si_ode(ode, measured_quantities)

	# Get parameters for identifiability analysis 
	# Use the parameters field directly instead of SIAN.get_parameters to avoid dependency issues
	params_to_assess = vcat(si_ode.parameters, si_ode.x_vars)

	# Create mapping from Nemo to MTK types
	nemo2mtk = Dict(gens .=> symbol_map)

	# Get polynomial system using SIAN
	@info "Getting polynomial system from SIAN"
	result = get_polynomial_system_from_sian(
		si_ode,
		params_to_assess;
		p = p,
		infolevel = infolevel,
	)

	# Extract the polynomial system and derivative info
	poly_system = result["polynomial_system"]
	y_derivative_dict = result["Y_eq"]

	# Also run identifiability check
	@info "Checking identifiability"
	id_result = StructuralIdentifiability.assess_identifiability(
		si_ode;
		funcs_to_check = params_to_assess,
		prob_threshold = p,
		loglevel = infolevel > 0 ? Logging.Info : Logging.Warn,
	)

	# Extract non-identifiable parameters
	unidentifiable_dict = Dict()
	for (param, status) in id_result
		if status == :nonidentifiable
			unidentifiable_dict[param] = status
		end
	end
	unidentifiable = Set(keys(unidentifiable_dict))

	@info "SI.jl found $(length(poly_system)) template equations"
	@info "Derivative variables: $(keys(y_derivative_dict))"
	@info "Derivative orders in y_derivative_dict: $(y_derivative_dict)"
	@info "Maximum derivative order needed: $(isempty(y_derivative_dict) ? 0 : maximum(values(y_derivative_dict)))"
	@info "Non-identifiable parameters: $unidentifiable"

	# Find identifiable combinations of unidentifiable parameters
	# The main ODE object must be passed, not the result dictionary.
	# This call finds combinations of all parameters, which is what we need.
	identifiable_funcs = find_identifiable_functions(si_ode)
	@info "Identifiable functions of unidentifiable parameters: $identifiable_funcs"

	# Build comprehensive variable mapping including derivatives
	# SIAN uses variables like y1_0, y1_1, y1_2 for derivatives
	# We need to map these to our DD structure when available

	# First, identify all variables in the polynomial system
	if !isempty(poly_system)
		R = parent(poly_system[1])
		all_vars = Nemo.gens(R)

		# Build extended mapping including derivative variables
		extended_map = Dict{Nemo.QQMPolyRingElem, Any}()

		# Copy existing mappings
		for (k, v) in nemo2mtk
			extended_map[k] = v
		end

		# Add derivative variable mappings
		for var in all_vars
			if !haskey(extended_map, var)
				var_name = string(var)
				parsed = parse_derivative_variable_name(var_name)

				if !isnothing(parsed)
					base_name, deriv_order = parsed

					# Map to DD structure if available
					if !isnothing(DD)
						# Find the corresponding observable index
						# SIAN uses y1, y2, etc. for observables
						# Extract the index from base_name (e.g., "y1" -> 1)
						m = match(r"y(\d+)", base_name)
						if !isnothing(m)
							obs_idx = parse(Int, m.captures[1])

							# Map to the appropriate DD variable
							if deriv_order == 0
								# Base observable
								if obs_idx <= length(DD.obs_lhs[1])
									deriv_var = DD.obs_lhs[1][obs_idx]
									extended_map[var] = deriv_var
									if infolevel > 0
										@debug "Mapped $var_name to DD observable: $deriv_var"
									end
								else
									@warn "Observable index $obs_idx out of bounds for DD structure"
								end
							else
								# Derivative of observable
								if deriv_order + 1 <= length(DD.obs_lhs) && obs_idx <= length(DD.obs_lhs[deriv_order+1])
									deriv_var = DD.obs_lhs[deriv_order+1][obs_idx]
									extended_map[var] = deriv_var
									if infolevel > 0
										@debug "Mapped $var_name to DD derivative: $deriv_var"
									end
								else
									# Create a symbolic variable as fallback
									deriv_var = Symbolics.variable(Symbol(var_name))
									extended_map[var] = deriv_var
									if infolevel > 0
										@warn "Cannot map $var_name to DD (order=$deriv_order), using symbolic: $deriv_var"
									end
								end
							end
						else
							# Not a y-variable, might be a state or parameter derivative
							# Create a symbolic variable
							deriv_var = Symbolics.variable(Symbol(var_name))
							extended_map[var] = deriv_var
							if infolevel > 0
								@debug "Created symbolic for non-observable derivative $var_name: $deriv_var"
							end
						end
					else
						# No DD structure available, create symbolic variable
						deriv_var = Symbolics.variable(Symbol(var_name))
						extended_map[var] = deriv_var
						if infolevel > 0
							@info "No DD structure, created symbolic for $var_name: $deriv_var"
						end
					end
				else
					# Non-derivative variable not in original map
					# Create a symbolic variable for it
					sym_var = Symbolics.variable(Symbol(var_name))
					extended_map[var] = sym_var
					if infolevel > 0
						@debug "Mapped unknown variable $var_name to symbolic $sym_var"
					end
				end
			end
		end

		nemo2mtk = extended_map
	end

	# Convert polynomial system to Symbolics format
	template_equations = []

	if infolevel > 0
		@info "Converting $(length(poly_system)) polynomials from Nemo to Symbolics"
	end

	for poly in poly_system
		# Convert the polynomial to Symbolics
		poly_sym = nemo_to_symbolics(poly, nemo2mtk)

		if infolevel > 0
			@debug "Converted polynomial: $(typeof(poly)) -> $(typeof(poly_sym))"
		end

		push!(template_equations, poly_sym)
	end

	# Debug: Final check
	if infolevel > 0 && !isempty(template_equations)
		@debug "Final template_equations[1] type: $(typeof(template_equations[1]))"
	end

	# Return identifiable_funcs as well
	return template_equations, y_derivative_dict, unidentifiable, identifiable_funcs
end

"""
	get_polynomial_system_from_sian(si_ode, params_to_assess; p = 0.99, infolevel = 0)

Get polynomial system using SIAN functions, adapted from PE.jl's implementation.
This now properly builds the system Et through the iterative rank-checking process.
"""
function get_polynomial_system_from_sian(si_ode, params_to_assess; p = 0.99, infolevel = 0)
	# Get equations using SIAN
	eqs, Q, x_eqs, y_eqs, x_vars, y_vars, u_vars, mu, all_indets, gens_Rjet = SIAN.get_equations(si_ode)

	non_jet_ring = si_ode.poly_ring
	Rjet = gens_Rjet[1].parent

	n = length(x_vars)
	m = length(y_vars)
	u = length(u_vars)
	s = length(mu) + n

	# Get X and Y equations
	X, X_eq = SIAN.get_x_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
	Y, Y_eq = SIAN.get_y_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)

	# Extract parameters and state variables
	not_int_cond_params = gens_Rjet[(end-length(si_ode.parameters)+1):end]
	all_params = vcat(not_int_cond_params, gens_Rjet[1:n])

	x_variables = gens_Rjet[1:n]
	for i in 1:(s+1)
		x_variables = vcat(x_variables,
			gens_Rjet[(i*(n+m+u)+1):(i*(n+m+u)+n)])
	end

	# Compute degree bound
	d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(Q * eq[2])[1])
							  for eq in eqs], Nemo.total_degree(Q))))

	# Sample point for Jacobian evaluations
	D1 = floor(BigInt,
		(length(params_to_assess) + 1) * 2 * d0 * s * (n + 1) * (1 + 2 * d0 * s) /
		(1 - p))

	# Convert empty array to proper type for u_variables
	u_empty = Vector{Nemo.QQMPolyRingElem}()
	sample = SIAN.sample_point(D1, x_vars, y_vars, u_empty, all_params, X_eq, Y_eq, Q)
	all_subs = sample[4]
	u_hat = sample[2]
	y_hat = sample[1]

	# Build the polynomial system Et through iterative process
	Et = Array{Nemo.QQMPolyRingElem}(undef, 0)
	x_theta_vars = all_params
	beta = [0 for i in 1:m]
	prolongation_possible = [1 for i in 1:m]

	all_x_theta_vars_subs = SIAN.insert_zeros_to_vals(all_subs[1], all_subs[2])
	eqs_i_old = Array{Nemo.QQMPolyRingElem}(undef, 0)
	evl_old = Array{Nemo.QQMPolyRingElem}(undef, 0)

	# Iterative rank-based construction
	while sum(prolongation_possible) > 0
		for i in 1:m
			if prolongation_possible[i] == 1
				eqs_i = vcat(Et, Y[i][beta[i]+1])
				evl = [Nemo.evaluate(eq, vcat(u_hat[1], y_hat[1]),
					vcat(u_hat[2], y_hat[2]))
					   for eq in eqs_i if !(eq in eqs_i_old)]
				evl_old = vcat(evl_old, evl)
				JacX = SIAN.jacobi_matrix(evl_old, x_theta_vars, all_x_theta_vars_subs)
				eqs_i_old = eqs_i

				if LinearAlgebra.rank(JacX) == length(eqs_i)
					Et = vcat(Et, Y[i][beta[i]+1])
					beta[i] = beta[i] + 1

					# Add necessary X-equations
					polys_to_process = vcat(Et, [Y[k][beta[k]+1] for k in 1:m if beta[k] < length(Y[k])])
					while length(polys_to_process) != 0
						new_to_process = Array{Nemo.QQMPolyRingElem}(undef, 0)
						vrs = Set{Nemo.QQMPolyRingElem}()
						for poly in polys_to_process
							vrs = union(vrs,
								[v for v in Nemo.vars(poly) if v in x_variables])
						end
						vars_to_add = Set{Nemo.QQMPolyRingElem}(v
																for v in vrs
																if !(v in x_theta_vars))
						for v in vars_to_add
							x_theta_vars = vcat(x_theta_vars, v)
							ord_var = SIAN.get_order_var2(v, all_indets, n + m + u, s)
							var_idx = Nemo.var_index(ord_var[1])
							poly = X[var_idx][ord_var[2]]
							Et = vcat(Et, poly)
							new_to_process = vcat(new_to_process, poly)
						end
						polys_to_process = new_to_process
					end
				else
					prolongation_possible[i] = 0
				end
			end
		end
	end

	# Add remaining Y equations that don't introduce new variables
	for i in 1:m
		for j in (beta[i]+1):length(Y[i])
			to_add = true
			for v in SIAN.get_vars(Y[i][j], x_vars, all_indets, n + m + u, s)
				if !(v in x_theta_vars)
					to_add = false
				end
			end
			if to_add
				beta[i] = beta[i] + 1
				Et = vcat(Et, Y[i][j])
			end
		end
	end

	@info "Built polynomial system with $(length(Et)) equations"

	# Assess local identifiability to find transcendence basis
	theta_l = Array{Nemo.QQMPolyRingElem}(undef, 0)
	params_to_assess_ = [SIAN.add_to_var(param, Rjet, 0) for param in params_to_assess]
	Et_eval_base = [Nemo.evaluate(e, vcat(u_hat[1], y_hat[1]),
		vcat(u_hat[2], y_hat[2]))
					for e in Et]
	for param_0 in params_to_assess_
		other_params = [v for v in x_theta_vars if v != param_0]
		Et_subs = [Nemo.evaluate(e, [param_0],
			[Nemo.evaluate(param_0, all_x_theta_vars_subs)])
				   for e in Et_eval_base]
		JacX = SIAN.jacobi_matrix(Et_subs, other_params, all_x_theta_vars_subs)
		if LinearAlgebra.rank(JacX) != length(Et)
			theta_l = vcat(theta_l, param_0)
		end
	end
	x_theta_vars_reorder = vcat(theta_l,
		reverse([x for x in x_theta_vars if !(x in theta_l)]))
	Et_ids, alg_indep = algebraic_independence(Et_eval_base, x_theta_vars_reorder,
		all_x_theta_vars_subs)

	# Reduce the system using the computed indices
	reduced_Et = Et[Et_ids]

	@info "Reduced polynomial system to $(length(reduced_Et)) equations"

	# Build the derivative mapping dictionary
	y_derivative_dict = Dict()
	for each in Y_eq
		name, order = SIAN.get_order_var(each[1], non_jet_ring)
		y_derivative_dict[each[1]] = order
	end

	# Return result with the full polynomial system Et
	return Dict(
		"polynomial_system" => reduced_Et,  # Return the REDUCED system
		"Y_eq" => y_derivative_dict,  # Maps derivative variables to orders
		"X_eq" => X_eq,
		"Y" => Y,  # Keep the full Y structure for reference
		"X" => X,  # Keep X structure as well
		"x_theta_vars" => x_theta_vars,  # Variables in the system
		"beta" => beta,  # Derivative orders used
		"non_jet_ring" => non_jet_ring,
	)
end

"""
	convert_si_polys_to_symbolics(polys::Vector, symbol_map::Vector, gens::Vector, transcendence_subs::Dict)

Convert Nemo polynomial system back to Symbolics expressions that ODEPE expects.
"""
function convert_si_polys_to_symbolics(
	polys::Vector,
	symbol_map::Vector,
	gens::Vector,
	transcendence_subs::Dict,
)
	@info "Converting SI.jl polynomials to Symbolics format"

	# Create mapping from Nemo generators to Symbolics variables
	nemo_to_sym = Dict(gens .=> symbol_map)

	symbolic_equations = []

	for poly in polys
		# Apply transcendence substitutions if provided
		if !isempty(transcendence_subs)
			poly = Symbolics.substitute(poly, transcendence_subs)
		end

		# Convert Nemo polynomial to Symbolics
		sym_eq = nemo_to_symbolics(poly, nemo_to_sym)
		push!(symbolic_equations, sym_eq)
	end

	@info "Converted $(length(symbolic_equations)) equations to Symbolics format"
	return symbolic_equations
end

"""
	parse_derivative_variable_name(var_name::String)

Parse a SIAN derivative variable name like "y1_2" to extract base variable and derivative order.
Returns (base_name, derivative_order) or nothing if parsing fails.
"""
function parse_derivative_variable_name(var_name::String)
	# Match pattern like "y1_2" where y1 is the base and 2 is the derivative order
	m = match(r"^([a-zA-Z]+\d+)_(\d+)$", var_name)
	if isnothing(m)
		return nothing
	end
	base_name = m.captures[1]
	derivative_order = parse(Int, m.captures[2])
	return (base_name, derivative_order)
end

"""
	nemo_to_symbolics(nemo_expr, var_map::Dict)

Convert a Nemo expression to a Symbolics expression using proper term-by-term reconstruction.
"""
function nemo_to_symbolics(nemo_expr, var_map::Dict)
	# Handle constants
	if nemo_expr isa Number
		return nemo_expr
	end

	# Handle Nemo QQ field elements (rationals)
	if nemo_expr isa Nemo.QQFieldElem
		num = BigInt(Nemo.numerator(nemo_expr))
		den = BigInt(Nemo.denominator(nemo_expr))
		return Rational(num, den)
	end

	# Handle fraction field elements
	if nemo_expr isa Nemo.Generic.FracFieldElem
		numer = nemo_to_symbolics(Nemo.numerator(nemo_expr), var_map)
		denom = nemo_to_symbolics(Nemo.denominator(nemo_expr), var_map)
		return numer / denom
	end

	# Handle polynomial variables directly
	if haskey(var_map, nemo_expr)
		return var_map[nemo_expr]
	end

	# For multivariate polynomials - use proper Nemo API
	if nemo_expr isa Nemo.QQMPolyRingElem
		# Handle zero polynomial
		if iszero(nemo_expr)
			return 0
		end

		# Get the parent ring and variables
		R = parent(nemo_expr)
		vars = Nemo.gens(R)

		# Build Symbolics expression by iterating over terms
		symbolic_terms = []

		# Use the correct Nemo API: iterate through indices
		for i in 1:length(nemo_expr)
			# Get coefficient for this term
			c = Nemo.coeff(nemo_expr, i)

			# Convert coefficient to Julia number
			coeff_val = if c isa Nemo.QQFieldElem
				num = BigInt(Nemo.numerator(c))
				den = BigInt(Nemo.denominator(c))
				Rational(num, den)
			elseif c isa Nemo.ZZRingElem
				BigInt(c)
			elseif c isa Integer
				c
			else
				@error "Unknown coefficient type" typeof(c) c
				1  # Default to 1
			end

			# Get exponent vector for this term
			exp_vec = Nemo.exponent_vector(nemo_expr, i)

			# Build the monomial
			monomial_factors = []
			for (j, var) in enumerate(vars)
				if exp_vec[j] > 0
					# Get the Symbolics variable from the map
					sym_var = get(var_map, var, nothing)
					if isnothing(sym_var)
						# Try to create mapping on the fly for derivative variables
						var_name = string(var)
						parsed = parse_derivative_variable_name(var_name)
						# If not found, create a new symbolic variable on-the-fly.
						# This is crucial for handling identifiable functions, where the
						# parameters might not be in the initial `var_map`.
						@warn "Variable $var not found in map, creating it symbolically."
						sym_var = Symbolics.variable(Symbol(var_name))
						var_map[var] = sym_var # Cache for future use
					end

					if exp_vec[j] == 1
						push!(monomial_factors, sym_var)
					else
						push!(monomial_factors, sym_var^exp_vec[j])
					end
				end
			end

			# Construct the term
			if isempty(monomial_factors)
				# Constant term
				push!(symbolic_terms, coeff_val)
			else
				# Term with variables
				term = coeff_val
				for factor in monomial_factors
					term = term * factor
				end
				push!(symbolic_terms, term)
			end
		end

		# Sum all terms
		if isempty(symbolic_terms)
			return 0
		else
			result = symbolic_terms[1]
			for i in 2:length(symbolic_terms)
				result = result + symbolic_terms[i]
			end
			return result
		end
	end

	# Unknown type
	@error "Cannot convert Nemo expression of type $(typeof(nemo_expr))"
	return nemo_expr
end

# Export main functions
export get_si_equation_system, convert_to_si_ode
