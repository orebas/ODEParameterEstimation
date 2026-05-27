# Receptor solution-count full diagnosis. See plan: full breakdown of HC solutions
# (paths/at-infinity/finite/singular/real/complex) with TRUE (oracle) derivatives,
# generic count vs BKK, polyhedral vs parameter tracking, seed-location effect, and
# AAAD contrast. Long-running (~1-3h). All logic in functions (avoid soft-scope);
# explicit flush; per-experiment try/catch so partial results survive.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, Random, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation

const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

function setup_all()
    pep = OPE.receptor_subtype_binding_branch()
    opts = EstimationOptions(datasize=101, noise_level=0.0, use_si_template=true, nooutput=true)
    spep = sample_problem_data(pep, opts)
    setup = OPE.setup_parameter_estimation(spep; interpolator=OPE.aaad, nooutput=true)
    DD = setup.good_DD; mq = spep.measured_quantities; ds = spep.data_sample; tvec = ds["t"]
    model = spep.model
    omodel = model isa OPE.OrderedODESystem ? model : begin (t,meq,ms,mp)=OPE.unpack_ODE(model); OPE.OrderedODESystem(model,ms,mp) end
    te, dd, _, _, _, meta = OPE.get_si_equation_system(omodel, mq, ds; DD=DD, infolevel=0)
    tdd = OPE.ensure_si_template_dd_support(omodel, mq, DD, dd)
    data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
    all_vars=[]; seen=Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(all_vars,v); push!(seen,v); end; end
    solve_vars = [v for v in all_vars if !(v in dset)]
    hc_system, hc_vars, hc_params = OPE.convert_to_hc_format_with_params(te, solve_vars, data_vars)
    return (; spep, mq, ds, tvec, tdd, dd, te, meta, data_vars, solve_vars, hc_system, hc_params, svname=string.(solve_vars))
end

function oracle_params(S, t; maxorder=12)
    # Exact (oracle) derivative jet at t: build PerfectInterpolants (centered at t)
    # and run them through the SAME evaluator the AAAD path uses (function-form
    # nth_deriv, keyed by diff2term(rhs)) -> exact derivative values in data_vars order.
    perf = OPE.build_perfect_interpolants(S.spep, Float64(t), maxorder)
    OPE.evaluate_data_vars_at_point(perf, S.data_vars, S.tdd, S.mq, Float64(t))
end

function bd(res)
    allfin  = HC.solutions(res; only_nonsingular=false, only_finite=true)
    realfin = HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
    (paths=HC.ntracked(res), atinf=HC.nat_infinity(res), finite=length(allfin),
     singular=HC.nsingular(res), real=length(realfin), complex=length(allfin)-length(realfin), realsols=realfin)
end
gi(S,s,b) = (i=findfirst(n->n==b||n==b*"_0", S.svname); i===nothing ? NaN : real(s[i]))
function hit(S, realsols)
    t=false; sw=false
    for x in realsols
        d=Dict(k=>gi(S,x,k) for k in keys(TRUTH))
        all(isfinite(d[k]) && abs(d[k]-TRUTH[k])<0.05*max(abs(TRUTH[k]),1) for k in keys(TRUTH)) && (t=true)
        all(isfinite(d[k]) && abs(d[k]-SWAP[k]) <0.05*max(abs(SWAP[k]),1)  for k in keys(SWAP))  && (sw=true)
    end
    (t ? "TRUTH " : "")*(sw ? "SWAP" : "")
end

function expA(S)
    println("\n##### EXP A: generic solution count vs BKK bound #####"); flush(stdout)
    @printf("mixed_volume (BKK torus)   = %d\n", HC.mixed_volume(S.hc_system)); flush(stdout)
    try @printf("paths_to_track(polyhedral) = %d\n", HC.paths_to_track(S.hc_system; start_system=:polyhedral)) catch e; println("paths poly err: $e") end; flush(stdout)
    try @printf("paths_to_track(total_deg)  = %d\n", HC.paths_to_track(S.hc_system; start_system=:total_degree)) catch e; println("paths totaldeg err: $e") end; flush(stdout)
    for seed in 1:3
        Random.seed!(1000+seed); p = randn(ComplexF64, length(S.hc_params))
        res = HC.solve(S.hc_system; target_parameters=p, show_progress=false); b=bd(res)
        @printf("random-complex #%d: paths=%d  at_infinity=%d  FINITE=%d (singular=%d)  real=%d  complex=%d\n",
            seed, b.paths, b.atinf, b.finite, b.singular, b.real, b.complex); flush(stdout)
    end
end

function expB(S)
    println("\n##### EXP B: ORACLE data at t=0, full breakdown #####"); flush(stdout)
    p = oracle_params(S, 0.0)
    res = HC.solve(S.hc_system; target_parameters=p, show_progress=false); b=bd(res)
    @printf("t=0 ORACLE: paths=%d  at_infinity=%d  FINITE=%d (singular=%d)  real=%d  complex=%d  | %s\n",
        b.paths, b.atinf, b.finite, b.singular, b.real, b.complex, hit(S,b.realsols)); flush(stdout)
    for x in b.realsols
        d=Dict(k=>gi(S,x,k) for k in keys(TRUTH))
        if all(isfinite(d[k]) && abs(d[k]-TRUTH[k])<0.05*max(abs(TRUTH[k]),1) for k in keys(TRUTH)) ||
           all(isfinite(d[k]) && abs(d[k]-SWAP[k]) <0.05*max(abs(SWAP[k]),1)  for k in keys(SWAP))
            println("   physical root: ", Dict(k=>round(d[k],digits=4) for k in keys(d))); flush(stdout)
        end
    end
end

function expC(S, grid)
    println("\n##### EXP C: ORACLE-data scan across t (fresh polyhedral per point) #####"); flush(stdout)
    @printf("%6s %6s %6s %6s %5s %5s %6s  %s\n","t","paths","atinf","FINITE","sing","real","cmplx","truth?"); flush(stdout)
    for t in grid
        try
            res = HC.solve(S.hc_system; target_parameters=oracle_params(S,t), show_progress=false); b=bd(res)
            @printf("%+6.2f %6d %6d %6d %5d %5d %6d  %s\n", t,b.paths,b.atinf,b.finite,b.singular,b.real,b.complex,hit(S,b.realsols)); flush(stdout)
        catch e; @printf("%+6.2f  ERROR %s\n", t, sprint(showerror,e)[1:min(60,end)]); flush(stdout) end
    end
end

function track_chain(S, seed_sols, seed_p, targets, label)
    @printf("  -- %s (%d start sols) --\n", label, length(seed_sols)); flush(stdout)
    prev = seed_sols; prevp = seed_p
    for (t,p) in targets
        try
            res = HC.solve(S.hc_system, prev; start_parameters=prevp, target_parameters=p, show_progress=false)
            af = HC.solutions(res; only_nonsingular=false, only_finite=true)
            rf = HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
            @printf("    t=%+5.2f  finite=%3d  real=%3d  %s\n", t, length(af), length(rf), hit(S,rf)); flush(stdout)
            prev = af; prevp = p
        catch e; @printf("    t=%+5.2f  ERROR %s\n", t, sprint(showerror,e)[1:min(45,end)]); flush(stdout) end
    end
end

function expD(S, grid)
    println("\n##### EXP D: ORACLE-data parameter tracking, 3 seeds #####"); flush(stdout)
    pvl = [(t, oracle_params(S,t)) for t in grid]
    mid = argmin(abs.(grid))
    s1 = HC.solutions(HC.solve(S.hc_system; target_parameters=pvl[1][2], show_progress=false); only_nonsingular=false, only_finite=true)
    track_chain(S, s1, pvl[1][2], pvl[2:end], "SEED t=$(grid[1]) -> rightward")
    sm = HC.solutions(HC.solve(S.hc_system; target_parameters=pvl[mid][2], show_progress=false); only_nonsingular=false, only_finite=true)
    track_chain(S, sm, pvl[mid][2], pvl[mid+1:end], "SEED t=$(grid[mid]) -> rightward")
    track_chain(S, sm, pvl[mid][2], reverse(pvl[1:mid-1]), "SEED t=$(grid[mid]) -> leftward")
    Random.seed!(42); gp = randn(ComplexF64, length(S.hc_params))
    sg = HC.solutions(HC.solve(S.hc_system; target_parameters=gp, show_progress=false); only_nonsingular=false, only_finite=true)
    @printf("  generic-complex seed: %d finite solutions\n", length(sg)); flush(stdout)
    rgm = HC.solve(S.hc_system, sg; start_parameters=gp, target_parameters=pvl[mid][2], show_progress=false)
    sgm = HC.solutions(rgm; only_nonsingular=false, only_finite=true)
    @printf("  generic -> t=%+.2f : finite=%d\n", grid[mid], length(sgm)); flush(stdout)
    track_chain(S, sgm, pvl[mid][2], pvl[mid+1:end], "GENERIC@t=$(grid[mid]) -> rightward")
    track_chain(S, sgm, pvl[mid][2], reverse(pvl[1:mid-1]), "GENERIC@t=$(grid[mid]) -> leftward")
end

function expE(S, grid)
    println("\n##### EXP E: AAAD contrast (interpolated data) #####"); flush(stdout)
    interps = OPE.create_interpolants(S.mq, S.ds, S.tvec, OPE.aaad)
    ap(t) = OPE.evaluate_data_vars_at_point(interps, S.data_vars, S.tdd, S.mq, Float64(t))
    println("  -- AAAD polyhedral scan --"); flush(stdout)
    @printf("  %6s %6s %5s %5s  %s\n","t","FINITE","sing","real","truth?"); flush(stdout)
    for t in grid
        try res = HC.solve(S.hc_system; target_parameters=ap(t), show_progress=false); b=bd(res)
            @printf("  %+6.2f %6d %5d %5d  %s\n", t,b.finite,b.singular,b.real,hit(S,b.realsols)); flush(stdout)
        catch e; @printf("  %+6.2f ERROR %s\n", t, sprint(showerror,e)[1:min(45,end)]); flush(stdout) end
    end
    pvl = [(t, ap(t)) for t in grid]
    s1 = HC.solutions(HC.solve(S.hc_system; target_parameters=pvl[1][2], show_progress=false); only_nonsingular=false, only_finite=true)
    track_chain(S, s1, pvl[1][2], pvl[2:end], "AAAD chain SEED t=$(grid[1]) -> rightward")
end

function main()
    println("=== RECEPTOR SOLUTION-COUNT DIAGNOSTIC ==="); flush(stdout)
    t0=time(); S = setup_all()
    @printf("setup (%.1fs): template %d eqs / %d solve_vars / %d data_vars ; full=%d dropped=%d M=%s\n",
        time()-t0, length(S.te), length(S.solve_vars), length(S.data_vars),
        length(S.meta.full_equations), length(S.meta.dropped_equation_indices), string(S.meta.algebraic_multiplicity)); flush(stdout)
    grid = collect(-0.5:0.1:0.5)
    for (nm,f) in (("A",()->expA(S)),("B",()->expB(S)),("C",()->expC(S,grid)),("D",()->expD(S,grid)),("E",()->expE(S,grid)))
        ts=time()
        try f(); @printf(">>> EXP %s done (%.1fs)\n", nm, time()-ts)
        catch e; @printf("### EXP %s FAILED (%.1fs): %s\n", nm, time()-ts, sprint(showerror,e)); end
        flush(stdout)
    end
    println("\n=== ALL DONE ==="); flush(stdout)
end
main()
