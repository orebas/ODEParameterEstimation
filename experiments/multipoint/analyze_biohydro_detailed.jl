# Detailed analysis of biohydrogenation 1-point vs 2-point stripped system
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/analyze_biohydro_detailed.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using Printf

function get_deriv_order(name_str)
    clean = replace(string(name_str), r"_pt\d+$" => "")
    parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
    return isnothing(parsed) ? 0 : parsed[2]
end

function main()
    pep = ODEParameterEstimation.biohydrogenation()
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=51, time_interval=[0.0, 1.0], noise_level=0.0, nooutput=true))
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_data; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    model = pep_data.model.system; mq = pep_data.measured_quantities
    t_vec = pep_data.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_data.p_true; real_params[replace(string(k), "(t)" => "")] = v; end

    # 1-point system
    t_mid = round(Int, n_t * 0.5)
    eqs1, vars1 = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_mid], precomputed_interpolants=setup.interpolants)
    roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars1), pep_data)
    param_set = Set(vn for (vn, r) in roles if r == :parameter)

    # Count 1-point structure
    data1 = count(eq -> length(Symbolics.get_variables(eq)) == 1, eqs1)
    struct1 = length(eqs1) - data1
    n_params = count(v -> string(v) in param_set, vars1)
    n_state1 = length(vars1) - n_params

    println("=== 1-POINT SYSTEM ===")
    println("  $(length(eqs1)) eqs, $(length(vars1)) vars")
    println("  $n_params params + $n_state1 state vars")
    println("  $struct1 structural + $data1 data equations")
    println("  Observables: x4, x5 (x6, x7 unobserved)")

    # Max order per variable base
    var_orders = Dict{String, Int}()
    for v in vars1
        clean = replace(string(v), r"\(.*\)$" => "")
        parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
        if !isnothing(parsed)
            base, ord = parsed
            var_orders[string(base)] = max(get(var_orders, string(base), 0), ord)
        end
    end
    println("  Max derivative per state: ", var_orders)

    # 2-point system
    t_a = round(Int, n_t*0.25); t_b = round(Int, n_t*0.75)
    ea, va = ODEParameterEstimation.construct_equation_system_from_si_template(model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD; interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_a], precomputed_interpolants=setup.interpolants)
    eb, vb = ODEParameterEstimation.construct_equation_system_from_si_template(model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD; interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_b], precomputed_interpolants=setup.interpolants)

    rd = Dict{Any,Any}()
    for v in vb; string(v) in param_set && continue
        rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt2")); end
    ebr = [Symbolics.substitute(eq, rd) for eq in eb]
    combined = vcat(ea, ebr)
    cvs = OrderedCollections.OrderedSet{Any}(); for eq in combined; union!(cvs, Symbolics.get_variables(eq)); end
    cv = collect(cvs)

    n_eq = length(combined); n_var = length(cv)
    n_state2 = n_var - n_params
    data2 = count(eq -> length(Symbolics.get_variables(eq)) == 1, combined)
    struct2 = n_eq - data2

    println("\n=== 2-POINT COMBINED (before stripping) ===")
    println("  $(n_eq) eqs, $(n_var) vars")
    println("  $n_params shared params + $n_state2 per-point state vars")
    println("  $struct2 structural + $data2 data equations")
    println("  Overdetermined by $(n_eq - n_var)")
    println("  Points: t=$(t_vec[t_a]), t=$(t_vec[t_b])")

    # Equation inventory by (type, order, point)
    eq_meta = []
    for (i, eq) in enumerate(combined)
        nv = length(Symbolics.get_variables(eq))
        mo = maximum(get_deriv_order(v) for v in Symbolics.get_variables(eq))
        pt = i <= length(ea) ? 1 : 2
        push!(eq_meta, (point=pt, is_data=nv==1, order=mo))
    end

    println("\n  Structural equations by order:")
    for ord in 0:10
        pt1 = count(i -> !eq_meta[i].is_data && eq_meta[i].order == ord && eq_meta[i].point == 1, 1:n_eq)
        pt2 = count(i -> !eq_meta[i].is_data && eq_meta[i].order == ord && eq_meta[i].point == 2, 1:n_eq)
        (pt1 + pt2 > 0) && @printf("    ord %d: %d from pt1, %d from pt2\n", ord, pt1, pt2)
    end

    println("  Data equations by order:")
    for ord in 0:10
        pt1 = count(i -> eq_meta[i].is_data && eq_meta[i].order == ord && eq_meta[i].point == 1, 1:n_eq)
        pt2 = count(i -> eq_meta[i].is_data && eq_meta[i].order == ord && eq_meta[i].point == 2, 1:n_eq)
        (pt1 + pt2 > 0) && @printf("    ord %d: %d from pt1, %d from pt2\n", ord, pt1, pt2)
    end

    # Top-down stripping
    println("\n=== TOP-DOWN STRIPPING ===")
    struct_indices = [i for (i, m) in enumerate(eq_meta) if !m.is_data]
    data_indices = [i for (i, m) in enumerate(eq_meta) if m.is_data]
    struct_by_order = sort(struct_indices; by=i -> -eq_meta[i].order)
    kept = trues(n_eq)

    for idx in struct_by_order
        kept[idx] = false
        struct_vars = Set{Any}()
        for i in 1:n_eq
            kept[i] && !eq_meta[i].is_data && union!(struct_vars, Symbolics.get_variables(combined[i]))
        end
        cascaded = Int[]
        for di in data_indices
            !kept[di] && continue
            dv = first(Symbolics.get_variables(combined[di]))
            if !(dv in struct_vars)
                kept[di] = false
                push!(cascaded, di)
            end
        end
        re = count(kept)
        rv_set = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq; kept[i] && union!(rv_set, Symbolics.get_variables(combined[i])); end
        rv_count = length(rv_set)
        m = eq_meta[idx]
        cascade_names = [string(first(Symbolics.get_variables(combined[di]))) for di in cascaded]
        cascade_str = isempty(cascaded) ? "" : " + data: $(join(cascade_names, ", "))"
        @printf("  -struct(pt%d ord=%d)%s → %d eqs, %d vars (Δ=%d)\n",
            m.point, m.order, cascade_str, re, rv_count, re - rv_count)
        if re == rv_count
            println("  → SQUARE!")
            break
        end
        if re < rv_count
            println("  → UNDERDETERMINED!")
            kept[idx] = true
            for di in cascaded; kept[di] = true; end
            break
        end
    end

    # Final system
    remaining = combined[kept]
    rv = OrderedCollections.OrderedSet{Any}()
    for eq in remaining; union!(rv, Symbolics.get_variables(eq)); end
    remaining_vars = collect(rv)

    remaining_struct = count(i -> kept[i] && !eq_meta[i].is_data, 1:n_eq)
    remaining_data = count(i -> kept[i] && eq_meta[i].is_data, 1:n_eq)
    max_remaining = maximum(eq_meta[i].order for i in 1:n_eq if kept[i])

    println("\n=== 2-POINT STRIPPED SYSTEM ===")
    println("  $(length(remaining)) eqs, $(length(remaining_vars)) vars")
    println("  $remaining_struct structural + $remaining_data data")
    println("  Max derivative order: $max_remaining")
    println("  Square: $(length(remaining) == length(remaining_vars))")

    # What was removed?
    removed_struct = count(i -> !kept[i] && !eq_meta[i].is_data, 1:n_eq)
    removed_data = count(i -> !kept[i] && eq_meta[i].is_data, 1:n_eq)
    println("\n  Removed: $removed_struct structural + $removed_data data = $(removed_struct + removed_data) total")
    println("  Removed structural by order:")
    for ord in 0:10
        pt1 = count(i -> !kept[i] && !eq_meta[i].is_data && eq_meta[i].order == ord && eq_meta[i].point == 1, 1:n_eq)
        pt2 = count(i -> !kept[i] && !eq_meta[i].is_data && eq_meta[i].order == ord && eq_meta[i].point == 2, 1:n_eq)
        (pt1 + pt2 > 0) && @printf("    ord %d: %d from pt1, %d from pt2\n", ord, pt1, pt2)
    end
    println("  Removed data by order:")
    for ord in 0:10
        n_removed = count(i -> !kept[i] && eq_meta[i].is_data && eq_meta[i].order == ord, 1:n_eq)
        n_removed > 0 && @printf("    ord %d: %d removed\n", ord, n_removed)
    end

    # Save the 2-point stripped system
    open("experiments/multipoint/biohydro_2pt_stripped_system.txt", "w") do io
        println(io, "# Biohydrogenation 2-point stripped system")
        println(io, "# Points: t_a=$(t_vec[t_a]), t_b=$(t_vec[t_b])")
        println(io, "# $(length(remaining)) equations, $(length(remaining_vars)) variables")
        println(io, "# True params: $real_params")
        println(io, "# Removed: $removed_struct structural + $removed_data data equations")
        println(io, "# Max derivative order: $max_remaining")
        println(io, "# Before stripping: $n_eq eqs, $n_var vars\n")

        println(io, "# VARIABLES:")
        for (i, v) in enumerate(remaining_vars)
            ord = get_deriv_order(v)
            shared = string(v) in param_set
            println(io, "#   $i. $(rpad(string(v), 14)) order=$ord$(shared ? "  SHARED" : "")")
        end

        println(io, "\n# EQUATIONS:")
        eq_num = 0
        for (orig_i, is_kept) in enumerate(kept)
            if is_kept
                eq_num += 1
                m = eq_meta[orig_i]
                typ = m.is_data ? "DATA  " : "STRUCT"
                println(io, "# $eq_num. [pt$(m.point) $typ ord=$(m.order)] $(string(combined[orig_i])) = 0")
            end
        end
    end
    println("\nSaved to experiments/multipoint/biohydro_2pt_stripped_system.txt")
end

main()
