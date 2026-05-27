# Diagnose receptor: dump the candidate POOL (branch completion OFF, wide top_k)
# and check whether truth and the swap-sibling are recovered, vs garbage.
using ODEParameterEstimation
using Printf
const OPE = ODEParameterEstimation

pep = OPE.receptor_subtype_binding_branch()
nvars = length(pep.ic) + length(pep.p_true)
opts = EstimationOptions(
    datasize = 101, noise_level = 0.0,
    system_solver = SolverHC, flow = FlowStandard, use_si_template = true,
    interpolator = InterpolatorAAAD, interpolators = [InterpolatorAAAD],
    auto_filter_interpolators = false,
    shooting_points = 4, shooting_warp = true, shooting_warp_beta = 3.0,
    use_parameter_homotopy = true, use_multipoint = false,
    polish_solver_solutions = false, polish_solutions = false,
    synthesize_aggregate_candidates = false,
    terminal_fallback = :none, backsolve_recovery = :none,
    nooutput = true, diagnostics = false, save_system = false,
    branch_detection = true,
    algebraic_multiplicity = nothing,   # don't truncate to M
    branch_top_k = 30,                   # show a wide pool
    branch_completion = false,           # NO completion — just the normal pool
    opt_lb = fill(1e-5, nvars), opt_ub = fill(5000.0, nvars),
)

# expected solutions
truth = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
swap  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)
function matchlabel(p)
    d = Dict(string(k)=>v for (k,v) in p)
    closeto(ref) = all(abs(d[k]-ref[k]) < 0.05*max(abs(ref[k]),1.0) for k in keys(ref))
    closeto(truth) && return "  <-- TRUTH"
    closeto(swap)  && return "  <-- SWAP sibling"
    return ""
end

t0 = time()
spep = sample_problem_data(pep, opts)
out = analyze_parameter_estimation_problem(spep, opts)
rows = out[2].returned_results
@printf("\n[%.1fs] receptor pool: %d ranked candidates (branch_top_k=30)\n", time()-t0, length(rows))
println("TRUTH: ", truth)
println("SWAP : ", swap)
println("-"^60)
for (i,r) in enumerate(rows)
    erv = (r.err === nothing) ? NaN : r.err
    @printf("row %2d  err=%.3e%s\n", i, erv, matchlabel(r.parameters))
    println("   params: ", [(string(k), round(v,sigdigits=4)) for (k,v) in r.parameters])
    println("   states: ", [(string(k), round(v,sigdigits=4)) for (k,v) in r.states])
end
println("\nDONE")
