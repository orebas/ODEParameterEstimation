# Sanity: does HC.solve(...; tracker_options=...) actually propagate to the tracker?
# Test at t=-0.3 seed=1 with max_steps in {50, 10_000, 200_000}. If options ARE applied,
# max_steps=50 must crater the finite count (paths can't converge in 50 steps) and bloat
# terminated_max_steps. If the count is unchanged, solve is ignoring tracker_options.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, Random, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation

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
    return (; spep, mq, tdd, data_vars, hc_system, hc_params)
end
oracle_params(S, t; maxorder=12) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), maxorder), S.data_vars, S.tdd, S.mq, Float64(t))
nfin(res) = length(HC.solutions(res; only_nonsingular=false, only_finite=true))
cc(prs, code) = count(r->r.return_code==code, prs)

function main()
    S = setup_all()
    p = oracle_params(S, -0.3)
    println("Verifying tracker_options propagation at t=-0.3 (seed=1):"); flush(stdout)
    for ms in (50, 10_000, 200_000)
        to = HC.TrackerOptions(max_steps=ms, extended_precision=true)
        res = HC.solve(S.hc_system; target_parameters=p, seed=UInt32(1), tracker_options=to, show_progress=false)
        prs = HC.path_results(res)
        @printf("  max_steps=%-7d : finite=%2d  success=%d  term_max_steps=%d  term_step_small=%d  term_acc=%d\n",
            ms, nfin(res), cc(prs,:success), cc(prs,:terminated_max_steps), cc(prs,:terminated_step_size_too_small), cc(prs,:terminated_accuracy_limit)); flush(stdout)
    end
    println("\nVerdict: if finite CRATERS at max_steps=50 -> tracker_options ARE applied (so 'aggressive")
    println("doesn't help' is a real result). If finite is unchanged -> solve ignored the options.")
    flush(stdout)
end
main()
