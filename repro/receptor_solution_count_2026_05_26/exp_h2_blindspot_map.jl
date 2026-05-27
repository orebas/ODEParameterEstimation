# EXP H2 — does the t=-0.3 blind spot SURVIVE the well-conditioned (pin-keeping) reformulation?
#
# Exp H showed keeping the linear y1-pins cuts the path count 6402->~297 and improves conditioning
# ~500x, yet at seed=1 truth was still missing at t=-0.3. That was ONE seed. Here we multi-seed
# the pin-keeping system across the left region to decide: if truth stays absent across seeds ->
# the blind spot is genuinely GEOMETRIC (survives reconditioning); if seeds now recover it ->
# the production blind spot was substantially trim-induced ill-conditioning.
#
# READ-ONLY diagnostic: builds an alternative square subsystem locally, does NOT modify any
# production trimming code.
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
gi(S,s,b) = (i=findfirst(n->n==b||n==b*"_0", S.svname); i===nothing ? NaN : real(s[i]))
function hit(S, realsols)
    t=false; sw=false
    for x in realsols
        d=Dict(k=>gi(S,x,k) for k in keys(TRUTH))
        all(isfinite(d[k]) && abs(d[k]-TRUTH[k])<0.05*max(abs(TRUTH[k]),1) for k in keys(TRUTH)) && (t=true)
        all(isfinite(d[k]) && abs(d[k]-SWAP[k]) <0.05*max(abs(SWAP[k]),1)  for k in keys(SWAP))  && (sw=true)
    end
    (t ? "T" : ".")*(sw ? "S" : ".")
end
function select_square(aug, solve_vars, data_vars; ntarget=length(solve_vars))
    J = Symbolics.jacobian(aug, solve_vars)
    Random.seed!(123); subs = Dict{Any,Any}()
    for v in solve_vars; subs[v] = randn(ComplexF64); end
    for v in data_vars;  subs[v] = randn(ComplexF64); end
    Jn = [ComplexF64(Symbolics.value(substitute(J[i,j], subs))) for i in 1:size(J,1), j in 1:size(J,2)]
    chosen = Int[]; B = zeros(ComplexF64, 0, ntarget)
    for i in 1:size(Jn,1)
        cand = vcat(B, reshape(Jn[i,:], 1, :))
        if rank(cand; atol=1e-8) > size(B,1); push!(chosen, i); B = cand; end
        length(chosen) == ntarget && break
    end
    return chosen
end

function main()
    println("=== EXP H2: blind-spot survival under pin-keeping reformulation ==="); flush(stdout)
    S = setup_all()
    pins = Any[]
    for k in 1:7
        li = findfirst(==("L_$k"), S.svname); yi = findfirst(==("Differential(t, $k)(y1(t))"), S.dvname)
        (li===nothing || yi===nothing) && continue
        push!(pins, S.solve_vars[li] - S.data_vars[yi])
    end
    aug = vcat(pins, collect(S.te))
    chosen = select_square(aug, S.solve_vars, S.data_vars)
    sys_H, _, _ = OPE.convert_to_hc_format_with_params(aug[chosen], S.solve_vars, S.data_vars)
    @printf("pin-keeping system built (%d pins kept). Multi-seed sweep (T=truth found, S=swap found):\n",
        count(<=(length(pins)), chosen)); flush(stdout)
    grid = collect(-0.5:0.1:0.1)
    seeds = 1:8
    @printf("   t   | %s | #seeds w/ truth | finite(med) maxcond(med)\n", join([@sprintf("s%d",s) for s in seeds], " "))
    for t in grid
        p = oracle_params(S, t)
        flags = String[]; ntruth = 0; fins = Int[]; conds = Float64[]
        for s in seeds
            res = HC.solve(sys_H; target_parameters=p, seed=UInt32(s), show_progress=false)
            rf = HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
            af = HC.solutions(res; only_nonsingular=false, only_finite=true)
            h = hit(S, rf); push!(flags, h); occursin("T", h) && (ntruth += 1)
            push!(fins, length(af))
            cs = [r.condition_jacobian for r in HC.path_results(res) if r.return_code==:success && isfinite(r.condition_jacobian)]
            push!(conds, isempty(cs) ? NaN : maximum(cs))
        end
        medf = sort(fins)[cld(length(fins),2)]
        medc = (cs=sort(filter(isfinite,conds)); isempty(cs) ? NaN : cs[cld(length(cs),2)])
        @printf("  %+5.2f | %s | %d/%d | %d  %.1e\n", t, join(flags, " "), ntruth, length(seeds), medf, medc); flush(stdout)
    end
    println("\n=== EXP H2 DONE ==="); flush(stdout)
end
main()
