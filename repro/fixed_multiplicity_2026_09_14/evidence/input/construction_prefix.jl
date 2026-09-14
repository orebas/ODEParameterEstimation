function inspect_sneyd_multiplicity_input(si_ode, params_to_assess; p = 0.99, infolevel = 0, compute_multiplicity = true,
	pre_fixed_params::OrderedDict = OrderedDict())
	sian_timing = OrderedDict{Symbol, Float64}()
	algebraic_multiplicity_timing = OrderedDict{Symbol, Any}()
	# Get equations using SIAN
	_t_get_equations = @elapsed begin
		eqs, Q, x_eqs, y_eqs, x_vars, y_vars, u_vars, mu, all_indets, gens_Rjet = SIAN.get_equations(si_ode)
	end
	sian_timing[:get_equations] = _t_get_equations

	non_jet_ring = si_ode.poly_ring
	Rjet = gens_Rjet[1].parent

	n = length(x_vars)
	m = length(y_vars)
	u = length(u_vars)
	s = length(mu) + n

	# Get X and Y equations
	_t_get_x_y_eq_start = time()
	X, X_eq = SIAN.get_x_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
	Y, Y_eq = SIAN.get_y_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
	sian_timing[:get_x_y_eq] = time() - _t_get_x_y_eq_start

	# Extract parameters and state variables
	_t_variable_setup_start = time()
	not_int_cond_params = gens_Rjet[(end-length(si_ode.parameters)+1):end]
	all_params = vcat(not_int_cond_params, gens_Rjet[1:n])

	x_variables = gens_Rjet[1:n]
	for i in 1:(s+1)
		x_variables = vcat(x_variables,
			gens_Rjet[(i*(n+m+u)+1):(i*(n+m+u)+n)])
	end
	sian_timing[:variable_setup] = time() - _t_variable_setup_start

	# Compute degree bound
	_t_degree_bound_start = time()
	d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(Q * eq[2])[1])
							  for eq in eqs], Nemo.total_degree(Q))))

	# Sample point for Jacobian evaluations
	D1 = floor(BigInt,
		(length(params_to_assess) + 1) * 2 * d0 * s * (n + 1) * (1 + 2 * d0 * s) /
		(1 - p))
	sian_timing[:degree_bound] = time() - _t_degree_bound_start

	# Convert empty array to proper type for u_variables
	u_empty = Vector{Nemo.QQMPolyRingElem}()
	_t_sample_point_start = time()
	sample = SIAN.sample_point(D1, x_vars, y_vars, u_empty, all_params, X_eq, Y_eq, Q)
	sian_timing[:sample_point] = time() - _t_sample_point_start
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
	_t_rank_construction_start = time()
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
	sian_timing[:rank_construction] = time() - _t_rank_construction_start

	@info "Built polynomial system with $(length(Et)) equations"
	if infolevel > 1
		@info "[SI-TEMPLATE] Raw polynomial variables collected during SIAN construction" variables = x_theta_vars
		for (idx, eq) in enumerate(Et)
			vars_in_eq = Nemo.vars(eq)
			@info "[SI-TEMPLATE] Raw polynomial equation" index = idx ring_variable_count = length(vars_in_eq) ring_variables = vars_in_eq
		end
	end

	# Classify coordinates using rank loss, even when Et has dependent rows.
	params_to_assess_ = [SIAN.add_to_var(param, Rjet, 0) for param in params_to_assess]
	_t_evaluate_Et_base_start = time()
	Et_eval_base = [Nemo.evaluate(e, vcat(u_hat[1], y_hat[1]),
		vcat(u_hat[2], y_hat[2]))
					for e in Et]
	sian_timing[:evaluate_Et_base] = time() - _t_evaluate_Et_base_start
	_t_local_identifiability_start = time()
	local_info = _sian_local_coordinates(Et_eval_base, x_theta_vars, params_to_assess_, all_x_theta_vars_subs)
	theta_l = local_info.locally_identifiable
	sian_timing[:local_identifiability_jacobians] = time() - _t_local_identifiability_start
	x_theta_vars_reorder = vcat(theta_l,
		reverse([x for x in x_theta_vars if !(x in theta_l)]))

	return _prepare_sian_multiplicity_system(si_ode, Et, Q, X_eq, Y_eq, all_params, sample, D1; pre_fixed_params)
end
