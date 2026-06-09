# Archived 2026-06-09 from src/core/analysis_utils.jl — NOT part of the build.
# _detect_branches + _branch_cluster_linf (post-polish 'branch' candidate reduction).
# Disabled for output in 2025-05 because it dropped the truth-near candidate in ~43%
# of regression cells (see git history of analysis_utils.jl). Kept for reference only;
# references package types/helpers (EstimationOptions, ParameterEstimationResult, etc.).

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
