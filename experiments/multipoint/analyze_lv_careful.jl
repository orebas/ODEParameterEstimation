# Careful analysis of lotka_volterra equation selection
#
# Goals:
# 1. Fix derivative order parsing for _pt2 variables
# 2. Compare ALL selection strategies on the SAME system
# 3. Verify solution counts are correct (not bugs)
# 4. Check: are the selected equation SETS actually different across strategies?
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using Random; include("experiments/multipoint/analyze_lv_careful.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using Random

function main()
    # ── Setup ────────────────────────────────────────────────────────────
    pep = ODEParameterEstimation.lotka_volterra()
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=51, nooutput=true))
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_data; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    model = pep_data.model.system; mq = pep_data.measured_quantities
    t_vec = pep_data.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_data.p_true
        real_params[replace(string(k), "(t)" => "")] = v
    end
    println("True params: ", real_params)

    t_a = round(Int, n_t * 0.25); t_b = round(Int, n_t * 0.75)
    println("Points: t_a=$(t_vec[t_a]), t_b=$(t_vec[t_b])")

    # Build template once, reuse
    ordered_model = ODEParameterEstimation.OrderedODESystem(model, ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model))
    si_tmpl, _ = ODEParameterEstimation.prepare_si_template_with_structural_fix(
        ordered_model, mq, pep_data.data_sample, setup.good_DD, false;
        states=ModelingToolkit.unknowns(model), params=ModelingToolkit.parameters(model), infolevel=0)

    function build_at(t_idx)
        ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_idx],
            precomputed_interpolants=setup.interpolants, si_template=si_tmpl)
    end

    ea, va = build_at(t_a)
    eb, vb = build_at(t_b)

    roles = ODEParameterEstimation._classify_polynomial_variables(string.(va), pep_data)
    param_set = Set(vn for (vn, r) in roles if r == :parameter)

    # Rename point B state vars
    rd = Dict{Any,Any}()
    for v in vb
        string(v) in param_set && continue
        rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt2"))
    end
    ebr = [Symbolics.substitute(eq, rd) for eq in eb]

    combined = vcat(ea, ebr)
    cvs = OrderedCollections.OrderedSet{Any}()
    for eq in combined; union!(cvs, Symbolics.get_variables(eq)); end
    cv = collect(cvs)
    n_per = length(ea)
    n_var = length(cv)

    println("\nCombined: $(length(combined)) equations, $n_var variables")

    # ── FIX: Correct derivative order parsing ────────────────────────────
    # For point A variables like "r_1", parse normally → order 1
    # For point B variables like "r_1_pt2", strip "_pt2" first, then parse → order 1
    function get_deriv_order(var_or_eq_var)
        name = string(var_or_eq_var)
        # Strip _ptN suffix if present
        clean = replace(name, r"_pt\d+$" => "")
        parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
        return isnothing(parsed) ? 0 : parsed[2]
    end

    function eq_max_deriv(eq)
        mo = 0
        for v in Symbolics.get_variables(eq)
            mo = max(mo, get_deriv_order(v))
        end
        return mo
    end

    # Verify the fix works
    println("\nDerivative order parsing check:")
    for name in ["r_0", "r_1", "r_5", "r_0_pt2", "r_1_pt2", "r_5_pt2", "k1_0", "w_3_pt2"]
        clean = replace(name, r"_pt\d+$" => "")
        parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
        ord = isnothing(parsed) ? 0 : parsed[2]
        println("  $name → clean=$clean → order=$ord")
    end

    # Compute correct derivative orders for all equations
    eq_ords = [eq_max_deriv(eq) for eq in combined]
    println("\nEquation derivative orders:")
    for (i, eq) in enumerate(combined)
        src = i <= n_per ? "A$(lpad(i, 2))" : "B$(lpad(i-n_per, 2))"
        nv = length(Symbolics.get_variables(eq))
        is_data = nv == 1
        println("  $i [$src] ord=$(eq_ords[i]) $(is_data ? "DATA" : "STRUCT") nv=$nv")
    end

    # ── Jacobian ─────────────────────────────────────────────────────────
    rp = randn(n_var) .* 10
    f_all = ODEParameterEstimation._compile_system_function(combined, cv)
    J = ForwardDiff.jacobian(f_all, rp)
    println("\nJacobian rank: $(rank(J; atol=1e-8)) / $n_var")

    # ── Helper: greedy with given ordering ───────────────────────────────
    function greedy(order)
        sel = Int[]; cur = zeros(eltype(J), 0, n_var); cr = 0
        for idx in order
            test = vcat(cur, J[idx:idx, :]); r = rank(test; atol=1e-8)
            if r > cr; push!(sel, idx); cur = test; cr = r; end
            cr == n_var && break
        end
        return sel
    end

    # ── Helper: solve and report ─────────────────────────────────────────
    function solve_report(label, eqs_subset, varlist)
        solutions = try
            s, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs_subset, varlist)
            s
        catch e
            println("  $label: HC.jl FAILED — $(sprint(showerror, e)[1:min(60,end)])")
            return
        end
        pidxs = [i for (i, v) in enumerate(varlist) if string(v) in param_set]
        pnames = [replace(string(varlist[i]), "_0" => "") for i in pidxs]
        println("  $label: $(length(solutions)) solutions")
        for (si, sol) in enumerate(solutions)
            pvals = [sol[i] for i in pidxs]
            errs = Dict{String,Float64}()
            for (j, pn) in enumerate(pnames)
                haskey(real_params, pn) && (errs[pn] = abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10))
            end
            me = maximum(values(errs))
            param_str = join([@sprintf("%s=%.4f", pn, pvals[j]) for (j, pn) in enumerate(pnames) if haskey(real_params, pn)], " ")
            @printf("    sol%d: %s  max_err=%.4f\n", si, param_str, me)
        end
    end

    # ── 1-point baselines ────────────────────────────────────────────────
    println("\n=== 1-POINT BASELINES ===")
    solve_report("1pt-A (t=$(t_vec[t_a]))", ea, va)
    bvs = OrderedCollections.OrderedSet{Any}()
    for eq in ebr; union!(bvs, Symbolics.get_variables(eq)); end
    solve_report("1pt-B (t=$(t_vec[t_b]))", ebr, collect(bvs))

    # ── Strategy comparisons ─────────────────────────────────────────────
    println("\n=== 2-POINT STRATEGIES ===")

    # 1. Interleaved (A1,B1,A2,B2,...)
    interleaved = Int[]
    for i in 1:n_per; push!(interleaved, i); push!(interleaved, n_per + i); end
    sel_int = greedy(interleaved)
    println("\nInterleaved: $(length(sel_int))/$n_var selected")
    if length(sel_int) == n_var
        println("  Equations: $(sort(sel_int))")
        println("  From A: $(sort(filter(i -> i <= n_per, sel_int)))")
        println("  From B: $(sort(filter(i -> i > n_per, sel_int)) .- n_per)")
        solve_report("Interleaved", combined[sel_int], cv)
    end

    # 2. Low-order-first interleaved (sort by CORRECT derivative order, then interleave)
    a_by_ord = sortperm(eq_ords[1:n_per])
    b_by_ord = sortperm(eq_ords[n_per+1:end]) .+ n_per
    lo_interleaved = Int[]
    for i in 1:n_per
        i <= length(a_by_ord) && push!(lo_interleaved, a_by_ord[i])
        i <= length(b_by_ord) && push!(lo_interleaved, b_by_ord[i])
    end
    sel_lo = greedy(lo_interleaved)
    println("\nLow-order interleaved: $(length(sel_lo))/$n_var selected")
    if length(sel_lo) == n_var
        println("  Equations: $(sort(sel_lo))")
        sel_orders = [eq_ords[i] for i in sel_lo]
        println("  Max order: $(maximum(sel_orders))")
        println("  Order histogram: ", [count(==(o), sel_orders) for o in 0:maximum(sel_orders)])
        solve_report("Low-order interleaved", combined[sel_lo], cv)
    end

    # 3. QR pivot selection
    F = qr(transpose(J), ColumnNorm())
    qr_rows = sort(F.p[1:n_var])
    println("\nQR pivot: rows $(qr_rows)")
    println("  From A: $(sort(filter(i -> i <= n_per, qr_rows)))")
    println("  From B: $(sort(filter(i -> i > n_per, qr_rows)) .- n_per)")
    solve_report("QR pivot", combined[qr_rows], cv)

    # 4. Check: are the equation SETS the same?
    println("\n=== COMPARING SELECTED EQUATION SETS ===")
    if length(sel_int) == n_var && length(sel_lo) == n_var
        same_int_lo = Set(sel_int) == Set(sel_lo)
        same_int_qr = Set(sel_int) == Set(qr_rows)
        same_lo_qr = Set(sel_lo) == Set(qr_rows)
        println("  Interleaved == Low-order: $same_int_lo")
        println("  Interleaved == QR: $same_int_qr")
        println("  Low-order == QR: $same_lo_qr")
        if !same_int_qr
            only_int = setdiff(Set(sel_int), Set(qr_rows))
            only_qr = setdiff(Set(qr_rows), Set(sel_int))
            println("  In interleaved but not QR: $only_int")
            println("  In QR but not interleaved: $only_qr")
        end
    end
end

main()
