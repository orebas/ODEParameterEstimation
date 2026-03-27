# Careful analysis of forced_lv_sinusoidal equation selection
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using Random; include("experiments/multipoint/analyze_flv_careful.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using Random

function get_deriv_order(name_str)
    clean = replace(string(name_str), r"_pt\d+$" => "")
    parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
    return isnothing(parsed) ? 0 : parsed[2]
end

function eq_max_deriv(eq)
    mo = 0
    for v in Symbolics.get_variables(eq)
        mo = max(mo, get_deriv_order(string(v)))
    end
    return mo
end

function main()
    pep = ODEParameterEstimation.forced_lv_sinusoidal()
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=51, time_interval=[0.0, 10.0], noise_level=0.0, nooutput=true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    model = pep_work.model.system; mq = pep_work.measured_quantities
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end
    println("True params: ", real_params)

    # Build cached template
    ordered_model = ODEParameterEstimation.OrderedODESystem(model, ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model))
    si_tmpl, _ = ODEParameterEstimation.prepare_si_template_with_structural_fix(
        ordered_model, mq, pep_work.data_sample, setup.good_DD, false;
        states=ModelingToolkit.unknowns(model), params=ModelingToolkit.parameters(model), infolevel=0)

    function build_at(t_idx)
        ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_idx],
            precomputed_interpolants=setup.interpolants, si_template=si_tmpl)
    end

    t_a = round(Int, n_t * 0.25); t_b = round(Int, n_t * 0.75)
    println("Points: t_a=$(t_vec[t_a]), t_b=$(t_vec[t_b])")

    ea, va = build_at(t_a)
    eb, vb = build_at(t_b)

    roles = ODEParameterEstimation._classify_polynomial_variables(string.(va), pep_work)
    param_set = Set(vn for (vn, r) in roles if r == :parameter)

    rd = Dict{Any,Any}()
    for v in vb; string(v) in param_set && continue
        rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt2"))
    end
    ebr = [Symbolics.substitute(eq, rd) for eq in eb]

    combined = vcat(ea, ebr)
    cvs = OrderedCollections.OrderedSet{Any}()
    for eq in combined; union!(cvs, Symbolics.get_variables(eq)); end
    cv = collect(cvs)
    n_per = length(ea); n_var = length(cv)

    println("Combined: $(length(combined)) eqs, $n_var vars")

    # Print equations with correct orders
    eq_ords = [eq_max_deriv(eq) for eq in combined]
    println("\nEquations:")
    for (i, eq) in enumerate(combined)
        src = i <= n_per ? "A$(lpad(i, 2))" : "B$(lpad(i-n_per, 2))"
        nv = length(Symbolics.get_variables(eq))
        is_data = nv == 1
        println("  $i [$src] ord=$(eq_ords[i]) $(is_data ? "DATA" : "STRUCT") nv=$nv")
    end

    # Jacobian
    rp = randn(n_var) .* 10
    f_all = ODEParameterEstimation._compile_system_function(combined, cv)
    J = ForwardDiff.jacobian(f_all, rp)
    println("\nJacobian rank: $(rank(J; atol=1e-8)) / $n_var")

    function greedy(order)
        sel = Int[]; cur = zeros(eltype(J), 0, n_var); cr = 0
        for idx in order
            test = vcat(cur, J[idx:idx, :]); r = rank(test; atol=1e-8)
            if r > cr; push!(sel, idx); cur = test; cr = r; end
            cr == n_var && break
        end
        return sel
    end

    function solve_report(label, sel)
        if length(sel) != n_var
            println("  $label: $(length(sel))/$n_var NOT SQUARE")
            return
        end
        solutions = try; s, _, _, _ = ODEParameterEstimation.solve_with_hc(combined[sel], cv); s
        catch e; println("  $label: HC FAIL — $(sprint(showerror, e)[1:min(50,end)])"); return; end
        pidxs = [i for (i, v) in enumerate(cv) if string(v) in param_set]
        pnames = [replace(string(cv[i]), "_0" => "") for i in pidxs]
        println("  $label: $(length(solutions)) solutions")
        for (si, sol) in enumerate(solutions)
            pvals = [sol[i] for i in pidxs]
            me = 0.0
            for (j, pn) in enumerate(pnames)
                haskey(real_params, pn) && (me = max(me, abs(pvals[j]-real_params[pn])/max(abs(real_params[pn]),1e-10)))
            end
            param_str = join([@sprintf("%s=%.3f", pn, pvals[j]) for (j, pn) in enumerate(pnames) if haskey(real_params, pn)], " ")
            @printf("    sol%d: %s  max_err=%.4f\n", si, param_str, me)
        end
    end

    # 1-point baselines
    println("\n=== 1-POINT BASELINES ===")
    for frac in [0.2, 0.33, 0.5, 0.67, 0.8]
        t_idx = max(2, min(n_t-1, round(Int, n_t * frac)))
        eqs_1, vars_1 = build_at(t_idx)
        solutions = try; s, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs_1, vars_1); s; catch; []; end
        pidxs = [i for (i, v) in enumerate(vars_1) if roles[string(v)] == :parameter]
        pnames = [replace(string(vars_1[i]), "_0" => "") for i in pidxs]
        for sol in solutions
            pvals = [sol[i] for i in pidxs]
            me = maximum(haskey(real_params, pn) ? abs(pvals[j]-real_params[pn])/max(abs(real_params[pn]),1e-10) : 0.0 for (j,pn) in enumerate(pnames))
            @printf("  1pt t=%.1f: %s  max_err=%.4f\n", t_vec[t_idx],
                join([@sprintf("%s=%.3f", pn, pvals[j]) for (j, pn) in enumerate(pnames) if haskey(real_params, pn)], " "), me)
        end
    end

    # 2-point strategies
    println("\n=== 2-POINT STRATEGIES ===")

    # Interleaved
    interleaved = Int[]
    for i in 1:n_per; push!(interleaved, i); push!(interleaved, n_per + i); end
    sel_int = greedy(interleaved)
    solve_report("Interleaved", sel_int)
    if length(sel_int) == n_var
        println("    Eqs from A: $(sort(filter(i -> i <= n_per, sel_int)))")
        println("    Eqs from B: $(sort(filter(i -> i > n_per, sel_int)) .- n_per)")
        println("    Max order: $(maximum(eq_ords[sel_int]))")
    end

    # Low-order interleaved
    a_by_ord = sortperm(eq_ords[1:n_per])
    b_by_ord = sortperm(eq_ords[n_per+1:end]) .+ n_per
    lo_int = Int[]
    for i in 1:n_per
        i <= length(a_by_ord) && push!(lo_int, a_by_ord[i])
        i <= length(b_by_ord) && push!(lo_int, b_by_ord[i])
    end
    sel_lo = greedy(lo_int)
    solve_report("Low-order interleaved", sel_lo)
    if length(sel_lo) == n_var
        same = Set(sel_int) == Set(sel_lo)
        println("    Same as interleaved: $same")
        println("    Max order: $(maximum(eq_ords[sel_lo]))")
    end

    # QR
    F = qr(transpose(J), ColumnNorm())
    qr_rows = sort(F.p[1:n_var])
    solve_report("QR pivot", qr_rows)
    if length(qr_rows) == n_var
        same_int = Set(sel_int) == Set(qr_rows)
        println("    Same as interleaved: $same_int")
        println("    Max order: $(maximum(eq_ords[qr_rows]))")
        diff_in = setdiff(Set(qr_rows), Set(sel_int))
        diff_out = setdiff(Set(sel_int), Set(qr_rows))
        !same_int && println("    QR adds: $diff_in, drops: $diff_out")
    end
end

main()
