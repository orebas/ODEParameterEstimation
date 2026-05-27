# EXP G — SOLVER vs GEOMETRY forensics for the receptor "blind spot".
#
# Background: a FRESH polyhedral solve (Exp C) returns the generic 18 finite solutions at
# t>=+0.2 but only ~10 near t=-0.3, with nsingular=0 throughout. Since nothing is singular,
# the missing solutions are heading to INFINITY. Question (Oren): is that genuine geometry
# (special real params -> some of the 18 truly diverge) or a SOLVER artifact (HC's tracker
# fails / mislabels finite-but-ill-conditioned paths)?
#
# We answer it by reading HC's per-path forensics, which Exp A-F never looked at:
#   * return_code histogram (:success / :at_infinity / :terminated_* )
#   * condition_jacobian distribution
#   * extended_precision_used (is HC already at the precision wall?)
# plus three controlled experiments:
#   G1/G2  same seed, DEFAULT vs AGGRESSIVE tracker -> does precision/steps recover them?
#   G3     track the TRUTH path alone from a good t into the blind spot -> watch cond ramp
#   G4     start from the certified generic 18, homotope to the real target -> how do the
#          18 partition into success/at_infinity/terminated at t=-0.3?
#   G0'    HC.certify (interval arithmetic) for a RIGOROUS independent count (no msolve needed)
#
# All logic in functions (avoid Julia soft-scope). Explicit flush. Per-block try/catch.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, Random, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation

const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

# ---- proven setup/helpers copied verbatim from run_diagnostic.jl ----
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

# ---- forensic helpers ----
med(v) = (s=sort(v); n=length(s); n==0 ? NaN : (isodd(n) ? s[(n+1)÷2] : (s[n÷2]+s[n÷2+1])/2))
function code_hist(prs)
    h = Dict{Symbol,Int}(); for r in prs; h[r.return_code]=get(h,r.return_code,0)+1; end; h
end
function cond_of(prs; pred=r->true)
    cs = Float64[]; for r in prs; (pred(r) && isfinite(r.condition_jacobian)) && push!(cs, r.condition_jacobian); end; cs
end

function report_solve(S, label, res)
    prs = HC.path_results(res); b = bd(res); h = code_hist(prs)
    @printf("  [%-18s] finite=%2d real=%2d singular=%d  %s\n", label, b.finite, b.real, b.singular, hit(S,b.realsols)); flush(stdout)
    print("      codes: "); for (k,v) in sort(collect(h), by=x->-x[2]); @printf("%s=%d  ", k, v); end; println()
    csa = cond_of(prs); csi = cond_of(prs; pred=r->r.return_code==:at_infinity)
    epu = count(r->r.extended_precision_used, prs)
    ninf_hi = count(r->r.return_code==:at_infinity && r.condition_jacobian>1e12, prs)
    @printf("      cond_jac(all): med=%.1e max=%.1e (#>1e10=%d, #>1e14=%d) | at_inf cond med=%.1e max=%.1e (#cond>1e12=%d) | ext_prec_used=%d\n",
        isempty(csa) ? NaN : med(csa), isempty(csa) ? NaN : maximum(csa),
        count(>(1e10),csa), count(>(1e14),csa),
        isempty(csi) ? NaN : med(csi), isempty(csi) ? NaN : maximum(csi), ninf_hi, epu); flush(stdout)
    return b
end

function dump_systems(S, dir)
    open(joinpath(dir,"trimmed_system_32.txt"),"w") do io
        println(io, "# TRIMMED (square) SI-template polynomial system actually solved by HC.")
        println(io, "# $(length(S.te)) equations, $(length(S.solve_vars)) solve_vars, $(length(S.data_vars)) data_vars (known from the derivative jet).")
        println(io, "# solve_vars: ", join(string.(S.solve_vars), ", "))
        println(io, "# data_vars : ", join(string.(S.data_vars), ", "))
        println(io); for (i,eq) in enumerate(S.te); println(io, "[$i]  ", eq, "  = 0"); end
    end
    open(joinpath(dir,"full_system_40.txt"),"w") do io
        println(io, "# FULL (untrimmed) SI-template system: $(length(S.meta.full_equations)) equations.")
        println(io, "# Rank-trimming dropped equation indices: $(S.meta.dropped_equation_indices)")
        println(io, "# (The trimmed 32-eq system above has SPURIOUS roots; only solutions also satisfying")
        println(io, "#  these dropped equations are genuine. algebraic_multiplicity reported = $(S.meta.algebraic_multiplicity).)")
        println(io); for (i,eq) in enumerate(S.meta.full_equations); println(io, "[$i]  ", eq, "  = 0"); end
    end
    println("  wrote trimmed_system_32.txt ($(length(S.te)) eqs) and full_system_40.txt ($(length(S.meta.full_equations)) eqs)"); flush(stdout)
end

# G0' — rigorous independent count via interval-arithmetic certification
function certify_count(S, label, p, sols)
    try
        cert = HC.certify(S.hc_system, sols; target_parameters=p, show_progress=false)
        print("  [certify $label] "); println(cert)
        for f in (:ncertified, :ndistinct_certified, :ndistinct_real_certified)
            try @printf("      %s = %d\n", f, getfield(HC, f)(cert)) catch end
        end
    catch e; @printf("  [certify %s] FAILED: %s\n", label, sprint(showerror,e)) end
    flush(stdout)
end

# G4 — start from certified generic 18, homotope to each real target; read arrival codes
function generic_to_target(S, ts, p0, s18)
    println("\n##### EXP G4: generic(18) -> real target params (how do the known 18 partition?) #####"); flush(stdout)
    for t in ts
        res = HC.solve(S.hc_system, s18; start_parameters=p0, target_parameters=oracle_params(S,t), show_progress=false)
        report_solve(S, "generic->t=$t", res)
    end
end

# G3 — track the truth path alone from a good t into the blind spot; watch cond ramp up
function truth_vec_at(S, t)
    res = HC.solve(S.hc_system; target_parameters=oracle_params(S,t), show_progress=false)
    for x in HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
        d = Dict(k=>gi(S,x,k) for k in keys(TRUTH))
        all(isfinite(d[k]) && abs(d[k]-TRUTH[k])<0.05*max(abs(TRUTH[k]),1) for k in keys(TRUTH)) && return x
    end
    return nothing
end
function track_truth(S, t_start, path_ts)
    println("\n##### EXP G3: single-path tracking of TRUTH from t=$t_start into the blind spot #####"); flush(stdout)
    x0 = truth_vec_at(S, t_start)
    if x0 === nothing; println("  could not isolate truth at t=$t_start — abort G3"); flush(stdout); return; end
    @printf("  truth isolated at t=%.2f (%d-vector); tracking it alone:\n", t_start, length(x0)); flush(stdout)
    prev = [x0]; prevp = oracle_params(S, t_start)
    for t in path_ts
        p = oracle_params(S, t)
        res = HC.solve(S.hc_system, prev; start_parameters=prevp, target_parameters=p, show_progress=false)
        prs = HC.path_results(res)
        if isempty(prs); @printf("    t=%+.2f : (no path result)\n", t); flush(stdout); break; end
        r = prs[1]
        af = HC.solutions(res; only_nonsingular=false, only_finite=true)
        stillT = false
        if !isempty(af)
            d = Dict(k=>gi(S,af[1],k) for k in keys(TRUTH))
            stillT = all(isfinite(d[k]) && abs(d[k]-TRUTH[k])<0.05*max(abs(TRUTH[k]),1) for k in keys(TRUTH))
        end
        @printf("    t=%+.2f : code=%-24s cond=%.2e acc=%.1e ep_used=%-5s finite=%d %s\n",
            t, string(r.return_code), r.condition_jacobian, r.accuracy, string(r.extended_precision_used),
            length(af), stillT ? "[still TRUTH]" : (isempty(af) ? "[LEFT to infinity/failed]" : "[jumped off truth]")); flush(stdout)
        if isempty(af); break; end       # path left the affine chart; can't carry it further
        prev = af; prevp = p
    end
end

# G1/G2 — fresh polyhedral, DEFAULT vs AGGRESSIVE tracker at the SAME seed (controlled A/B)
function expG_fresh(S, ts)
    println("\n##### EXP G1/G2: fresh polyhedral — DEFAULT vs AGGRESSIVE tracker (same seed) #####"); flush(stdout)
    aggr = HC.TrackerOptions(max_steps=200_000, extended_precision=true, min_step_size=1e-64)
    for t in ts
        p = oracle_params(S,t)
        seeds = (t == 0.0) ? (1,) : (1,2)
        println("=== t=$t ==="); flush(stdout)
        for s in seeds
            rd = HC.solve(S.hc_system; target_parameters=p, seed=UInt32(s), show_progress=false)
            bdd = report_solve(S, "default seed=$s", rd)
            ra = HC.solve(S.hc_system; target_parameters=p, seed=UInt32(s), tracker_options=aggr, show_progress=false)
            bda = report_solve(S, "AGGR seed=$s", ra)
            verdict = bda.finite > bdd.finite ? @sprintf("SOLVER-RECOVERABLE (+%d finite via aggressive tracker)", bda.finite-bdd.finite) :
                      bda.finite < bdd.finite ? @sprintf("aggressive found FEWER (-%d) — count is seed/path stochastic", bdd.finite-bda.finite) :
                      "NO CHANGE (identical finite count → deficit NOT fixed by precision/steps)"
            @printf("    >>> t=%+.2f seed=%d VERDICT: %s\n", t, s, verdict); flush(stdout)
        end
    end
end

function main()
    dir = @__DIR__
    println("=== EXP G: SOLVER vs GEOMETRY FORENSICS ==="); flush(stdout)
    t0=time(); S = setup_all()
    @printf("setup (%.1fs): %d eqs / %d solve_vars / %d data_vars ; full=%d dropped=%s M=%s\n",
        time()-t0, length(S.te), length(S.solve_vars), length(S.data_vars),
        length(S.meta.full_equations), string(S.meta.dropped_equation_indices), string(S.meta.algebraic_multiplicity)); flush(stdout)
    dump_systems(S, dir)
    ts = [0.0, -0.3, -0.4]

    # generic solve once, shared by G0' (certify) and G4
    println("\n##### EXP G0': generic solve + rigorous certification #####"); flush(stdout)
    Random.seed!(7); p0 = randn(ComplexF64, length(S.hc_params))
    res0 = HC.solve(S.hc_system; target_parameters=p0, show_progress=false)
    s18 = HC.solutions(res0; only_nonsingular=false, only_finite=true)
    @printf("  generic finite solutions = %d\n", length(s18)); flush(stdout)
    certify_count(S, "generic", p0, s18)
    # certify truth presence at t=0
    p00 = oracle_params(S, 0.0)
    s0 = HC.solutions(HC.solve(S.hc_system; target_parameters=p00, show_progress=false); only_nonsingular=false, only_finite=true)
    certify_count(S, "oracle t=0", p00, s0)

    for (nm,f) in (("G4-generic->target", ()->generic_to_target(S, ts, p0, s18)),
                   ("G3-truth-path",      ()->track_truth(S, 0.0, [-0.1,-0.2,-0.3,-0.4,-0.5])),
                   ("G1G2-fresh",         ()->expG_fresh(S, ts)))
        ts0=time()
        try f(); @printf(">>> %s done (%.1fs)\n", nm, time()-ts0)
        catch e; @printf("### %s FAILED (%.1fs): %s\n", nm, time()-ts0, sprint(showerror,e)) end
        flush(stdout)
    end
    println("\n=== EXP G DONE ==="); flush(stdout)
end
main()
