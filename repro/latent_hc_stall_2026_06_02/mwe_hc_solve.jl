#!/usr/bin/env julia
# MWE — does HC.jl stall on the latent_subpopulation_branch symmetric system?
#
# Loads a polynomial system dumped by ODEPE's `save_poly_system`, rebuilds the HC.jl
# System exactly as the production pipeline does (`convert_to_hc_format`), solves it
# VERBOSE, and reports the path-result breakdown + wall time.
#
# THE DIAGNOSTIC is the return-code mix:
#   :success      — path converged to a finite solution
#   :at_infinity  — path diverged to infinity (deficient/non-generic target → many of these)
#   :terminated   — tracker GAVE UP (step size collapsed — the stall signature)
# A flood of :at_infinity / :terminated on the symmetric system, vs clean :success on the
# generic one, would confirm "exactly-symmetric target stalls the polyhedral tracker".
#
# Usage:  julia --startup-file=no mwe_hc_solve.jl <dumped_system.jl>
# Wrap in `timeout` — the symmetric system is EXPECTED to stall (no RESULT line = stalled).

using Pkg
Pkg.activate(raw"/home/orebas/ParameterEstimationBenchmark-local/environments/julia_odepe")
using MKL
using ODEParameterEstimation
using HomotopyContinuation
const HC = HomotopyContinuation
using Symbolics, StaticArrays

length(ARGS) >= 1 || error("usage: julia --startup-file=no mwe_hc_solve.jl <dumped_system.jl>")
sysfile = ARGS[1]
println("Loading dumped system: ", sysfile)
include(sysfile)            # defines `varlist` and `poly_system` (save_poly_system format)
println("  $(length(poly_system)) equations, $(length(varlist)) variables")

# Rebuild the HC system the SAME way ODEPE does — this is the exact object the pipeline solves.
hc_system, hc_vars = ODEParameterEstimation.convert_to_hc_format(poly_system, varlist)
println("  HC system: $(length(hc_system.expressions)) expressions, $(length(hc_vars)) variables")

println("\n=== HC.solve  (show_progress = true) ===")
flush(stdout)
t0 = time()
result = HC.solve(hc_system; show_progress = true)
elapsed = time() - t0

# --- Path-result breakdown by return code: THE diagnostic ---
prs = HC.path_results(result)
codes = Dict{Symbol, Int}()
for pr in prs
    c = pr.return_code
    codes[c] = get(codes, c, 0) + 1
end
println("\n=== RESULT  ($(round(elapsed, digits = 1)) s) ===")
println("paths tracked : ", length(prs))
for (k, v) in sort(collect(codes), by = x -> -x[2])
    println("  return_code :$(k)  → $v")
end
println("nsolutions    : ", HC.nsolutions(result))
println("nreal         : ", HC.nreal(result))
try; println("nsingular     : ", HC.nsingular(result)); catch; end
try; println("nat_infinity  : ", HC.nat_infinity(result)); catch; end
println("\n(If this RESULT block printed, HC.solve RETURNED. A stall = no RESULT before the timeout fires.)")
