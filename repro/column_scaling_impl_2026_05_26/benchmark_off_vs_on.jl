# Broad do-no-harm + candidate-SET check for column scaling ON-by-default, on systems beyond the
# fast regression suite. For each system: sample once (noise=0), solve OFF and ON on the SAME data.
# Report: best_max OFF vs ON (flag any system ON makes WORSE = recovery regression), candidate
# counts, and SET similarity = max over ON candidates of the nearest-neighbor relative distance to
# an OFF candidate (small ⇒ off/on find the same points, not just the same count).
#
# Run:  julia --startup-file=no repro/column_scaling_impl_2026_05_26/benchmark_off_vs_on.jl
using ODEParameterEstimation, Printf, Statistics, Random
const OPE = ODEParameterEstimation
include(joinpath(@__DIR__, "..", "..", "src", "examples", "load_examples.jl"))
const OUT = joinpath(@__DIR__, "benchmark_off_vs_on.csv")

mkopts(cs) = EstimationOptions(
	datasize = 201, noise_level = 0.0, system_solver = SolverHC, flow = FlowStandard,
	interpolator = InterpolatorAAAD, auto_filter_interpolators = false, use_si_template = true,
	use_parameter_homotopy = true, use_multipoint = false, use_column_scaling = cs,
	shooting_points = 4, polish_solver_solutions = false, polish_solutions = false,
	nooutput = true, diagnostics = false)

function solve_set(sampled, opts)
	res, _, _ = analyze_parameter_estimation_problem(deepcopy(sampled), opts)
	cands = res[1]; best = Inf; vecs = Vector{Vector{Float64}}()
	for c in cands
		s = try OPE.oracle_error_stats(sampled, c) catch; nothing end
		s !== nothing && (best = min(best, s.maximum))
		ks = sort(collect(keys(c.parameters)), by = string)
		v = Float64[Float64(c.parameters[k]) for k in ks]
		all(isfinite, v) && push!(vecs, v)
	end
	(best = isfinite(best) ? best : NaN, n = length(cands), vecs = vecs)
end

# max over A of (min relative-L∞ distance to B): is every A-candidate near some B-candidate?
function set_delta(A, B)
	(isempty(A) || isempty(B)) && return NaN
	mx = 0.0
	for a in A
		d = Inf
		for b in B
			length(b) == length(a) || continue
			d = min(d, maximum(abs.(a .- b) ./ max.(abs.(b), 1e-9)))
		end
		mx = max(mx, d)
	end
	mx
end

function run_sys(io, sym)
	pep = ALL_MODELS[sym]()
	Random.seed!(20260527)
	sampled = sample_problem_data(pep, mkopts(false))
	off = solve_set(sampled, mkopts(false))
	on  = solve_set(sampled, mkopts(true))
	sd = set_delta(on.vecs, off.vecs)
	worse = isfinite(on.best) && isfinite(off.best) && on.best > 10 * max(off.best, 1e-12)
	@printf("%-22s | OFF best=%.2e n=%-3d | ON best=%.2e n=%-3d | set-Δ=%.1e %s\n",
		sym, off.best, off.n, on.best, on.n, sd, worse ? "  <== ON WORSE (regression?)" : ""); flush(stdout)
	@printf(io, "%s,%.3e,%d,%.3e,%d,%.3e,%d\n", sym, off.best, off.n, on.best, on.n, sd, worse ? 1 : 0)
end

function main()
	systems = [:simple, :lotka_volterra, :vanderpol, :harmonic, :daisy_mamil3,
			   :slowfast, :daisy_mamil4, :seir, :biohydrogenation]
	open(OUT, "w") do io
		println(io, "system,off_best,off_n,on_best,on_n,set_delta,on_worse")
		println("=== column scaling OFF vs ON — recovery + candidate-set similarity (noise=0, same data) ===")
		println(repeat("-", 92)); flush(stdout)
		for s in systems
			try run_sys(io, s) catch e; println("$s ERROR: ", sprint(showerror, e)[1:min(110,end)]); flush(stdout) end
		end
	end
	println("\nwrote ", OUT)
end

main()
