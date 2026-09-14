"""
    PreparedRobustSystem

Residual and Jacobian kernels for one polynomial structure. Numerical observation
data are runtime arguments, so changing a shooting point does not generate a new
function. Kernels contain no mutable evaluation buffers; each solve owns its
ForwardDiff/finite-difference workspace.
"""
struct PreparedRobustSystem{F, J}
	residual!::F
	jacobian!::J
	variables::Vector{Num}
	data_variables::Vector{Num}
	equation_count::Int
	jacobian_mode::Symbol
	forwarddiff_chunk_size::Int
	compiled_residual::Bool
end

"""
    prepare_robust_system(poly_system, varlist; data_vars=Num[], jacobian=:forwarddiff,
                         forwarddiff_chunk_size=1)

Prepare `F(z, d)` and its Jacobian with respect to `z`, keeping the data `d`
separate from the unknowns. Symbolic differentiation is performed once, with a
ForwardDiff fallback if symbolic Jacobian construction fails.

# Arguments
- `poly_system`: Equations in the ordered unknowns and optional data symbols.
- `varlist`: Ordered unknowns to solve for.
- `data_vars`: Ordered numerical-data symbols supplied at each solve.
- `jacobian`: `:symbolic`, `:forwarddiff`, `:finitediff`, or `:none`.
- `forwarddiff_chunk_size`: Number of AD directions; zero selects ForwardDiff's
  automatic chunk size.

# Returns
A reusable `PreparedRobustSystem`, passed to `solve_with_robust` through its
`prepared_system` keyword together with the current `data_values`.
"""
function prepare_robust_system(poly_system, varlist;
	data_vars = Num[], jacobian::Symbol = :forwarddiff,
	forwarddiff_chunk_size::Int = 1)
	jacobian in (:symbolic, :forwarddiff, :finitediff, :none) ||
		throw(ArgumentError("Unsupported polynomial Jacobian method: $jacobian"))
	forwarddiff_chunk_size >= 0 || throw(ArgumentError("forwarddiff_chunk_size must be nonnegative"))
	variables, data_variables = Num.(varlist), Num.(data_vars)
	# allunique's small-array fast path uses ==, which is symbolic for Num.
	length(Set(vcat(variables, data_variables))) == length(variables) + length(data_variables) ||
		throw(ArgumentError("Polynomial unknowns and data symbols must be distinct and individually unique"))
	equations = Num.(poly_system)
	compiled = true
	residual! = try
		Symbolics.build_function(equations, variables, data_variables; expression = Val(false))[2]
	catch err
		_rethrow_if_interrupt(err)
		@warn "build_function failed in prepare_robust_system; falling back to symbolic substitution" exception = (err, catch_backtrace())
		compiled = false
		(r, u, d) -> begin
			substitution = Dict{Num, eltype(u)}(zip(variables, u))
			for (v, value) in zip(data_variables, d)
				substitution[v] = value
			end
			for i in eachindex(equations)
				r[i] = Symbolics.value(Symbolics.substitute(equations[i], substitution))
			end
			nothing
		end
	end
	jacobian! = if jacobian == :symbolic
		try
			J = Symbolics.jacobian(equations, variables)
			Symbolics.build_function(J, variables, data_variables; expression = Val(false))[2]
		catch err
			_rethrow_if_interrupt(err)
			@warn "Symbolic polynomial Jacobian construction failed; using ForwardDiff" exception = (err, catch_backtrace())
			jacobian = :forwarddiff
			nothing
		end
	else
		nothing
	end
	return PreparedRobustSystem(residual!, jacobian!, variables, data_variables,
		length(equations), jacobian, forwarddiff_chunk_size, compiled)
end

"""Create a solve-local Jacobian callback and workspace for a prepared kernel."""
function _bind_robust_jacobian(system::PreparedRobustSystem, residual!, data_values)
	m, n = system.equation_count, length(system.variables)
	if system.jacobian_mode == :symbolic
		return (J, u) -> system.jacobian!(J, u, data_values)
	elseif system.jacobian_mode == :forwarddiff
		f! = (r, u) -> residual!(r, u)
		x, r = zeros(n), zeros(m)
		chunk = system.forwarddiff_chunk_size == 0 ? ForwardDiff.Chunk(x) :
			ForwardDiff.Chunk(n, min(n, system.forwarddiff_chunk_size))
		config = ForwardDiff.JacobianConfig(f!, r, x, chunk)
		return (J, u) -> ForwardDiff.jacobian!(J, f!, r, u, config)
	elseif system.jacobian_mode == :finitediff
		# The constructor takes unknowns first, residuals second (rectangular
		# least-squares systems need different buffer lengths).
		cache = FiniteDiff.JacobianCache(zeros(n), zeros(m))
		return (J, u) -> FiniteDiff.finite_difference_jacobian!(J, residual!, u, cache)
	end
	return nothing
end

"""Reuse a kernel within one estimation run, including symbol order in the key."""
function _cached_robust_system!(cache::AbstractDict, equations, variables, data_variables,
	opts::EstimationOptions)
	# Retain the full key so hash collisions cannot alias two different systems.
	key = (Tuple(Num.(equations)), Tuple(Num.(variables)), Tuple(Num.(data_variables)),
		opts.polish_solver_jacobian, opts.polish_solver_chunk_size)
	t0 = time()
	hit = haskey(cache, key)
	system = get!(cache, key) do
		prepare_robust_system(equations, variables; data_vars = data_variables,
			jacobian = opts.polish_solver_jacobian,
			forwarddiff_chunk_size = opts.polish_solver_chunk_size)
	end
	_record_detailed_timing!((category = :prepare_robust_system,
		context = _current_detailed_timing_context(), total_seconds = time() - t0,
		cache_hit = hit, equation_count = length(equations), variable_count = length(variables),
		data_variable_count = length(data_variables), jacobian = system.jacobian_mode))
	return system
end
