# EXP I (v2) — the decisive tiebreaker both PAL partners demanded:
# dump TRUTH's exact solution coordinates vs t. Geometry(i) vs coordinate-pathology(ii):
#   * if high-order jet coords (Ca_8, L_7, ...) EXPLODE or coords SHRINK toward 0 (toric boundary)
#     at t<=-0.3 -> coordinate/scaling pathology (fixable by substitution/Taylor-scaling).
#   * if all coords are O(1) yet HC still fails -> genuine discriminant/path issue.
# Also: residual of TRUTH in the TRIMMED system at oracle data (does truth exist as a root there?),
# and monodromy_solve seeded at truth at the blind spot.  READ-ONLY.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation
const PARAMBASES = Set(["R1tot","R2tot","kon1","kon2","koff1","koff2"])
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)

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
    return (; spep, mq, ds, tdd, te, data_vars, solve_vars, svname=string.(solve_vars))
end
oracle_params(S, t; maxorder=12) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), maxorder), S.data_vars, S.tdd, S.mq, Float64(t))

function truth_vec(S, t; maxorder=12)
    sc = OPE.compute_oracle_taylor_coefficients(S.spep, Float64(t), maxorder)
    scbase = Dict(replace(string(k), "(t)"=>"") => v for (k,v) in sc)
    tv = zeros(ComplexF64, length(S.svname)); info = Tuple{String,Int,Float64}[]
    for (i,nm) in enumerate(S.svname)
        parsed = OPE.parse_derivative_variable_name(nm)
        base, ord = parsed === nothing ? (nm, 0) : (String(parsed[1]), parsed[2])
        if base in PARAMBASES
            tv[i] = TRUTH[base]
        elseif haskey(scbase, base)
            tv[i] = Float64(scbase[base][ord+1] * factorial(big(ord)))  # jet var x_k = k-th derivative
        end
        push!(info, (nm, ord, abs(tv[i])))
    end
    return tv, info
end
getmag(info, name) = (for (nm,ord,a) in info; nm==name && return a; end; NaN)

function main()
    println("=== EXP I v2: truth coordinates vs t (geometry vs scaling) ==="); flush(stdout)
    S = setup_all()
    trim_sys, _, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
    grid = collect(-0.5:0.1:0.5)
    @printf("%6s | %10s | %10s %-8s | %10s %-8s | %8s %8s %8s\n",
        "t","trim_res","max|x|","(var)","minpos|x|","(var)","|Ca_8|","|Cb_8|","|L_7|"); flush(stdout)
    for t in grid
        p = oracle_params(S, t); tv, info = truth_vec(S, t)
        r = trim_sys(tv, p)
        mags = [a for (_,_,a) in info]; nms = [nm for (nm,_,_) in info]
        imax = argmax(mags); posmags = [(i,a) for (i,a) in enumerate(mags) if a>0]
        imin = posmags[argmin([a for (_,a) in posmags])][1]
        @printf("%+6.2f | %10.2e | %10.2e %-8s | %10.2e %-8s | %8.1e %8.1e %8.1e\n",
            t, norm(r), mags[imax], nms[imax], mags[imin], nms[imin],
            getmag(info,"Ca_8"), getmag(info,"Cb_8"), getmag(info,"L_7")); flush(stdout)
    end
    # per-order max magnitude at the blind spot vs a good point (factorial/derivative blowup?)
    for t in (-0.3, 0.0)
        _, info = truth_vec(S, t); bord = Dict{Int,Float64}()
        for (_,ord,a) in info; bord[ord]=max(get(bord,ord,0.0),a); end
        print("  max|coord| by order @ t=$t: "); for o in sort(collect(keys(bord))); @printf("o%d:%.1e ", o, bord[o]); end; println(); flush(stdout)
    end
    # monodromy seeded at truth at the blind spot
    for t in (-0.3,)
        p = oracle_params(S, t); tv, _ = truth_vec(S, t)
        try
            mr = HC.monodromy_solve(trim_sys, [tv], p; show_progress=false)
            @printf("  MONODROMY @ t=%.2f (seed=truth): %d solutions found\n", t, length(HC.solutions(mr))); flush(stdout)
        catch e
            @printf("  MONODROMY @ t=%.2f failed: %s\n", t, sprint(showerror,e)[1:min(140,end)]); flush(stdout)
        end
    end
    println("\n=== EXP I v2 DONE ==="); flush(stdout)
end
main()
