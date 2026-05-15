"""
	get_solution_vector(solution)

Extract a vector of values from a solution object.

# Arguments
- `solution`: Solution object containing states and parameters

# Returns
- Vector containing concatenated state and parameter values
"""
function get_solution_vector(solution)
	return vcat(collect(values(solution.states)), collect(values(solution.parameters)))
end

"""
	solution_distance(sol1, sol2)

Calculate the relative distance between two solutions.

# Arguments
- `sol1`: First solution
- `sol2`: Second solution

# Returns
- Maximum relative difference between corresponding components
"""
function solution_distance(sol1, sol2)
	v1 = get_solution_vector(sol1)
	v2 = get_solution_vector(sol2)
	# Use relative distance for each component with better handling of near-zero values
	rel_diffs = map(zip(v1, v2)) do (x, y)
		denom = max(abs(x) + abs(y), 1.0)  # Avoid division by zero
		return abs(x - y) / denom
	end
	return maximum(rel_diffs)
end

"""
	cluster_solutions(sorted_results)

Group similar solutions into clusters based on relative distances.

# Arguments
- `sorted_results`: Vector of solutions sorted by error

# Returns
- Vector of solution clusters
"""
function cluster_solutions(sorted_results)
	clusters = Vector{Vector{Any}}()

	for sol in sorted_results
		# Try to find a cluster for this solution
		cluster_idx = findfirst(cluster ->
				solution_distance(sol, cluster[1]) < CLUSTERING_THRESHOLD,
			clusters)

		if isnothing(cluster_idx)
			# Start new cluster
			push!(clusters, [sol])
		else
			# Add to existing cluster
			push!(clusters[cluster_idx], sol)
		end
	end

	return clusters
end

function relative_error_value(est, true_val)
	if !isfinite(est)
		return NaN
	elseif abs(true_val) < 1e-6
		return abs(est - true_val)
	else
		return abs((est - true_val) / true_val)
	end
end

function oracle_error_stats(problem::ParameterEstimationProblem, candidate)
	param_names = collect(keys(candidate.parameters))
	non_init_params = filter(p -> !startswith(string(p), "init_"), param_names)
	unident_params = if hasfield(typeof(candidate), :all_unidentifiable)
		Set(candidate.all_unidentifiable)
	else
		Set()
	end

	errorvec = Float64[]

	for (state, value) in candidate.states
		if !(state in unident_params) && haskey(problem.ic, state)
			push!(errorvec, relative_error_value(value, problem.ic[state]))
		end
	end

	for p in non_init_params
		if !(p in unident_params) && haskey(problem.p_true, p)
			push!(errorvec, relative_error_value(candidate.parameters[p], problem.p_true[p]))
		end
	end

	finite_errors = filter(isfinite, errorvec)
	isempty(finite_errors) && return nothing

	return (
		minimum = minimum(finite_errors),
		mean = mean(finite_errors),
		median = median(finite_errors),
		maximum = maximum(finite_errors),
		rms = sqrt(mean(finite_errors .^ 2)),
	)
end

function oracle_sort_key(problem::ParameterEstimationProblem, candidate)
	stats = oracle_error_stats(problem, candidate)
	if isnothing(stats)
		return (Inf, Inf, isnothing(candidate.err) ? Inf : candidate.err)
	end
	return (stats.maximum, stats.median, isnothing(candidate.err) ? Inf : candidate.err)
end

# ──────────── Branch detection (Phase B candidate-reduction) ────────────────
#
# Given a list of (already-polished) ParameterEstimationResult representatives,
# cluster them in identifiable-variable space using L-infinity normalized distance,
# then filter clusters by per-cluster median residual and size to surface
# "algebraic branches" rather than 100s-1000s of near-duplicates.
#
# Returns a Vector{ParameterEstimationResult} of cluster representatives, each
# annotated with `branch_size` = the size of its source cluster, sorted by
# ascending median residual.

"""
	_branch_cluster_linf(values_matrix::AbstractMatrix, eps::Float64) -> Vector{Int}

L-infinity clustering with robust per-column normalization. Returns a cluster
label per row. Used by branch-detection (Phase B) post-polish step.

Algorithm:
  med_v   = median(X[:, v])              # per-column median
  mad_v   = median(|X[:, v] - med_v|)    # MAD
  scale_v = max(|med_v|, mad_v, 1e-10)
  X_norm  = (X .- med) ./ scale
  dist(i, j) = max over v of |X_norm[i,v] - X_norm[j,v]|     # L-inf
  edge(i, j) iff dist < eps
  cluster = connected components

Implementation: greedy single-link in row order (matching `cluster_solutions`).
"""
function _branch_cluster_linf(X::AbstractMatrix{Float64}, eps::Float64)
	n, d = size(X)
	labels = zeros(Int, n)
	if n == 0
		return labels
	end
	# Per-column robust scale
	med = [median(X[:, v]) for v in 1:d]
	mad = [median(abs.(X[:, v] .- med[v])) for v in 1:d]
	scale = [max(abs(med[v]), mad[v], 1e-10) for v in 1:d]
	Xn = similar(X)
	for v in 1:d
		Xn[:, v] = (X[:, v] .- med[v]) ./ scale[v]
	end
	# Greedy single-link in row order
	cluster_reps = Int[]
	for i in 1:n
		merged = false
		for (k, rep) in enumerate(cluster_reps)
			dist = 0.0
			for v in 1:d
				diff = abs(Xn[i, v] - Xn[rep, v])
				dist = max(dist, diff)
				if dist >= eps
					break
				end
			end
			if dist < eps
				labels[i] = k
				merged = true
				break
			end
		end
		if !merged
			push!(cluster_reps, i)
			labels[i] = length(cluster_reps)
		end
	end
	return labels
end

"""
	_detect_branches(reps::Vector{ParameterEstimationResult}; opts) -> Vector{ParameterEstimationResult}

Post-polish branch detection. Re-cluster cluster reps in identifiable-only
variable space; keep only clusters whose median err is within
`opts.branch_resid_factor` of the best cluster's median, and whose size is
at least `opts.branch_min_size`. Each surviving representative is annotated
with `branch_size` = size of its source cluster. Result sorted by median err.

If no clusters survive (e.g., everything is tiny), falls back to the single
best-err rep with `branch_size = 1`.
"""
function _detect_branches(reps::AbstractVector, opts::EstimationOptions)
	if isempty(reps)
		return ParameterEstimationResult[]
	end

	# Pre-cluster filter: drop candidates whose individual polish residual is
	# >branch_resid_factor× the global best. This is more aggressive (and more
	# robust) than the post-cluster median filter we used to do — it shrinks the
	# input set to a small high-quality subset before L∞-MAD clustering can be
	# fooled by extreme outliers (e.g. blown-rescue candidates with values ~1e10
	# inflate MAD and squash legitimate separations).
	reps_collected = collect(reps)
	if length(reps_collected) > 1
		finite_errs = Float64[c.err for c in reps_collected if !isnothing(c.err) && isfinite(c.err)]
		if !isempty(finite_errs)
			best_err = minimum(finite_errs)
			cutoff = opts.branch_resid_factor * best_err
			filtered = filter(c -> !isnothing(c.err) && isfinite(c.err) && c.err <= cutoff, reps_collected)
			if !isempty(filtered)
				reps_collected = filtered
			end
		end
	end
	reps = reps_collected

	if length(reps) == 1
		r = first(reps)
		r.branch_size = 1
		return ParameterEstimationResult[r]
	end

	# Determine identifiable-vs-non-id mask, in the order: states then parameters
	first_rep = first(reps)
	all_unid = first_rep.all_unidentifiable  # Set{Num}
	state_keys = collect(keys(first_rep.states))
	param_keys = collect(keys(first_rep.parameters))
	all_keys = vcat(state_keys, param_keys)
	id_mask = Bool[!(k in all_unid) for k in all_keys]
	id_keys = all_keys[id_mask]

	# Build (n × d_id) matrix of identifiable values
	n = length(reps)
	d = length(id_keys)
	if d == 0
		# Everything flagged non-id — degenerate; keep single best-err rep
		sorted = sort(collect(reps), by = c -> isnothing(c.err) ? Inf : c.err)
		best = first(sorted)
		best.branch_size = length(reps)
		return ParameterEstimationResult[best]
	end

	X = Matrix{Float64}(undef, n, d)
	for (i, r) in enumerate(reps)
		for (j, k) in enumerate(id_keys)
			v = haskey(r.states, k) ? r.states[k] : r.parameters[k]
			X[i, j] = Float64(v)
		end
	end

	# Cluster
	labels = _branch_cluster_linf(X, opts.branch_cluster_eps)
	n_clusters = maximum(labels)

	# Per-cluster: size + median err + best-err rep
	cluster_sizes = zeros(Int, n_clusters)
	cluster_errs = [Float64[] for _ in 1:n_clusters]
	cluster_members = [Int[] for _ in 1:n_clusters]
	for (i, lab) in enumerate(labels)
		cluster_sizes[lab] += 1
		err = (isnothing(reps[i].err) || !isfinite(reps[i].err)) ? Inf : reps[i].err
		push!(cluster_errs[lab], err)
		push!(cluster_members[lab], i)
	end
	cluster_med = [isempty(es) ? Inf : median(es) for es in cluster_errs]

	# Best cluster's median err
	finite_meds = filter(isfinite, cluster_med)
	best_med = isempty(finite_meds) ? Inf : minimum(finite_meds)

	# Filter: residual ≤ resid_factor × best AND size ≥ min_size
	survivors = Int[]
	for k in 1:n_clusters
		ok_resid = isfinite(cluster_med[k]) && cluster_med[k] <= opts.branch_resid_factor * best_med
		ok_size = cluster_sizes[k] >= opts.branch_min_size
		if ok_resid && ok_size
			push!(survivors, k)
		end
	end

	# Fallback: if nothing survives, take the cluster with the lowest median err
	if isempty(survivors)
		# Pick the single best cluster by median err; any size
		_, k_best = findmin(cluster_med)
		push!(survivors, k_best)
	end

	# For each surviving cluster, pick the best-err rep within it and annotate branch_size
	out = ParameterEstimationResult[]
	for k in survivors
		members = cluster_members[k]
		# Best-err member
		best_member_idx = argmin([(isnothing(reps[i].err) || !isfinite(reps[i].err)) ? Inf : reps[i].err for i in members])
		rep_idx = members[best_member_idx]
		rep = reps[rep_idx]
		rep.branch_size = cluster_sizes[k]
		push!(out, rep)
	end

	# Sort by cluster median err (ascending)
	sort!(out, by = c -> (isnothing(c.err) || !isfinite(c.err)) ? Inf : c.err)

	# Cap result count at branch_top_k (0 = disabled). Truth-near rep is in the
	# top of the err-sorted list in 6/6 polish + 3/3 nopolish cases verified in
	# the 2026-05 numbat probes; 20 is a defensible default.
	if opts.branch_top_k > 0 && length(out) > opts.branch_top_k
		out = out[1:opts.branch_top_k]
	end
	return out
end

function apply_uq_failure_policy(uq_result, opts::EstimationOptions)
	if !uq_result.success && opts.uq_failure_policy == :throw
		error("Uncertainty quantification failed: $(uq_result.message)")
	end
	return uq_result
end

_result_err_key(candidate) = (isnothing(candidate.err) || !isfinite(candidate.err)) ? Inf : candidate.err

function _scored_results(results)
	return filter(results) do candidate
		err = candidate.err
		!isnothing(err) && isfinite(err)
	end
end

function _best_scored_result(results)
	scored = _scored_results(results)
	isempty(scored) && return nothing
	return first(sort(scored, by = _result_err_key))
end

const _UQ_MATERN_INTERPOLATOR_SOURCES = Set((
	:agp_robust_matern52,
	:s3_matern52,
	:s3_adapt_matern52,
	:s3_bic_matern52,
))

function _default_uq_interpolator_source(opts::EstimationOptions)
	if !isempty(opts.interpolators)
		return interpolator_method_to_symbol(first(opts.interpolators))
	end
	return interpolator_method_to_symbol(opts.interpolator)
end

_uq_kernel_from_interpolator_source(source::Union{Nothing, Symbol}) =
	source in _UQ_MATERN_INTERPOLATOR_SOURCES ? :matern52 : :se

function _uq_kernel_for_result(candidate, opts::EstimationOptions)::Symbol
	source = if hasproperty(candidate, :provenance) && !isnothing(candidate.provenance.interpolator_source)
		candidate.provenance.interpolator_source
	elseif hasproperty(candidate, :interpolator_source) && !isnothing(candidate.interpolator_source)
		candidate.interpolator_source
	else
		_default_uq_interpolator_source(opts)
	end
	return _uq_kernel_from_interpolator_source(source)
end

function _compute_uq_result(
	PEP::ParameterEstimationProblem,
	solved_res,
	opts::EstimationOptions,
)
	if !(opts.compute_uncertainty && !isempty(solved_res))
		return nothing
	end

	best_solution = _best_scored_result(solved_res)
	if isnothing(best_solution)
		if !opts.nooutput
			println("\nSkipping parameter uncertainty: no finite-error solution available.")
		end
		return nothing
	end

	if !opts.nooutput
		println("\nComputing parameter uncertainty (experimental)...")
	end

	uq_result = estimate_parameter_uncertainty(
		PEP,
		best_solution,
		PEP.data_sample;
		max_deriv_order = 2,
		n_timepoints = min(20, length(PEP.data_sample["t"]) ÷ 5),
		kernel_type = _uq_kernel_for_result(best_solution, opts),
	)
	uq_result = apply_uq_failure_policy(uq_result, opts)
	if !opts.nooutput
		print_uncertainty_results(uq_result)
	end
	return uq_result
end

"""
	print_stats_table(io, name, stats)

Print a formatted table of statistics.

# Arguments
- `io`: IO stream to print to
- `name`: Name of the statistics group
- `stats`: Dictionary of statistics to print
"""
function print_stats_table(io, name, stats)
	println(io, "\n$name Statistics:")
	println(io, "-"^50)
	println(io, "Variable      | Mean        | Std         | Min         | Max         | Range       | Turns")
	println(io, "-"^50)
	for (var, stat) in stats
		@printf(io, "%-12s | %10.6f | %10.6f | %10.6f | %10.6f | %10.6f | %10d\n",
			var, stat.mean, stat.std, stat.min, stat.max, stat.range, stat.turns)
	end
end

"""
	analyze_estimation_result(problem::ParameterEstimationProblem, result)

Analyze the results of parameter estimation, including clustering solutions and printing statistics.

# Arguments
- `problem`: The parameter estimation problem
- `result`: Vector of solution results
"""
function analyze_estimation_result(problem::ParameterEstimationProblem, result;
		nooutput = false, opts::EstimationOptions = EstimationOptions())
	# Merge dictionaries into a single OrderedDict
	all_params = merge(OrderedDict(), problem.ic, problem.p_true)

	# Print header
	if !nooutput
		println("\n=== Model: $(problem.name) ===")
	end

	scored_results = _scored_results(result)
	sorted_results = if isempty(scored_results)
		Any[]
	else
		sort(scored_results, by = _result_err_key)
	end

	# Cluster ALL candidates first; rely on clustering (CLUSTERING_THRESHOLD = 1e-5
	# relative parameter distance) to produce the set of distinct algebraic-basin
	# representatives. The legacy `err < MAX_ERROR_THRESHOLD` gate silently dropped
	# truth-near candidates whose trajectory loss was high (e.g. on practical-non-
	# identifiability cases like flexible_arm where fit-best is anticorrelated with
	# truth-best). Cluster-first preserves them as separate basin reps.
	#
	# We do NOT cap cluster count: the legacy code's MAX_SOLUTIONS cap applied only
	# to raw candidates in the rare fallback branch (when no candidate had err<0.5).
	# Capping clusters too aggressively drops truth-near reps when the natural
	# cluster count exceeds the cap (flex_arm has 83 natural clusters).
	clusters = cluster_solutions(sorted_results)

	# Show unidentifiable parameters if any
	if !isempty(sorted_results)
		first_result = first(sorted_results)

		# First show all structurally unidentifiable parameters
		if hasfield(typeof(first_result), :all_unidentifiable) && !isempty(first_result.all_unidentifiable)
			if !nooutput
				println("\nAll structurally unidentifiable parameters:")
				println("-"^50)
				println("These parameters cannot be uniquely determined from the data:")
				for param in first_result.all_unidentifiable
					println("  • $param")
				end
				println()
			end
		end

		# Then show the minimal set of fixed values
		if !isnothing(first_result.unident_dict) && !isempty(first_result.unident_dict)
			if !nooutput
				println("\nMinimal set of fixed values to make remaining parameters identifiable:")
				println("-"^50)
				println("These parameters were fixed to make the system identifiable:")
				for (param, value) in first_result.unident_dict
					# Format the value - handle complex numbers
					val_str = if value isa Complex
						abs(imag(value)) < 1e-10 ?
						@sprintf("%.6f", real(value)) :
						@sprintf("%.3f%+.3fi", real(value), imag(value))
					else
						@sprintf("%.6f", value)
					end
					println("  • $param = $val_str")
				end
				println()
			end
		end
	end

	# Print best solution from each cluster
	if !nooutput
		println("\nFound $(length(clusters)) distinct solution clusters:")
	end
	for (i, cluster) in enumerate(clusters)
		best_solution = first(cluster)  # cluster is sorted by error
		if !nooutput
			println("\nCluster $i: $(length(cluster)) similar solutions")
			println("Best solution (Error: $(round(best_solution.err, digits=6))):")
			if hasfield(typeof(best_solution), :provenance)
				println("Lineage: $(lineage_summary(best_solution))")
			end
			println("-"^50)
		end

		# Get parameters in original order from the model
		param_names = problem.model.original_parameters

		# Filter out init_ parameters from the parameter list since they're already in states
		non_init_params = filter(p -> !startswith(string(p), "init_"), param_names)

		# First get the state names in the order they appear in the model
		state_names = problem.model.original_states

		# Collect values in matching order
		estimates = vcat(
			[best_solution.states[s] for s in state_names],
			[best_solution.parameters[p] for p in non_init_params],
		)
		true_values = vcat(
			[problem.ic[s] for s in state_names],
			[problem.p_true[p] for p in non_init_params],
		)
		var_names = vcat(state_names, non_init_params)

		# Calculate relative errors with proper handling of near-zero values
		rel_errors = map(zip(estimates, true_values)) do (est, true_val)
			relative_error_value(est, true_val)
		end

		# Find maximum lengths for alignment
		max_var_len = maximum(length(string(var)) for var in var_names)
		max_var_len = max(max_var_len, 12) # minimum width for "Variable" header

		# Print table header with dynamic width
		header = @sprintf("%-*s | True Value  | Estimated   | Rel. Error", max_var_len, "Variable")
		if !nooutput
			println(header)
			println("-"^(length(header)))
		end

		# Print states and parameters
		for (var, true_val, est_val, rel_err) in zip(var_names, true_values, estimates, rel_errors)
			# Format the estimated value - handle complex numbers
			est_str = if est_val isa Complex
				abs(imag(est_val)) < 1e-10 ?
				@sprintf("%.6f", real(est_val)) :
				@sprintf("%.3f%+.3fi", real(est_val), imag(est_val))
			else
				@sprintf("%.6f", est_val)
			end

			# Print the row with dynamic width
			if !nooutput
				@printf("%-*s | %10.6f | %10s | %10.6f\n",
					max_var_len, var, true_val, est_str, rel_err)
			end
		end
		if !nooutput
			println()
		end
	end

	# Print best approximation error summary line
	best_approximation_error = isempty(sorted_results) ? Inf : first(sorted_results).err
	if !nooutput
		println("\nBest approximation error for $(problem.name): $(round(best_approximation_error, digits=6))")
	end

	# Calculate and return best error (excluding unidentifiable parameters)
	besterror = Inf
	best_min_error = Inf
	best_mean_error = Inf
	best_median_error = Inf
	best_max_error = Inf
	best_rms_error = Inf

	if !isempty(scored_results)
		for each in result
			stats = oracle_error_stats(problem, each)
			if !isnothing(stats)
				besterror = min(besterror, stats.maximum)
				best_min_error = min(best_min_error, stats.minimum)
				best_mean_error = min(best_mean_error, stats.mean)
				best_median_error = min(best_median_error, stats.median)
				best_max_error = min(best_max_error, stats.maximum)
				best_rms_error = min(best_rms_error, stats.rms)
			end
		end
	end
	if !nooutput
		println("\nBest maximum relative error for $(problem.name) (excluding ALL unidentifiable parameters): $(round(besterror, digits=6))")
		println("Best minimum relative error: $(round(best_min_error, digits=6))")
		println("Best mean relative error: $(round(best_mean_error, digits=6))")
		println("Best median relative error: $(round(best_median_error, digits=6))")
		println("Best maximum relative error: $(round(best_max_error, digits=6))")
		println("Best RMS relative error: $(round(best_rms_error, digits=6))")
	end
	# Return a tuple containing:
	# - Vector of best solutions from each cluster
	# - Best maximum relative error across all results
	# - Best minimum relative error across all results
	# - Best mean relative error across all results
	# - Best median relative error across all results
	# - Best maximum relative error across all results
	# - Best approximation error across all results
	# - Best RMS relative error across all results
	#
	# When opts.branch_detection is true (default), the returned representatives
	# are err-sorted cluster reps capped at branch_top_k. cluster_reps comes from
	# cluster_solutions(sorted_results) which preserves err order (lowest first),
	# so a simple slice gives top-K by data residual. branch_size is annotated below.
	#
	# Historically this stage called _detect_branches to do additional L∞-MAD
	# clustering on identifiable axes and filter by branch_resid_factor / branch_min_size.
	# The 2026-05-14 numbat regression eval (results/numbat_analysis/three_way/) found
	# _detect_branches drops the truth-near candidate in 43% of regression cells:
	# MAD-normalization can compress near-truth and far-from-truth into one cluster,
	# whose err-best rep then misses truth. Skipping it improves recovery from 3% to
	# 77% (within 2× of the legacy "06" benchmark's oracle) on 101 probe cells.
	# _detect_branches is still callable for diagnostics; just not used for output.
	#
	# When opts.branch_detection is false, fall back to legacy oracle-based sort (the
	# cheat) — retained for old-benchmark reproducibility.
	cluster_reps = [first(cluster) for cluster in clusters]
	for (i, c) in enumerate(clusters)
		cluster_reps[i].branch_size = length(c)
	end
	returned_results = if opts.branch_detection
		if opts.branch_top_k > 0 && length(cluster_reps) > opts.branch_top_k
			cluster_reps[1:opts.branch_top_k]
		else
			cluster_reps
		end
	else
		sort(cluster_reps, by = candidate -> oracle_sort_key(problem, candidate))
	end

	# `all_unidentifiable` is an equation-level invariant of the system, not a
	# per-candidate observation. Some upstream candidate-creating code paths
	# (notably synthesize_aggregates) historically forgot to propagate it, and
	# whichever rep the selection happened to land on then carried an empty set
	# into the output. Union across every input candidate to recover the system-
	# wide flag, then stamp it on each returned rep so consumers see consistent
	# output regardless of which code path produced the winning candidate.
	system_unid = Set{Num}()
	for r in sorted_results
		if hasfield(typeof(r), :all_unidentifiable)
			union!(system_unid, r.all_unidentifiable)
		end
	end
	for rep in returned_results
		rep.all_unidentifiable = system_unid
	end

	return (
		returned_results,
		besterror,
		best_min_error,
		best_mean_error,
		best_median_error,
		best_max_error,
		best_approximation_error,
		best_rms_error,
	)
end





function analyze_parameter_estimation_problem(PEP::ParameterEstimationProblem, opts::EstimationOptions = EstimationOptions())
	validate_options(opts) || throw(ArgumentError("Invalid EstimationOptions; fix the reported configuration errors before running estimation."))

	# Auto-handle transcendental functions (sin/cos/exp) at the top level
	# so the transformed PEP is used consistently for both estimation and analysis
	if opts.auto_handle_transcendentals
		t_var = ModelingToolkit.get_iv(PEP.model.system)
		PEP, _tr_info = transform_pep_for_estimation(PEP, t_var)
		if !isnothing(_tr_info) && !opts.nooutput
			println("Transcendental handling: transformed $(length(_tr_info.entries)) expression(s) into polynomial form")
		end
	end

	if !opts.nooutput
		println("Starting model: ", PEP.name)
	end

	# Initialize variables outside try blocks
	solved_res = []
	unident_dict = Dict()
	trivial_dict = Dict()
	all_unidentifiable = []

	# Choose workflow based on opts.flow
	if opts.flow == FlowStandard
		if !opts.nooutput
			println("Using NEW optimized parameter estimation flow")
		end
		results_tuple = optimized_multishot_parameter_estimation(PEP, opts)
	elseif opts.flow == FlowDirectOpt
		if !opts.nooutput
			println("Using direct optimization workflow (BFGS)")
		end
		# Align return signature with other workflows: (solutions, unident_dict, trivial_dict, all_unidentifiable)
		local direct_results = direct_optimization_parameter_estimation(PEP; opts = opts)
		results_tuple = (direct_results, Dict(), Dict(), [])
	else
		error("Unknown EstimationFlow: $(opts.flow)")
	end
	solved_res, unident_dict, trivial_dict, all_unidentifiable = results_tuple

	if !opts.nooutput
		println("\nUnidentifiability analysis from the algebraic estimation workflow:")
		println("All unidentifiable variables: ", all_unidentifiable)
		println("Unidentifiable variables substitution dictionary: ", unident_dict)
		println("Trivially solvable variables: ", trivial_dict)
	end

	results_tuple_to_return = analyze_estimation_result(PEP, solved_res, nooutput = opts.nooutput, opts = opts)

	uq_result = _compute_uq_result(PEP, solved_res, opts)

	return results_tuple, results_tuple_to_return, uq_result

end
