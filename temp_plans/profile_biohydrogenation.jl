# Deep Sub-Phase Allocation Profiling for Biohydrogenation
#
# This script instruments individual sub-functions within each major phase
# of the parameter estimation pipeline, using the SAME production settings
# as run_examples.jl (datasize=2001, InterpolatorAGPRobust, SolverHC, etc.)
#
# Usage:
#   julia temp_plans/profile_biohydrogenation.jl
#
# The script:
#   1. Loads the biohydrogenation model with production settings
#   2. Runs a warmup pass (full pipeline via analyze_parameter_estimation_problem)
#   3. Runs a measured pass calling internal sub-functions directly with @timed
#   4. Prints a two-level table showing time + allocations per sub-phase
#
# Why biohydrogenation?
#   - 4 states, 6 parameters, 2 observables (medium complexity)
#   - Non-polynomial ODEs (Michaelis-Menten rational functions)
#   - Denominator clearing creates larger polynomial systems
#   - Good stress test for GP interpolation with 2001 points

using Printf

# ─── Configuration (matches run_examples.jl exactly) ─────────────────
const DATASIZE        = 2001
const INTERPOLATOR    = :InterpolatorAGPRobust
const SOLVER          = :SolverHC
const NOISE_LEVEL     = 0.0
const SHOOTING_POINTS = 8
const TRY_MORE        = false   # Set false to profile ONE pipeline pass only
# ──────────────────────────────────────────────────────────────────────

println("="^70)
println("  Deep Sub-Phase Profiling: Biohydrogenation")
println("  Settings: datasize=$DATASIZE, interpolator=$INTERPOLATOR")
println("="^70)

println("\nLoading ODEParameterEstimation...")
t_load = @elapsed begin
	using ODEParameterEstimation
	include(joinpath(@__DIR__, "..", "src", "examples", "load_examples.jl"))
end
@printf("Package loaded in %.1f s\n", t_load)

# Access Symbolics and OrderedCollections through ODEParameterEstimation's module
const Symbolics = ODEParameterEstimation.Symbolics
const OrderedCollections = ODEParameterEstimation.OrderedCollections

# ─── Helper: format bytes as human-readable string ───────────────────
function fmt_bytes(bytes::Number)
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

# ─── Helper: pretty-print the two-level profiling table ──────────────
struct PhaseResult
	name::String
	time::Float64
	bytes::Int64
	gctime::Float64
	children::Vector{PhaseResult}
end

PhaseResult(name, time, bytes, gctime) = PhaseResult(name, time, bytes, gctime, PhaseResult[])

function print_profile_table(phases::Vector{PhaseResult})
	total_time  = sum(p.time  for p in phases)
	total_bytes = sum(p.bytes for p in phases)
	total_gc    = sum(p.gctime for p in phases)

	name_w = 55

	println()
	println("╔", "═"^name_w, "╤══════════╤═════════════╤═══════╗")
	@printf("║ %-*s│ %8s │ %11s │ %5s ║\n", name_w - 1, "Phase / Sub-phase", "Time (s)", "Allocs", "GC %")
	println("╠", "═"^name_w, "╪══════════╪═════════════╪═══════╣")

	for (i, phase) in enumerate(phases)
		gc_pct = phase.time > 0 ? 100.0 * phase.gctime / phase.time : 0.0
		label = "$i. $(phase.name)"
		@printf("║ %-*s│ %8.2f │ %11s │ %4.1f%% ║\n",
			name_w - 1, label, phase.time, fmt_bytes(phase.bytes), gc_pct)

		for (j, child) in enumerate(phase.children)
			child_gc = child.time > 0 ? 100.0 * child.gctime / child.time : 0.0
			child_label = "   $(i)$(Char('a' + j - 1)). $(child.name)"
			@printf("║ %-*s│ %8.2f │ %11s │ %4.1f%% ║\n",
				name_w - 1, child_label, child.time, fmt_bytes(child.bytes), child_gc)
		end
	end

	gc_pct_total = total_time > 0 ? 100.0 * total_gc / total_time : 0.0
	println("╠", "═"^name_w, "╪══════════╪═════════════╪═══════╣")
	@printf("║ %-*s│ %8.2f │ %11s │ %4.1f%% ║\n",
		name_w - 1, "TOTAL", total_time, fmt_bytes(total_bytes), gc_pct_total)
	println("╚", "═"^name_w, "╧══════════╧═════════════╧═══════╝")
end

# ─── Set up the problem ──────────────────────────────────────────────
println("\nSetting up biohydrogenation model...")
pep_raw = biohydrogenation()

solver_enum = getfield(ODEParameterEstimation, SOLVER)
interp_enum = getfield(ODEParameterEstimation, INTERPOLATOR)

opts = EstimationOptions(
	datasize             = DATASIZE,
	noise_level          = NOISE_LEVEL,
	system_solver        = solver_enum,
	flow                 = FlowStandard,
	use_si_template      = true,
	polish_solver_solutions = true,
	polish_solutions     = false,
	polish_maxiters      = 50,
	polish_method        = PolishLBFGS,
	opt_ad_backend       = :enzyme,
	interpolator         = interp_enum,
	diagnostics          = false,
	nooutput             = true,
	try_more_methods     = TRY_MORE,
	profile_phases       = false,   # We do our own profiling below
	shooting_points      = SHOOTING_POINTS,
	save_system          = false,
)

# Sample data (ODE solve to generate synthetic observations)
println("Sampling problem data (ODE solve)...")
t_sample = @timed begin
	pep = sample_problem_data(pep_raw, opts)
end
@printf("  Data sampled in %.2f s (%.1f MiB)\n", t_sample.time, t_sample.bytes / 1024^2)

# ─── Warmup pass (full pipeline, compiles everything) ────────────────
println("\n", "="^70)
println("  WARMUP PASS (compiling)")
println("="^70)

# Use small datasize for warmup to speed up compilation
opts_warmup = ODEParameterEstimation.merge_options(opts,
	datasize = 101,
	shooting_points = 1,
	try_more_methods = false,
	nooutput = true,
)
pep_warmup = sample_problem_data(pep_raw, opts_warmup)

t_warmup = @elapsed begin
	try
		analyze_parameter_estimation_problem(pep_warmup, opts_warmup)
	catch e
		@warn "Warmup pass encountered error (may be expected): $(typeof(e))"
	end
end
@printf("Warmup completed in %.1f s\n", t_warmup)
GC.gc()

# ─── Measured pass: granular sub-phase profiling ─────────────────────
println("\n", "="^70)
println("  MEASURED PASS (production settings)")
println("  datasize=$DATASIZE, interpolator=$INTERPOLATOR, solver=$SOLVER")
println("="^70)

# Get internal function references
const PE = ODEParameterEstimation

# Resolve interpolator and solver functions
interpolator_func = PE.get_interpolator_function(opts.interpolator, opts.custom_interpolator)
system_solver_func = PE.get_solver_function(opts.system_solver)
polish_method_func = PE.get_polish_optimizer(opts.polish_method)

# ─────────────────────────────────────────────────────────────────────
# PHASE 1: Setup (identifiability + interpolants)
# ─────────────────────────────────────────────────────────────────────
println("\n--- Phase 1: Setup ---")

# Extract model components
t_var, eqns, states, params = PE.unpack_ODE(pep.model.system)
t_vector = pep.data_sample["t"]

# 1a. Create interpolants
print("  1a. create_interpolants...")
r_1a = @timed begin
	interpolants = PE.create_interpolants(
		pep.measured_quantities, pep.data_sample, t_vector, interpolator_func
	)
end
@printf(" %.2f s, %s\n", r_1a.time, fmt_bytes(r_1a.bytes))

# 1b. Determine optimal points count (calls multipoint_local_identifiability_analysis)
num_points_cap = min(length(params), 1, length(t_vector))
print("  1b. determine_optimal_points_count...")
r_1b = @timed begin
	good_num_points, good_deriv_level, good_udict, good_varlist, good_DD =
		PE.determine_optimal_points_count(
			pep.model.system, pep.measured_quantities, num_points_cap, t_vector, true
		)
end
@printf(" %.2f s, %s\n", r_1b.time, fmt_bytes(r_1b.bytes))

# 1c. Pick shooting points
print("  1c. pick_points...")
r_1c = @timed begin
	time_index_set = PE.pick_points(t_vector, good_num_points, interpolants, 0.5)
end
@printf(" %.2f s, %s\n", r_1c.time, fmt_bytes(r_1c.bytes))

phase1 = PhaseResult("Setup (identifiability + interpolants)",
	r_1a.time + r_1b.time + r_1c.time,
	r_1a.bytes + r_1b.bytes + r_1c.bytes,
	r_1a.gctime + r_1b.gctime + r_1c.gctime,
	[
		PhaseResult("create_interpolants", r_1a.time, r_1a.bytes, r_1a.gctime),
		PhaseResult("determine_optimal_points_count", r_1b.time, r_1b.bytes, r_1b.gctime),
		PhaseResult("pick_points", r_1c.time, r_1c.bytes, r_1c.gctime),
	])

# ─────────────────────────────────────────────────────────────────────
# PHASE 2: SI Template (SIAN analysis + iterative fixing)
# ─────────────────────────────────────────────────────────────────────
println("\n--- Phase 2: SI Template ---")

ordered_model = isa(pep.model.system, PE.OrderedODESystem) ?
	pep.model.system :
	PE.OrderedODESystem(pep.model.system, states, params)

# 2a. First call to get_si_equation_system (initial template)
pre_fixed_params = OrderedDict{Any, Float64}()
print("  2a. get_si_equation_system (initial)...")
r_2a = @timed begin
	template_equations, derivative_dict, unidentifiable, identifiable_funcs = PE.get_si_equation_system(
		ordered_model,
		pep.measured_quantities,
		pep.data_sample;
		DD = good_DD,
		infolevel = 0,
		pre_fixed_params = pre_fixed_params,
	)
end
@printf(" %.2f s, %s\n", r_2a.time, fmt_bytes(r_2a.bytes))

# 2b. Iterative fix loop (DOF analysis + repeated SIAN calls if needed)
print("  2b. iterative_fix_loop...")
r_2b = @timed begin
	local si_template_local = (
		equations = template_equations,
		deriv_dict = derivative_dict,
		unidentifiable = unidentifiable,
		identifiable_funcs = identifiable_funcs,
	)

	# Replicate the iterative fixing logic from optimized_multishot_estimation.jl
	local max_fix_iterations = 10
	local iteration_count = 0
	local is_converged = false
	local template_eqs_local = template_equations

	while iteration_count < max_fix_iterations && !is_converged
		iteration_count += 1

		local n_equations = length(si_template_local.equations)
		local vars_in_system = OrderedCollections.OrderedSet{Any}()
		for eq in si_template_local.equations
			union!(vars_in_system, Symbolics.get_variables(eq))
		end

		# Build set of observable derivative variables from DD
		local obs_data_vars = Set{Any}()
		if !isnothing(good_DD)
			for level in good_DD.obs_lhs
				for v in level
					push!(obs_data_vars, v)
				end
			end
		end

		local unknown_vars = OrderedCollections.OrderedSet{Any}()
		for v in vars_in_system
			if !(v in obs_data_vars)
				push!(unknown_vars, v)
			end
		end
		local n_variables = length(unknown_vars)

		if n_equations == n_variables
			is_converged = true
		elseif n_equations < n_variables
			# Underdetermined — fix one parameter
			local already_fixed = Set(keys(pre_fixed_params))
			local param_to_fix, fix_value = PE.select_one_parameter_to_fix(
				si_template_local, already_fixed, false; states = states
			)
			if param_to_fix === nothing
				break
			end
			pre_fixed_params[param_to_fix] = fix_value

			# Re-run SIAN with fixed parameter
			local te_new, dd_new, ui_new, if_new =
				PE.get_si_equation_system(
					ordered_model,
					pep.measured_quantities,
					pep.data_sample;
					DD = good_DD,
					infolevel = 0,
					pre_fixed_params = pre_fixed_params,
				)
			si_template_local = (
				equations = te_new,
				deriv_dict = dd_new,
				unidentifiable = ui_new,
				identifiable_funcs = if_new,
			)
			template_eqs_local = te_new
		else
			break  # Overdetermined
		end
	end
	# Export results from the block
	(si_template_local, template_eqs_local, iteration_count)
end
# Unpack results from iterative fix block
si_template, template_equations, fix_iterations = r_2b.value
@printf(" %.2f s, %s (%d iterations)\n", r_2b.time, fmt_bytes(r_2b.bytes), fix_iterations)

phase2 = PhaseResult("SI Template (SIAN analysis)",
	r_2a.time + r_2b.time,
	r_2a.bytes + r_2b.bytes,
	r_2a.gctime + r_2b.gctime,
	[
		PhaseResult("get_si_equation_system (initial)", r_2a.time, r_2a.bytes, r_2a.gctime),
		PhaseResult("iterative_fix_loop", r_2b.time, r_2b.bytes, r_2b.gctime),
	])

# ─────────────────────────────────────────────────────────────────────
# PHASE 3: Equation Construction + Solving at shooting points
# ─────────────────────────────────────────────────────────────────────
println("\n--- Phase 3: Equation Construction + Solving ---")

# Select shooting points (replicating pipeline logic)
if opts.shooting_points == 0
	mid = max(1, min(length(t_vector), round(Int, 0.499 * length(t_vector))))
	point_indices = [mid]
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

println("  Shooting points: $(length(point_indices)) points")

# 3a. Construct equation systems at all shooting points
all_solutions = []
all_hc_vars = []
all_trivial_dicts = []
all_trimmed_vars = []
all_forward_subst_dicts = []
all_reverse_subst_dicts = []
all_final_varlists = []
solution_time_indices = Int[]

r_3a_total_time = 0.0
r_3a_total_bytes = 0
r_3a_total_gc = 0.0
r_3b_total_time = 0.0
r_3b_total_bytes = 0
r_3b_total_gc = 0.0
r_3c_total_time = 0.0
r_3c_total_bytes = 0
r_3c_total_gc = 0.0

for (pt_num, point_idx) in enumerate(point_indices)
	global r_3a_total_time, r_3a_total_bytes, r_3a_total_gc
	global r_3b_total_time, r_3b_total_bytes, r_3b_total_gc
	global r_3c_total_time, r_3c_total_bytes, r_3c_total_gc
	global all_solutions, all_hc_vars, all_trivial_dicts, all_trimmed_vars
	global all_forward_subst_dicts, all_reverse_subst_dicts, all_final_varlists

	# 3a. construct_equation_system_from_si_template
	r_construct = @timed begin
		target_k, varlist_k = PE.construct_equation_system_from_si_template(
			pep.model.system,
			pep.measured_quantities,
			pep.data_sample,
			good_deriv_level,
			good_udict,
			good_varlist,
			good_DD;
			interpolator = interpolator_func,
			time_index_set = [point_idx],
			precomputed_interpolants = interpolants,
			diagnostics = false,
			si_template = si_template,
		)
	end
	r_3a_total_time += r_construct.time
	r_3a_total_bytes += r_construct.bytes
	r_3a_total_gc += r_construct.gctime

	final_target = target_k
	final_varlist = varlist_k

	# 3b. System solver (HomotopyContinuation.solve)
	r_solve = @timed begin
		solver_options = Dict(
			:debug_solver => false,
			:debug_cas_diagnostics => false,
			:debug_dimensional_analysis => false,
		)
		solutions_k, hc_vars_k, trivial_dict_k, trimmed_vars_k =
			system_solver_func(final_target, final_varlist; options = solver_options)
	end
	r_3b_total_time += r_solve.time
	r_3b_total_bytes += r_solve.bytes
	r_3b_total_gc += r_solve.gctime

	# 3c. Polish raw solver solutions (solve_with_robust, polish_only=true)
	r_polish = @timed begin
		if opts.polish_solver_solutions && !isempty(solutions_k)
			polished_point = Vector{Vector{Float64}}()
			for sol in solutions_k
				start_pt = real.(sol)
				p_sols, _, _, _ = PE.solve_with_robust(
					final_target, final_varlist;
					start_point = start_pt,
					polish_only = true,
					options = Dict(:abstol => 1e-12, :reltol => 1e-12, :debug => false),
				)
				if !isempty(p_sols)
					push!(polished_point, p_sols[1])
				else
					push!(polished_point, sol)
				end
			end
			solutions_k = polished_point
		end
	end
	r_3c_total_time += r_polish.time
	r_3c_total_bytes += r_polish.bytes
	r_3c_total_gc += r_polish.gctime

	# Accumulate solutions
	append!(all_solutions, solutions_k)
	for _ in 1:length(solutions_k)
		push!(solution_time_indices, point_idx)
	end
	all_hc_vars = hc_vars_k
	push!(all_trivial_dicts, trivial_dict_k)
	push!(all_forward_subst_dicts, OrderedDict{Symbolics.Num, Any}())
	push!(all_reverse_subst_dicts, OrderedDict{Any, Symbolics.Num}())
	all_trimmed_vars = trimmed_vars_k
	all_final_varlists = final_varlist

	if pt_num <= 3 || pt_num == length(point_indices)
		@printf("    Point %d/%d (t=%.2f): construct=%.2fs, solve=%.2fs, polish=%.2fs | %d solutions\n",
			pt_num, length(point_indices), t_vector[point_idx],
			r_construct.time, r_solve.time, r_polish.time, length(solutions_k))
	elseif pt_num == 4
		println("    ... (remaining points omitted) ...")
	end
end

@printf("  3a total: construct_equation_system  %.2f s, %s\n", r_3a_total_time, fmt_bytes(r_3a_total_bytes))
@printf("  3b total: system_solver (HC.solve)   %.2f s, %s\n", r_3b_total_time, fmt_bytes(r_3b_total_bytes))
@printf("  3c total: polish (solve_with_robust) %.2f s, %s\n", r_3c_total_time, fmt_bytes(r_3c_total_bytes))

phase3 = PhaseResult("Equation construction + Solving",
	r_3a_total_time + r_3b_total_time + r_3c_total_time,
	r_3a_total_bytes + r_3b_total_bytes + r_3c_total_bytes,
	r_3a_total_gc + r_3b_total_gc + r_3c_total_gc,
	[
		PhaseResult("construct_equation_system (×$(length(point_indices)))", r_3a_total_time, r_3a_total_bytes, r_3a_total_gc),
		PhaseResult("system_solver / HC.solve (×$(length(point_indices)))", r_3b_total_time, r_3b_total_bytes, r_3b_total_gc),
		PhaseResult("polish / solve_with_robust (×$(length(point_indices)))", r_3c_total_time, r_3c_total_bytes, r_3c_total_gc),
	])

# ─────────────────────────────────────────────────────────────────────
# PHASE 4: Result Processing (ODE backward integration, clustering)
# ─────────────────────────────────────────────────────────────────────
println("\n--- Phase 4: Result Processing ---")

# Build setup_data named tuple (replicating what setup_parameter_estimation returns)
setup_data = (
	states = states,
	params = params,
	t_vector = t_vector,
	interpolants = interpolants,
	good_num_points = good_num_points,
	good_deriv_level = good_deriv_level,
	good_udict = good_udict,
	good_varlist = good_varlist,
	good_DD = good_DD,
	time_index_set = time_index_set,
	all_unidentifiable = good_DD.all_unidentifiable,
)

# Build solution_data named tuple
solutions = all_solutions
hc_vars = all_hc_vars
trivial_dict = isempty(all_trivial_dicts) ? OrderedDict() : merge(all_trivial_dicts...)
trimmed_vars = all_trimmed_vars
forward_subst_dict = isempty(all_forward_subst_dicts) ? [OrderedDict{Symbolics.Num, Any}()] : [all_forward_subst_dicts[1]]
reverse_subst_dict = isempty(all_reverse_subst_dicts) ? [OrderedDict{Any, Symbolics.Num}()] : [all_reverse_subst_dicts[1]]
final_varlist = all_final_varlists

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

println("  $(length(solutions)) solutions to process")

# 4a. process_estimation_results (includes ODE backward integration)
print("  4a. process_estimation_results...")
r_4a = @timed begin
	solved_res = PE.process_estimation_results(
		pep,
		solution_data,
		setup_data;
		nooutput = true,
		polish_solutions = opts.polish_solutions,
		polish_maxiters = opts.polish_maxiters,
		polish_method = polish_method_func,
	)
end
@printf(" %.2f s, %s\n", r_4a.time, fmt_bytes(r_4a.bytes))

# 4b. analyze_estimation_result (clustering / scoring)
print("  4b. analyze_estimation_result...")
r_4b = @timed begin
	if !isempty(solved_res)
		results_tuple = PE.analyze_estimation_result(pep, solved_res, nooutput = true)
	end
end
@printf(" %.2f s, %s\n", r_4b.time, fmt_bytes(r_4b.bytes))

phase4 = PhaseResult("Result processing",
	r_4a.time + r_4b.time,
	r_4a.bytes + r_4b.bytes,
	r_4a.gctime + r_4b.gctime,
	[
		PhaseResult("process_estimation_results (ODE solve)", r_4a.time, r_4a.bytes, r_4a.gctime),
		PhaseResult("analyze_estimation_result (scoring)", r_4b.time, r_4b.bytes, r_4b.gctime),
	])

# ─────────────────────────────────────────────────────────────────────
# Print the combined two-level profiling table
# ─────────────────────────────────────────────────────────────────────
println("\n", "="^70)
println("  PROFILING RESULTS: Biohydrogenation (datasize=$DATASIZE)")
println("="^70)

phases = [phase1, phase2, phase3, phase4]
print_profile_table(phases)

# ─── Additional diagnostics ──────────────────────────────────────────
println("\n--- Additional Info ---")
println("  Model: biohydrogenation (4 states, 6 params, 2 obs)")
println("  Data points: $DATASIZE")
println("  Shooting points: $(length(point_indices))")
println("  Solutions found: $(length(solutions))")
println("  Solutions after processing: $(length(solved_res))")
println("  Interpolator: $INTERPOLATOR")
println("  Solver: $SOLVER")
println("  try_more_methods: $TRY_MORE (set false to avoid double pipeline)")
println()

# ─── Memory breakdown summary ────────────────────────────────────────
println("--- Allocation Breakdown Summary ---")
total_bytes = sum(p.bytes for p in phases)
for (i, p) in enumerate(phases)
	pct = total_bytes > 0 ? 100.0 * p.bytes / total_bytes : 0.0
	@printf("  Phase %d: %-45s %5.1f%%  %s\n", i, p.name, pct, fmt_bytes(p.bytes))
	for child in p.children
		child_pct = total_bytes > 0 ? 100.0 * child.bytes / total_bytes : 0.0
		@printf("           %-45s %5.1f%%  %s\n", child.name, child_pct, fmt_bytes(child.bytes))
	end
end
@printf("  %-47s        %s\n", "TOTAL", fmt_bytes(total_bytes))
println()

# ─── Compare: what would double pipeline cost? ───────────────────────
println("--- Double Pipeline Impact (try_more_methods=true) ---")
@printf("  Single pipeline total:  %s\n", fmt_bytes(total_bytes))
@printf("  Estimated double:       %s  (×2 for AAAD fallback pass)\n", fmt_bytes(2 * total_bytes))
println("  Recommendation: Set try_more_methods=false if first pass succeeds")
println()
println("Done.")
