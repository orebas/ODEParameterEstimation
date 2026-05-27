# EXP K — confirm the FIX implied by Exp I (truth exists at t=-0.3 but lives at coords spanning
# ~1e7; the failure is column scaling, not geometry).
#   K1: seed monodromy_solve with an ORDINARY polyhedral-found solution at t=-0.3 (NOT truth).
#       If the 18 form one monodromy orbit, this completes to all 18 incl truth -> a practical
#       "polyhedral seed + monodromy completion" fix needing no rescaling.
#   K2: DATA-DRIVEN COLUMN SCALING. Rescale each jet variable x_k by the magnitude of the order-k
#       observable derivative (known from data, no truth needed): x_k = s_k * x_k_scaled. Solve the
#       rescaled system with plain polyhedral, multi-seed. If truth is now found at t=-0.3 (vs 0/8
#       baseline), column scaling is THE fix. Scaling x_k->s_k*x_k does NOT change the Newton
#       polytopes, so mixed_volume stays 6402 — only the coordinate scales change.
# READ-ONLY; no production code touched.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, Random, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation
const PARAMBASES = Set(["R1tot","R2tot","kon1","kon2","koff1","koff2"])
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

function setup_all()
    pep = OPE.receptor_subtype_binding_branch()
    opts = EstimationOptions(datasize=101, noise_level=0.0, use_si_template=true, nooutput=true)
    spep = sample_problem_data(pep, opts)
    setup = OPE.setup_parameter_estimation(spep; interpolator=OPE.aaad, nooutput=true)
    DD = setup.good_DD; mq = spep.measured_quantities; ds = spep.data_sample
    model = spep.model
    omodel = model isa OPE.OrderedODESystem ? model : begin (t,meq,ms,mp)=OPE.unpack_ODE(model); OPE.OrderedODESystem(model,ms,mp) end
    te, dd, _, _, _, meta = OPE.get_si_equation_system(omodel, mq, ds; DD=DD, infolevel=0)
    tdd = OPE.ensure_si_template_dd_support(omodel, mq, DD, dd)
    data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
    all_vars=[]; seen=Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(all_vars,v); push!(seen,v); end; end
    solve_vars = [v for v in all_vars if !(v in dset)]
    return (; spep, mq, ds, tdd, te, data_vars, solve_vars, svname=string.(solve_vars), dvname=string.(data_vars))
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
    (t ? "TRUTH " : "")*(sw ? "SWAP" : "")
end
realonly(sols) = [s for s in sols if maximum(abs.(imag.(s))) < 1e-6]

function order_scales(S, p)
    os = Dict{Int,Float64}()
    for (i,dv) in enumerate(S.dvname)
        m = match(r"Differential\(t, (\d+)\)", dv)
        k = m === nothing ? 0 : parse(Int, m.captures[1])
        os[k] = max(get(os,k,0.0), abs(p[i]))
    end
    os
end

function main()
    println("=== EXP K: confirm the column-scaling / monodromy fix at t=-0.3 ==="); flush(stdout)
    S = setup_all()
    trim_sys, _, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
    t = -0.3; p = oracle_params(S, t)

    # ---- K1: monodromy from an ordinary polyhedral solution ----
    res = HC.solve(trim_sys; target_parameters=p, seed=UInt32(1), show_progress=false)
    polysols = HC.solutions(res; only_nonsingular=false, only_finite=true)
    @printf("K1: plain polyhedral found %d finite; truth/swap among real: '%s'\n",
        length(polysols), hit(S, HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6))); flush(stdout)
    try
        mr = HC.monodromy_solve(trim_sys, polysols, p; show_progress=false)
        ms = HC.solutions(mr)
        @printf("K1: monodromy seeded from those %d -> %d solutions; truth/swap among real: '%s'\n",
            length(polysols), length(ms), hit(S, realonly(ms))); flush(stdout)
    catch e; @printf("K1 monodromy failed: %s\n", sprint(showerror,e)[1:min(160,end)]); flush(stdout) end

    # ---- K2: data-driven column scaling ----
    os = order_scales(S, p)
    sdict = Dict{Any,Any}(); scales = Float64[]
    for (i,nm) in enumerate(S.svname)
        parsed = OPE.parse_derivative_variable_name(nm)
        base, ord = parsed === nothing ? (nm,0) : (String(parsed[1]), parsed[2])
        s = base in PARAMBASES ? 1.0 : max(get(os, ord, 1.0), 1.0)
        push!(scales, s); sdict[S.solve_vars[i]] = s * S.solve_vars[i]
    end
    scaled_eqs = [substitute(eq, sdict) for eq in S.te]
    scaled_sys, _, _ = OPE.convert_to_hc_format_with_params(scaled_eqs, S.solve_vars, S.data_vars)
    @printf("K2: data-driven column scaling (scale range %.1e .. %.1e). Multi-seed at t=-0.3 (params unscaled):\n",
        minimum(scales), maximum(scales)); flush(stdout)
    nt = 0
    for seed in 1:6
        r = HC.solve(scaled_sys; target_parameters=p, seed=UInt32(seed), show_progress=false)
        fin = HC.solutions(r; only_nonsingular=false, only_finite=true)
        rf  = HC.solutions(r; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
        h = hit(S, rf); occursin("TRUTH", h) && (nt += 1)
        @printf("   seed=%d finite=%2d real=%2d %s\n", seed, length(fin), length(rf), h); flush(stdout)
    end
    @printf("K2 RESULT: column-scaled polyhedral found TRUTH in %d/6 seeds at t=-0.3 (unscaled baseline: 0/8)\n", nt); flush(stdout)
    println("\n=== EXP K DONE ==="); flush(stdout)
end
main()
