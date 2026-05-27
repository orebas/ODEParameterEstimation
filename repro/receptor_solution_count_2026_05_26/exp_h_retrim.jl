# EXP H — test the "smarter trim" hypothesis.
#
# Finding: the production rank-trim keeps eqs [1]-[32] and DROPS [33]-[40], which are the
# LINEAR data-pins  L_k = y1_k  (k=1..7)  and  Ca_8+Cb_8 = y2_8.  Because y1 = L is observed
# directly, the trimmed 32-eq system therefore uses NONE of the y1-derivative data (orders 1-7).
# That under-constrains the system (18 finite roots instead of 2 physical) and forces reliance on
# high-order y2 derivatives (ill-conditioning -> the t=-0.3 blind spot).
#
# Hypothesis: a trim that PRIORITIZES the linear pins (keep L_k = y1_k, drop redundant nonlinear
# dynamics eqs instead) yields a square system that (a) has far fewer spurious roots and (b) is
# much better conditioned -> recovers truth at t=-0.3.
#
# Test: build augmented list [7 linear pins ; original 32 te], greedily select a rank-32
# independent subset with the PINS FIRST, solve at t=0 and t=-0.3 with oracle data, and compare
# finite/real/truth + condition numbers + return-code histogram against the production trim.
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
    return (; spep, mq, ds, tvec, tdd, dd, te, meta, data_vars, solve_vars, svname=string.(solve_vars), dvname=string.(data_vars))
end
oracle_params(S, t; maxorder=12) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), maxorder), S.data_vars, S.tdd, S.mq, Float64(t))
function bd(res)
    allfin  = HC.solutions(res; only_nonsingular=false, only_finite=true)
    realfin = HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
    (finite=length(allfin), real=length(realfin), realsols=realfin)
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
med(v) = (s=sort(v); n=length(s); n==0 ? NaN : (isodd(n) ? s[(n+1)÷2] : (s[n÷2]+s[n÷2+1])/2))
function report(S, label, sys, p)
    res = HC.solve(sys; target_parameters=p, seed=UInt32(1), show_progress=false)
    prs = HC.path_results(res); b = bd(res)
    h = Dict{Symbol,Int}(); for r in prs; h[r.return_code]=get(h,r.return_code,0)+1; end
    cs = Float64[]; for r in prs; isfinite(r.condition_jacobian) && push!(cs, r.condition_jacobian); end
    succ_cs = Float64[]; for r in prs; (r.return_code==:success && isfinite(r.condition_jacobian)) && push!(succ_cs, r.condition_jacobian); end
    @printf("  [%-22s] finite=%2d real=%2d  %s\n", label, b.finite, b.real, hit(S,b.realsols)); flush(stdout)
    print("      codes: "); for (k,v) in sort(collect(h), by=x->-x[2]); @printf("%s=%d  ", k, v); end; println()
    @printf("      cond_jac(success-paths): med=%.2e max=%.2e\n",
        isempty(succ_cs) ? NaN : med(succ_cs), isempty(succ_cs) ? NaN : maximum(succ_cs)); flush(stdout)
    return b
end

# Greedy rank-32 selection from an augmented equation list, evaluating the symbolic Jacobian at a
# random complex point. Equations earlier in `aug` are preferred (so put the linear pins first).
function select_square(aug, solve_vars, data_vars; ntarget=length(solve_vars))
    J = Symbolics.jacobian(aug, solve_vars)               # (length(aug)) x ntarget symbolic
    Random.seed!(123)
    subs = Dict{Any,Any}()
    for v in solve_vars; subs[v] = randn(ComplexF64); end
    for v in data_vars;  subs[v] = randn(ComplexF64); end
    Jn = [ComplexF64(Symbolics.value(substitute(J[i,j], subs))) for i in 1:size(J,1), j in 1:size(J,2)]
    chosen = Int[]; B = zeros(ComplexF64, 0, ntarget)
    for i in 1:size(Jn,1)
        cand = vcat(B, reshape(Jn[i,:], 1, :))
        if rank(cand; atol=1e-8) > size(B,1)
            push!(chosen, i); B = cand
        end
        length(chosen) == ntarget && break
    end
    return chosen, rank(B; atol=1e-8)
end

function main()
    println("=== EXP H: smarter-trim (keep linear y1-pins) vs production trim ==="); flush(stdout)
    S = setup_all()
    @printf("solve_vars=%d data_vars=%d te=%d\n", length(S.solve_vars), length(S.data_vars), length(S.te)); flush(stdout)

    # production system (baseline)
    sys_prod, _, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)

    # build the 7 linear pins L_k - y1_k for k=1..7
    pins = Any[]
    for k in 1:7
        li = findfirst(==("L_$k"), S.svname); li === nothing && continue
        yi = findfirst(==("Differential(t, $k)(y1(t))"), S.dvname); yi === nothing && continue
        push!(pins, S.solve_vars[li] - S.data_vars[yi])
    end
    @printf("built %d linear pins L_k=y1_k\n", length(pins)); flush(stdout)

    # augmented list with PINS FIRST, then production te; greedily pick a square rank-32 subset
    aug = vcat(pins, collect(S.te))
    chosen, rk = select_square(aug, S.solve_vars, S.data_vars)
    npins_kept = count(<=(length(pins)), chosen)
    @printf("selected %d eqs (rank=%d); linear pins kept: %d/%d\n", length(chosen), rk, npins_kept, length(pins)); flush(stdout)
    sys_H, _, _ = OPE.convert_to_hc_format_with_params(aug[chosen], S.solve_vars, S.data_vars)

    for t in (0.0, -0.3, -0.4)
        p = oracle_params(S, t)
        println("=== t=$t ==="); flush(stdout)
        report(S, "PRODUCTION trim", sys_prod, p)
        report(S, "SMARTER trim (pins)", sys_H, p)
    end
    println("\n=== EXP H DONE ==="); flush(stdout)
end
main()
