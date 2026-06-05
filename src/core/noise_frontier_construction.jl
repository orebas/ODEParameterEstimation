"""
Noise-first polynomial-system construction probes.

This module builds square single-point or multipoint systems from the full SI
template equation pool, then selects among rank-complete bases by:

1. lowest maximum observed-derivative order;
2. lowest actual mixed volume among candidate bases at that order;
3. support/conditioning deterministic tie-breaks.

The standard solver path uses this construction when
`system_construction_policy = :noise_frontier`; `:legacy` keeps the older
SI-template and multipoint builders.
"""

const NoiseEqMeta = @NamedTuple{point::Int, source_index::Int, max_observed_order::Int, support_score::Float64}

struct NoiseFrontierCandidate
	n_points::Int
	strategy::Symbol
	max_observed_order::Int
	selected_equation_indices::Vector{Int}
	selected_source_indices::Vector{Int}
	dropped_equation_indices::Vector{Int}
	equations::Vector{Any}
	solve_vars::Vector{Any}
	data_vars::Vector{Any}
	eq_metadata::Vector{NoiseEqMeta}
	rank::Int
	target_rank::Int
	is_square::Bool
	rank_complete::Bool
	support_score::Float64
	solve_var_count::Int
	data_var_count::Int
	condition_proxy::Float64
	mixed_volume::Union{Nothing, Int}
end

struct NoiseFrontierResult
	n_points::Int
	minimal_max_observed_order::Union{Nothing, Int}
	selected::Union{Nothing, NoiseFrontierCandidate}
	candidates::Vector{NoiseFrontierCandidate}
	frontier::Vector{NamedTuple}
	full_equation_count::Int
	combined_equation_count::Int
	target_rank::Int
end

function _noise_strip_point_suffix(name::AbstractString)
	return replace(String(name), r"_pt\d+$" => "")
end

function _noise_observable_bases(measured_quantities)
	bases = Set{String}()
	for mq in measured_quantities
		name = replace(string(mq.lhs), "(t)" => "")
		startswith(name, "_obs_trfn_") || push!(bases, name)
	end
	return bases
end

function _noise_dd_order_maps(template_DD)
	by_obj = Dict{Any, Int}()
	by_string = Dict{String, Int}()
	isnothing(template_DD) && return by_obj, by_string
	for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
		order = level_idx - 1
		for v in level_vars
			by_obj[v] = order
			by_string[string(v)] = order
		end
	end
	return by_obj, by_string
end

function _noise_var_role(v, pep::ParameterEstimationProblem, dd_order_by_obj, dd_order_by_string, obs_bases)
	vname = string(v)
	clean = _noise_strip_point_suffix(vname)
	contains(clean, "_trfn_") && return (role = :transcendental, order = 0, base = clean)
	if haskey(dd_order_by_obj, v)
		return (role = :data, order = dd_order_by_obj[v], base = clean)
	elseif haskey(dd_order_by_string, clean)
		return (role = :data, order = dd_order_by_string[clean], base = clean)
	end
	parsed = parse_derivative_variable_name(clean)
	if !isnothing(parsed)
		base, order = parsed
		if base in obs_bases
			return (role = :data, order = order, base = base)
		end
		param_bases = Set(replace(string(p), "(t)" => "") for p in keys(pep.p_true))
		state_bases = Set(replace(string(s), "(t)" => "") for s in keys(pep.ic))
		if base in param_bases && order == 0
			return (role = :parameter, order = 0, base = base)
		elseif base in state_bases
			return (role = order == 0 ? :state_ic : :state_derivative, order = order, base = base)
		end
	end
	return (role = :unknown, order = 0, base = clean)
end

function _noise_equation_feature(eq, pep::ParameterEstimationProblem, dd_order_by_obj, dd_order_by_string, obs_bases)
	vars = collect(Symbolics.get_variables(eq))
	data_orders = Int[]
	for v in vars
		role = _noise_var_role(v, pep, dd_order_by_obj, dd_order_by_string, obs_bases)
		role.role == :data && push!(data_orders, role.order)
	end
	max_obs = isempty(data_orders) ? -1 : maximum(data_orders)
	# Cheap structural proxy. Actual MV is used for candidate selection whenever requested.
	support_score = Float64(length(vars)) + 1.0e-3 * length(string(eq))
	return max_obs, support_score
end

function _noise_template_equations(si_template)
	if hasproperty(si_template, :all_equations)
		return collect(si_template.all_equations)
	elseif hasproperty(si_template, :rank_trimming_metadata) &&
		   hasproperty(si_template.rank_trimming_metadata, :full_equations)
		return collect(si_template.rank_trimming_metadata.full_equations)
	end
	return collect(si_template.equations)
end

function _noise_template_clean_name_map(symb_template_vars, inst_var_name_set::Set{String}, template_DD, measured_quantities)
	symb_to_clean = Dict{Any, String}()
	for v in symb_template_vars
		sname = string(v)
		if sname in inst_var_name_set
			symb_to_clean[v] = sname
			continue
		end
		found = false
		if !isnothing(template_DD)
			for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
				for (obs_idx, lhs_v) in enumerate(level_vars)
					if lhs_v === v || isequal(lhs_v, v)
						deriv_order = level_idx - 1
						obs_name = replace(string(measured_quantities[obs_idx].lhs), r"\(.*\)$" => "")
						symb_to_clean[v] = "$(obs_name)_$(deriv_order)"
						found = true
						break
					end
				end
				found && break
			end
		end
		if !found
			clean = replace(sname, r"\(.*?\)" => "")
			clean = replace(clean, r"[^a-zA-Z0-9_]" => "_")
			symb_to_clean[v] = clean
		end
	end
	return symb_to_clean
end

function _noise_rename_symbolic_equations(symb_eqs, symb_vars, symb_to_clean, param_set::Set{String}, point::Int)
	rd = Dict{Any, Any}()
	for v in symb_vars
		sname = string(v)
		clean = get(symb_to_clean, v, sname)
		if point == 1
			if sname != clean && !(clean in param_set)
				rd[v] = Symbolics.variable(Symbol(clean))
			end
		else
			clean in param_set && continue
			rd[v] = Symbolics.variable(Symbol(clean * "_pt$(point)"))
		end
	end
	return isempty(rd) ? collect(symb_eqs) : [Symbolics.substitute(eq, rd) for eq in symb_eqs]
end

function _noise_probe_indices(data_sample, n_points::Int)
	t_vec = data_sample["t"]
	n_t = length(t_vec)
	fracs = n_points == 1 ? [0.5] :
		n_points == 2 ? [0.25, 0.75] :
		collect(range(0.15, 0.85; length = n_points))
	return [max(2, min(n_t - 1, round(Int, n_t * f))) for f in fracs]
end

function _noise_build_pool(
	pep::ParameterEstimationProblem,
	setup::NamedTuple,
	si_template;
	n_points::Int,
	diagnostics::Bool = false,
	probe_indices::Union{Nothing, Vector{Int}} = nothing,
)
	n_points >= 1 || throw(ArgumentError("n_points must be positive"))
	interpolants = get(setup, :interpolants, nothing)
	isnothing(interpolants) && throw(ArgumentError("setup.interpolants is required for noise-frontier construction probes"))
	template_DD = hasproperty(si_template, :template_DD) ? si_template.template_DD : setup.good_DD
	full_symb_eqs = _noise_template_equations(si_template)
	full_vars_set = OrderedCollections.OrderedSet{Any}()
	for eq in full_symb_eqs
		union!(full_vars_set, Symbolics.get_variables(eq))
	end
	full_symb_vars = collect(full_vars_set)

	probes = isnothing(probe_indices) ? _noise_probe_indices(pep.data_sample, n_points) : probe_indices
	length(probes) == n_points || throw(ArgumentError("probe_indices length must match n_points"))

	combined_inst_eqs = Any[]
	combined_symb_eqs = Any[]
	source_indices = Int[]
	points = Int[]

	first_inst = instantiate_si_template_equations(
		full_symb_eqs,
		pep.measured_quantities,
		pep.data_sample,
		si_template.deriv_dict,
		template_DD;
		interpolants = interpolants,
		time_index = probes[1],
		diagnostics = false,
		prune_overdetermined = false,
	)
	roles = _classify_polynomial_variables(string.(first_inst.vars), pep)
	param_set = Set(vn for (vn, role) in roles if role == :parameter)
	symb_to_clean = _noise_template_clean_name_map(full_symb_vars, Set(string.(first_inst.vars)), template_DD, pep.measured_quantities)

	for pt in 1:n_points
		inst = pt == 1 ? first_inst : instantiate_si_template_equations(
			full_symb_eqs,
			pep.measured_quantities,
			pep.data_sample,
			si_template.deriv_dict,
			template_DD;
			interpolants = interpolants,
			time_index = probes[pt],
			diagnostics = false,
			prune_overdetermined = false,
		)
		inst_renamed, _ = _rename_per_point_variables(inst.equations, inst.vars, param_set, pt)
		symb_renamed = _noise_rename_symbolic_equations(full_symb_eqs, full_symb_vars, symb_to_clean, param_set, pt)
		n_inst = length(inst_renamed)
		n_symb = length(symb_renamed)
		if n_inst != n_symb && diagnostics
			@warn "[NOISE-FRONTIER] Template/instantiated equation-count mismatch; using prefix mapping for nontrivial equations" point = pt instantiated = n_inst symbolic = n_symb
		end
		n_keep = min(n_inst, n_symb)
		append!(combined_inst_eqs, inst_renamed[1:n_keep])
		append!(combined_symb_eqs, symb_renamed[1:n_keep])
		append!(source_indices, collect(1:n_keep))
		append!(points, fill(pt, n_keep))
	end

	dd_order_by_obj, dd_order_by_string = _noise_dd_order_maps(template_DD)
	obs_bases = _noise_observable_bases(pep.measured_quantities)

	combined_inst_vars_set = OrderedCollections.OrderedSet{Any}()
	for eq in combined_inst_eqs
		union!(combined_inst_vars_set, Symbolics.get_variables(eq))
	end
	combined_inst_vars_all = collect(combined_inst_vars_set)
	rank_vars = Any[]
	data_subst = Dict{Any, Float64}()
	for (i, v) in enumerate(combined_inst_vars_all)
		role = _noise_var_role(v, pep, dd_order_by_obj, dd_order_by_string, obs_bases)
		if role.role in (:data, :transcendental)
			data_subst[v] = 1.0 + 0.125 * i
		else
			push!(rank_vars, v)
		end
	end
	rank_inst_eqs = isempty(data_subst) ? combined_inst_eqs :
		[Symbolics.substitute(eq, data_subst) for eq in combined_inst_eqs]

	metadata = NoiseEqMeta[]
	for (i, eq) in enumerate(combined_symb_eqs)
		max_obs, support_score = _noise_equation_feature(eq, pep, dd_order_by_obj, dd_order_by_string, obs_bases)
		push!(metadata, (point = points[i], source_index = source_indices[i], max_observed_order = max_obs, support_score = support_score))
	end

	return (
		symbolic_equations = combined_symb_eqs,
		instantiated_equations = rank_inst_eqs,
		instantiated_vars = rank_vars,
		metadata = metadata,
		template_DD = template_DD,
		full_equation_count = length(full_symb_eqs),
		probe_indices = probes,
	)
end

function _noise_rank_matrix(equations, variables; rank_atol::Float64 = 1e-8, n_rank_probes::Int = 3)
	n_var = length(variables)
	n_eq = length(equations)
	if n_var == 0 || n_eq == 0
		return zeros(Float64, n_eq, n_var), 0
	end
	f = _compile_system_function(equations, variables)
	best_J = zeros(Float64, n_eq, n_var)
	best_rank = -1
	rng = MersenneTwister(0x9f4d0329)
	for _ in 1:max(1, n_rank_probes)
		x = randn(rng, n_var) .* 3.0
		J = try
			ForwardDiff.jacobian(f, x)
		catch
			zeros(Float64, n_eq, n_var)
		end
		all(isfinite, J) || continue
		r = rank(J; atol = rank_atol)
		if r > best_rank
			best_rank = r
			best_J = Float64.(J)
		end
	end
	return best_J, max(best_rank, 0)
end

function _noise_rank_of_rows(J, rows; rank_atol::Float64 = 1e-8)
	isempty(rows) && return 0
	return rank(J[collect(rows), :]; atol = rank_atol)
end

function _noise_greedy_basis(J, ordered_indices, target_rank::Int; rank_atol::Float64 = 1e-8)
	selected = Int[]
	current = zeros(Float64, 0, size(J, 2))
	current_rank = 0
	for idx in ordered_indices
		trial = vcat(current, J[idx:idx, :])
		r = rank(trial; atol = rank_atol)
		if r > current_rank
			push!(selected, idx)
			current = trial
			current_rank = r
		end
		current_rank == target_rank && break
	end
	return current_rank == target_rank && length(selected) == target_rank ? selected : Int[]
end

function _noise_dynamic_basis(J, allowed, metadata, symbolic_equations, pep, dd_order_by_obj, dd_order_by_string, obs_bases,
		target_rank::Int; tie_policy::Symbol, rank_atol::Float64 = 1e-8)
	selected = Int[]
	introduced = Set{String}()
	remaining = Set(allowed)
	current = zeros(Float64, 0, size(J, 2))
	current_rank = 0
	while current_rank < target_rank
		best = nothing
		best_key = nothing
		for idx in sort(collect(remaining))
			trial = vcat(current, J[idx:idx, :])
			r = rank(trial; atol = rank_atol)
			r > current_rank || continue
			var_tokens = Set(string.(Symbolics.get_variables(symbolic_equations[idx])))
			new_tokens = setdiff(var_tokens, introduced)
			new_data_orders = Int[]
			for v in Symbolics.get_variables(symbolic_equations[idx])
				string(v) in new_tokens || continue
				role = _noise_var_role(v, pep, dd_order_by_obj, dd_order_by_string, obs_bases)
				role.role == :data && push!(new_data_orders, role.order)
			end
			max_new_data = isempty(new_data_orders) ? 999 : maximum(new_data_orders)
			marginal_count = length(new_tokens)
			key = if tie_policy == :data_order
				(max_new_data, marginal_count, metadata[idx].support_score, idx)
			else
				(marginal_count, metadata[idx].support_score, max_new_data, idx)
			end
			if isnothing(best_key) || key < best_key
				best = idx
				best_key = key
			end
		end
		isnothing(best) && break
		push!(selected, best)
		union!(introduced, Set(string.(Symbolics.get_variables(symbolic_equations[best]))))
		current = vcat(current, J[best:best, :])
		current_rank = rank(current; atol = rank_atol)
		delete!(remaining, best)
	end
	return current_rank == target_rank && length(selected) == target_rank ? selected : Int[]
end

function _noise_removal_basis(J, allowed, metadata, target_rank::Int; rank_atol::Float64 = 1e-8)
	kept = sort(collect(allowed))
	for idx in sort(kept; by = i -> (-metadata[i].max_observed_order, -metadata[i].support_score, -i))
		length(kept) <= target_rank && break
		trial = setdiff(kept, [idx])
		if _noise_rank_of_rows(J, trial; rank_atol = rank_atol) >= target_rank
			kept = trial
		end
	end
	return length(kept) == target_rank && _noise_rank_of_rows(J, kept; rank_atol = rank_atol) == target_rank ? sort(kept) : Int[]
end

function _noise_basis_score(indices, metadata)
	isempty(indices) && return Inf
	return sum(metadata[i].support_score for i in indices)
end

function _noise_exchange_candidates(J, seeds, allowed, metadata, target_rank::Int; beam_width::Int, rank_atol::Float64 = 1e-8)
	beam = unique([sort(s) for s in seeds if length(s) == target_rank])
	sort!(beam; by = s -> _noise_basis_score(s, metadata))
	length(beam) > beam_width && resize!(beam, beam_width)
	for _ in 1:2
		next = copy(beam)
		for basis in beam
			basis_set = Set(basis)
			for out_idx in basis
				for in_idx in allowed
					in_idx in basis_set && continue
					trial = sort!(vcat(setdiff(basis, [out_idx]), [in_idx]))
					if _noise_rank_of_rows(J, trial; rank_atol = rank_atol) == target_rank
						push!(next, trial)
					end
				end
			end
		end
		unique!(next)
		sort!(next; by = s -> _noise_basis_score(s, metadata))
		length(next) > beam_width && resize!(next, beam_width)
		beam = next
	end
	return beam
end

function _noise_classify_selected_vars(equations, pep, dd_order_by_obj, dd_order_by_string, obs_bases)
	vars_set = OrderedCollections.OrderedSet{Any}()
	for eq in equations
		union!(vars_set, Symbolics.get_variables(eq))
	end
	solve_vars = Any[]
	data_vars = Any[]
	for v in vars_set
		role = _noise_var_role(v, pep, dd_order_by_obj, dd_order_by_string, obs_bases)
		if role.role in (:data, :transcendental)
			push!(data_vars, v)
		else
			push!(solve_vars, v)
		end
	end
	return solve_vars, data_vars
end

function _noise_condition_proxy(J, selected; rank_atol::Float64 = 1e-8)
	length(selected) == 0 && return Inf
	Js = J[selected, :]
	size(Js, 1) < size(Js, 2) && return Inf
	svs = try
		svdvals(Js)
	catch
		return Inf
	end
	isempty(svs) && return Inf
	return svs[1] / max(svs[end], rank_atol)
end

function _noise_mixed_volume(equations, solve_vars, data_vars)
	length(equations) == length(solve_vars) || return nothing
	try
		if isempty(data_vars)
			hc_system, _ = convert_to_hc_format(equations, solve_vars)
			return Int(HomotopyContinuation.mixed_volume(hc_system))
		end
		hc_system, _, _ = convert_to_hc_format_with_params(equations, solve_vars, data_vars)
		return Int(HomotopyContinuation.mixed_volume(hc_system))
	catch e
		@warn "[NOISE-FRONTIER] mixed_volume failed" exception = e
		return nothing
	end
end

function _noise_candidate_from_indices(
	indices,
	strategy::Symbol,
	cap::Int,
	pool,
	J,
	pep,
	dd_order_by_obj,
	dd_order_by_string,
	obs_bases;
	compute_mixed_volume::Bool,
	rank_atol::Float64 = 1e-8,
)
	selected = sort(collect(indices))
	equations = Any[pool.symbolic_equations[i] for i in selected]
	solve_vars, data_vars = _noise_classify_selected_vars(equations, pep, dd_order_by_obj, dd_order_by_string, obs_bases)
	r = _noise_rank_of_rows(J, selected; rank_atol = rank_atol)
	target_rank = length(pool.instantiated_vars)
	is_square = length(equations) == length(solve_vars)
	rank_complete = r == target_rank
	mv = compute_mixed_volume && is_square && rank_complete ? _noise_mixed_volume(equations, solve_vars, data_vars) : nothing
	all_indices = collect(eachindex(pool.symbolic_equations))
	return NoiseFrontierCandidate(
		pool.n_points,
		strategy,
		cap,
		selected,
		Int[pool.metadata[i].source_index for i in selected],
		setdiff(all_indices, selected),
		equations,
		solve_vars,
		data_vars,
		NoiseEqMeta[pool.metadata[i] for i in selected],
		r,
		target_rank,
		is_square,
		rank_complete,
		_noise_basis_score(selected, pool.metadata),
		length(solve_vars),
		length(data_vars),
		_noise_condition_proxy(J, selected; rank_atol = rank_atol),
		mv,
	)
end

function _noise_candidate_sort_key(c::NoiseFrontierCandidate)
	mv_key = isnothing(c.mixed_volume) ? typemax(Int) : c.mixed_volume
	return (mv_key, c.support_score, c.solve_var_count, c.condition_proxy, string(c.strategy), join(c.selected_equation_indices, " "))
end

function _noise_observable_index_by_name(measured_quantities)
	obs_name_to_idx = Dict{String, Int}()
	for (idx, mq_eq) in enumerate(measured_quantities)
		obs_name = replace(string(mq_eq.lhs), r"\(.*\)$" => "")
		obs_name_to_idx[obs_name] = idx
	end
	return obs_name_to_idx
end

function _noise_evaluate_data_var(v, interpolants, measured_quantities, obs_name_to_idx, t_point)
	clean_name = _noise_strip_point_suffix(string(v))
	trfn_val = evaluate_trfn_template_variable(clean_name, t_point)
	isnothing(trfn_val) && (trfn_val = evaluate_obs_trfn_template_variable(clean_name, t_point))
	if !isnothing(trfn_val)
		return Float64(trfn_val)
	end

	parsed = parse_derivative_variable_name(clean_name)
	if isnothing(parsed)
		@warn "[NOISE-FRONTIER] Cannot parse data variable; using 0.0" data_var = string(v)
		return 0.0
	end
	base_name, deriv_order = parsed
	obs_idx = get(obs_name_to_idx, string(base_name), nothing)
	if isnothing(obs_idx)
		m = match(r"^y(\d+)$", string(base_name))
		!isnothing(m) && (obs_idx = parse(Int, m.captures[1]))
	end

	if !isnothing(obs_idx) && obs_idx <= length(measured_quantities)
		obs_rhs = ModelingToolkit.diff2term(measured_quantities[obs_idx].rhs)
		if haskey(interpolants, obs_rhs)
			return Float64(nth_deriv(x -> interpolants[obs_rhs](x), deriv_order, t_point))
		end
		obs_lhs_wrapped = Symbolics.wrap(measured_quantities[obs_idx].lhs)
		if haskey(interpolants, obs_lhs_wrapped)
			return Float64(nth_deriv(x -> interpolants[obs_lhs_wrapped](x), deriv_order, t_point))
		end
	end

	@warn "[NOISE-FRONTIER] No interpolant for data variable; using 0.0" data_var = string(v) base = string(base_name) deriv_order obs_idx
	return 0.0
end

"""
	evaluate_noise_frontier_data_vars_at_point(interpolants, data_vars, measured_quantities, t_point)

Evaluate the selected frontier candidate's data variables in the exact order
expected by HC parameter homotopy. Data variables are clean SIAN-style names
(`y1_0`, `y2_3`, possibly suffixed with `_ptK`) plus optional `_trfn_` variables.
"""
function evaluate_noise_frontier_data_vars_at_point(interpolants, data_vars, measured_quantities, t_point)
	obs_name_to_idx = _noise_observable_index_by_name(measured_quantities)
	return Float64[
		_noise_evaluate_data_var(v, interpolants, measured_quantities, obs_name_to_idx, t_point)
		for v in data_vars
	]
end

function instantiate_noise_frontier_candidate(candidate::NoiseFrontierCandidate, interpolants, data_sample, measured_quantities, time_index::Int)
	t_point = data_sample["t"][time_index]
	values = evaluate_noise_frontier_data_vars_at_point(interpolants, candidate.data_vars, measured_quantities, t_point)
	subst = Dict{Any, Any}(candidate.data_vars[i] => values[i] for i in eachindex(candidate.data_vars))
	return [Symbolics.substitute(eq, subst) for eq in candidate.equations], candidate.solve_vars
end

function _noise_point_index_for_var(v, n_points::Int)
	name = string(v)
	for pt in 2:n_points
		endswith(name, "_pt$pt") && return pt
	end
	return 1
end

function _noise_order_data_vars_by_point(data_vars, n_points::Int)
	return sort(collect(data_vars); by = v -> (_noise_point_index_for_var(v, n_points), string(v)))
end

function _noise_per_point_ranges(data_vars, n_points::Int)
	per_point_indices = [Int[] for _ in 1:n_points]
	for (i, dv) in enumerate(data_vars)
		push!(per_point_indices[_noise_point_index_for_var(dv, n_points)], i)
	end
	ranges = UnitRange{Int}[]
	for indices in per_point_indices
		push!(ranges, isempty(indices) ? (1:0) : (first(indices):last(indices)))
	end
	return ranges
end

function _noise_param_indices_and_names(solve_vars, pep::ParameterEstimationProblem)
	param_names_set = Set(replace(string(p), "(t)" => "") for p in keys(pep.p_true))
	param_indices = Int[]
	param_names = String[]
	for (i, v) in enumerate(solve_vars)
		clean = _noise_strip_point_suffix(string(v))
		clean = replace(clean, r"_0$" => "")
		clean = replace(clean, r"\(.*\)$" => "")
		if clean in param_names_set
			push!(param_indices, i)
			push!(param_names, clean)
		end
	end
	return param_indices, param_names
end

"""
	build_noise_frontier_multipoint_template(pep, setup, si_template; kwargs...) -> MultiPointTemplate

Build a production `MultiPointTemplate` from the full-equation noise-frontier
selection. This is the replacement for `build_multipoint_template` when
`system_construction_policy = :noise_frontier`.
"""
function build_noise_frontier_multipoint_template(
	pep::ParameterEstimationProblem,
	setup::NamedTuple,
	si_template;
	n_points::Int = 2,
	compute_mixed_volume::Bool = true,
	candidate_limit::Int = 64,
	beam_width::Int = 16,
	rank_atol::Float64 = 1e-8,
	diagnostics::Bool = false,
)
	result = build_noise_frontier_system(
		pep,
		setup,
		si_template;
		n_points = n_points,
		compute_mixed_volume = compute_mixed_volume,
		candidate_limit = candidate_limit,
		beam_width = beam_width,
		rank_atol = rank_atol,
		diagnostics = diagnostics,
	)
	selected = result.selected
	isnothing(selected) && error("noise-frontier multipoint construction found no square full-rank candidate")

	data_vars = _noise_order_data_vars_by_point(selected.data_vars, n_points)
	param_indices, param_names = _noise_param_indices_and_names(selected.solve_vars, pep)
	eq_metadata = [(point = m.point, is_data = false, order = m.max_observed_order) for m in selected.eq_metadata]
	per_point_ranges = _noise_per_point_ranges(data_vars, n_points)
	if diagnostics
		@info "[NOISE-FRONTIER-MP] Selected template" n_points equations = length(selected.equations) solve_vars = length(selected.solve_vars) data_vars = length(data_vars) max_observed_order = selected.max_observed_order mixed_volume = selected.mixed_volume
	end

	return MultiPointTemplate(
		n_points,
		si_template,
		Num[eq for eq in selected.equations],
		Num[eq for eq in selected.equations],
		selected.solve_vars,
		data_vars,
		param_indices,
		param_names,
		eq_metadata,
		result.combined_equation_count,
		selected.selected_equation_indices,
		selected.dropped_equation_indices,
		per_point_ranges,
		hasproperty(si_template, :template_DD) ? si_template.template_DD : setup.good_DD,
		pep.measured_quantities,
	)
end

"""
	build_noise_frontier_system(pep, setup, si_template; kwargs...) -> NoiseFrontierResult

Build a noise-first square-system construction frontier. `setup` must provide
`good_DD` and `interpolants`, matching the normal multishot setup tuple.
"""
function build_noise_frontier_system(
	pep::ParameterEstimationProblem,
	setup::NamedTuple,
	si_template;
	n_points::Int = 1,
	compute_mixed_volume::Bool = true,
	candidate_limit::Int = 64,
	beam_width::Int = 16,
	rank_atol::Float64 = 1e-8,
	n_rank_probes::Int = 3,
	diagnostics::Bool = false,
	probe_indices::Union{Nothing, Vector{Int}} = nothing,
)
	candidate_limit > 0 || throw(ArgumentError("candidate_limit must be positive"))
	beam_width > 0 || throw(ArgumentError("beam_width must be positive"))
	raw_pool = _noise_build_pool(pep, setup, si_template;
		n_points = n_points, diagnostics = diagnostics, probe_indices = probe_indices)
	pool = (; raw_pool..., n_points = n_points)
	J, full_rank = _noise_rank_matrix(pool.instantiated_equations, pool.instantiated_vars;
		rank_atol = rank_atol, n_rank_probes = n_rank_probes)
	target_rank = length(pool.instantiated_vars)
	max_cap = maximum([m.max_observed_order for m in pool.metadata]; init = -1)
	max_cap = max(max_cap, 0)
	frontier = NamedTuple[]
	candidates = NoiseFrontierCandidate[]
	selected_cap = nothing

	dd_order_by_obj, dd_order_by_string = _noise_dd_order_maps(pool.template_DD)
	obs_bases = _noise_observable_bases(pep.measured_quantities)

	for cap in 0:max_cap
		allowed = [i for i in eachindex(pool.metadata) if pool.metadata[i].max_observed_order <= cap]
		allowed_rank = _noise_rank_of_rows(J, allowed; rank_atol = rank_atol)
		feasible = allowed_rank >= target_rank && full_rank >= target_rank
		push!(frontier, (
			max_observed_order = cap,
			allowed_count = length(allowed),
			allowed_rank = allowed_rank,
			target_rank = target_rank,
			feasible = feasible,
		))
		feasible || continue
		selected_cap = cap

		seeds = Vector{Vector{Int}}()
		orders = Dict{Symbol, Vector{Int}}(
			:support_greedy => sort(allowed; by = i -> (pool.metadata[i].support_score, pool.metadata[i].max_observed_order, i)),
			:index_greedy => sort(allowed),
			:reverse_support_greedy => sort(allowed; by = i -> (-pool.metadata[i].support_score, pool.metadata[i].max_observed_order, i)),
		)
		for (strategy, order) in orders
			basis = _noise_greedy_basis(J, order, target_rank; rank_atol = rank_atol)
			isempty(basis) || push!(seeds, basis)
		end
		for tie_policy in (:support, :data_order)
			basis = _noise_dynamic_basis(J, allowed, pool.metadata, pool.symbolic_equations, pep,
				dd_order_by_obj, dd_order_by_string, obs_bases, target_rank;
				tie_policy = tie_policy, rank_atol = rank_atol)
			isempty(basis) || push!(seeds, basis)
		end
		removal = _noise_removal_basis(J, allowed, pool.metadata, target_rank; rank_atol = rank_atol)
		isempty(removal) || push!(seeds, removal)

		exchanged = _noise_exchange_candidates(J, seeds, allowed, pool.metadata, target_rank;
			beam_width = beam_width, rank_atol = rank_atol)
		all_bases = unique(vcat([sort(s) for s in seeds], exchanged))
		sort!(all_bases; by = s -> _noise_basis_score(s, pool.metadata))
		length(all_bases) > candidate_limit && resize!(all_bases, candidate_limit)

		for (i, basis) in enumerate(all_bases)
			strategy = i <= length(seeds) ? Symbol(:seed_, i) : Symbol(:exchange_, i)
			push!(candidates, _noise_candidate_from_indices(
				basis,
				strategy,
				cap,
				pool,
				J,
				pep,
				dd_order_by_obj,
				dd_order_by_string,
				obs_bases;
				compute_mixed_volume = compute_mixed_volume,
				rank_atol = rank_atol,
			))
		end
		break
	end

	valid_candidates = [c for c in candidates if c.rank_complete && c.is_square]
	sort!(valid_candidates; by = _noise_candidate_sort_key)
	selected = isempty(valid_candidates) ? nothing : first(valid_candidates)
	if diagnostics
		if isnothing(selected)
			@warn "[NOISE-FRONTIER] No square full-rank candidate found" n_points target_rank full_rank
		else
			@info "[NOISE-FRONTIER] Selected candidate" n_points max_observed_order = selected.max_observed_order mixed_volume = selected.mixed_volume support_score = selected.support_score solve_vars = selected.solve_var_count data_vars = selected.data_var_count
		end
	end
	return NoiseFrontierResult(
		n_points,
		selected_cap,
		selected,
		candidates,
		frontier,
		pool.full_equation_count,
		length(pool.symbolic_equations),
		target_rank,
	)
end

function noise_frontier_rows(result::NoiseFrontierResult)
	rows = NamedTuple[]
	for c in result.candidates
		push!(rows, (
			n_points = c.n_points,
			strategy = c.strategy,
			max_observed_order = c.max_observed_order,
			rank = c.rank,
			target_rank = c.target_rank,
			is_square = c.is_square,
			solve_var_count = c.solve_var_count,
			data_var_count = c.data_var_count,
			support_score = c.support_score,
			condition_proxy = c.condition_proxy,
			mixed_volume = isnothing(c.mixed_volume) ? missing : c.mixed_volume,
			selected_equation_indices = join(c.selected_equation_indices, " "),
			selected_source_indices = join(c.selected_source_indices, " "),
		))
	end
	return rows
end

function write_noise_frontier_csv(path::AbstractString, result::NoiseFrontierResult)
	rows = noise_frontier_rows(result)
	open(path, "w") do io
		header = [
			"n_points", "strategy", "max_observed_order", "rank", "target_rank",
			"is_square", "solve_var_count", "data_var_count", "support_score",
			"condition_proxy", "mixed_volume", "selected_equation_indices",
			"selected_source_indices",
		]
		println(io, join(header, ","))
		for row in rows
			values = [replace(string(getproperty(row, Symbol(h))), "," => ";") for h in header]
			println(io, join(values, ","))
		end
	end
	return path
end
