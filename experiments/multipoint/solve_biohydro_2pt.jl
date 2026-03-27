# Solve the biohydrogenation 2-point stripped system with HC.jl
# Save intermediate output so we can see progress
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using HomotopyContinuation; include("experiments/multipoint/solve_biohydro_2pt.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using HomotopyContinuation

# Build the system (same as analyze_biohydro_detailed.jl)
function get_deriv_order(name_str)
    clean = replace(string(name_str), r"_pt\d+$" => "")
    parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
    return isnothing(parsed) ? 0 : parsed[2]
end

function build_system()
    pep = ODEParameterEstimation.biohydrogenation()
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=51, time_interval=[0.0, 1.0], noise_level=0.0, nooutput=true))
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_data; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    model = pep_data.model.system; mq = pep_data.measured_quantities
    t_vec = pep_data.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_data.p_true; real_params[replace(string(k), "(t)" => "")] = v; end

    t_a = round(Int, n_t*0.25); t_b = round(Int, n_t*0.75)
    ea, va = ODEParameterEstimation.construct_equation_system_from_si_template(model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD; interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_a], precomputed_interpolants=setup.interpolants)
    eb, vb = ODEParameterEstimation.construct_equation_system_from_si_template(model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD; interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_b], precomputed_interpolants=setup.interpolants)
    roles = ODEParameterEstimation._classify_polynomial_variables(string.(va), pep_data)
    param_set = Set(vn for (vn, r) in roles if r == :parameter)
    rd = Dict{Any,Any}(); for v in vb; string(v) in param_set && continue
        rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt2")); end
    ebr = [Symbolics.substitute(eq, rd) for eq in eb]
    combined = vcat(ea, ebr)

    # Top-down stripping
    eq_meta = [(point = i <= length(ea) ? 1 : 2,
                is_data = length(Symbolics.get_variables(eq)) == 1,
                order = maximum(get_deriv_order(v) for v in Symbolics.get_variables(eq)))
               for (i, eq) in enumerate(combined)]
    struct_indices = [i for (i, m) in enumerate(eq_meta) if !m.is_data]
    data_indices = [i for (i, m) in enumerate(eq_meta) if m.is_data]
    struct_by_order = sort(struct_indices; by=i -> -eq_meta[i].order)
    n_eq = length(combined)
    kept = trues(n_eq)

    for idx in struct_by_order
        kept[idx] = false
        struct_vars = Set{Any}()
        for i in 1:n_eq; kept[i] && !eq_meta[i].is_data && union!(struct_vars, Symbolics.get_variables(combined[i])); end
        for di in data_indices; !kept[di] && continue
            dv = first(Symbolics.get_variables(combined[di]))
            !(dv in struct_vars) && (kept[di] = false); end
        re = count(kept)
        rv_set = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq; kept[i] && union!(rv_set, Symbolics.get_variables(combined[i])); end
        re == length(rv_set) && break
        re < length(rv_set) && (kept[idx] = true; break)
    end

    remaining = combined[kept]
    rv = OrderedCollections.OrderedSet{Any}()
    for eq in remaining; union!(rv, Symbolics.get_variables(eq)); end
    remaining_vars = collect(rv)

    return (eqs=remaining, vars=remaining_vars, real_params=real_params, param_set=param_set, pep_data=pep_data)
end

function main()
    println("Building biohydrogenation 2-point stripped system...")
    flush(stdout)
    sys = build_system()
    println("System: $(length(sys.eqs)) eqs, $(length(sys.vars)) vars")
    println("Square: $(length(sys.eqs) == length(sys.vars))")
    flush(stdout)

    # Convert to HC.jl
    println("\nConverting to HC.jl...")
    flush(stdout)
    hc_system, hc_vars = ODEParameterEstimation.convert_to_hc_format(sys.eqs, sys.vars)

    bez = try; HomotopyContinuation.bezout_number(hc_system); catch e; "overflow: $e"; end
    println("Bezout bound: $bez")
    flush(stdout)

    # Try polyhedral first
    println("\n=== Method 1: Polyhedral homotopy (default) ===")
    flush(stdout)
    t0 = time()
    try
        result = HomotopyContinuation.solve(hc_system; show_progress=true)
        elapsed = time() - t0
        real_sols = HomotopyContinuation.solutions(result; only_real=true, real_tol=1e-6)
        all_results = HomotopyContinuation.results(result)
        println("\nResult: $(length(all_results)) paths, $(length(real_sols)) real solutions, $(round(elapsed; digits=1))s")
        flush(stdout)

        pidxs = [i for (i, v) in enumerate(sys.vars) if string(v) in sys.param_set]
        pnames = [replace(string(sys.vars[i]), "_0" => "") for i in pidxs]
        for (si, sol) in enumerate(real_sols[1:min(5, end)])
            pvals = Float64.(real.(sol[pidxs]))
            me = maximum(haskey(sys.real_params, pn) ? abs(pvals[j]-sys.real_params[pn])/max(abs(sys.real_params[pn]),1e-10) : 0.0 for (j,pn) in enumerate(pnames))
            param_str = join([@sprintf("%s=%.3f", pn, pvals[j]) for (j, pn) in enumerate(pnames) if haskey(sys.real_params, pn)], " ")
            @printf("  sol%d: %s  err=%.4f\n", si, param_str, me)
            flush(stdout)
        end
    catch e
        elapsed = time() - t0
        println("FAILED after $(round(elapsed; digits=1))s: $(sprint(showerror, e)[1:min(100,end)])")
        flush(stdout)
    end

    # Try total degree with show_progress
    println("\n=== Method 2: Total degree start system ===")
    println("(This tracks $(bez isa String ? "many" : bez) paths — may take a long time)")
    flush(stdout)
    t0 = time()
    try
        result = HomotopyContinuation.solve(hc_system; start_system=:total_degree, show_progress=true)
        elapsed = time() - t0
        real_sols = HomotopyContinuation.solutions(result; only_real=true, real_tol=1e-6)
        all_results = HomotopyContinuation.results(result)
        println("\nResult: $(length(all_results)) paths, $(length(real_sols)) real solutions, $(round(elapsed; digits=1))s")
        flush(stdout)

        pidxs = [i for (i, v) in enumerate(sys.vars) if string(v) in sys.param_set]
        pnames = [replace(string(sys.vars[i]), "_0" => "") for i in pidxs]
        for (si, sol) in enumerate(real_sols[1:min(5, end)])
            pvals = Float64.(real.(sol[pidxs]))
            me = maximum(haskey(sys.real_params, pn) ? abs(pvals[j]-sys.real_params[pn])/max(abs(sys.real_params[pn]),1e-10) : 0.0 for (j,pn) in enumerate(pnames))
            param_str = join([@sprintf("%s=%.3f", pn, pvals[j]) for (j, pn) in enumerate(pnames) if haskey(sys.real_params, pn)], " ")
            @printf("  sol%d: %s  err=%.4f\n", si, param_str, me)
            flush(stdout)
        end
    catch e
        elapsed = time() - t0
        println("FAILED after $(round(elapsed; digits=1))s: $(sprint(showerror, e)[1:min(100,end)])")
        flush(stdout)
    end

    println("\nDONE")
    flush(stdout)
end

main()
