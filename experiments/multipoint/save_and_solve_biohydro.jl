# Build biohydrogenation 2-point stripped system, save it, try multiple HC.jl methods
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using Random; using HomotopyContinuation; include("experiments/multipoint/save_and_solve_biohydro.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using Random
using HomotopyContinuation
using Serialization

function get_deriv_order(name_str)
    clean = replace(string(name_str), r"_pt\d+$" => "")
    parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
    return isnothing(parsed) ? 0 : parsed[2]
end

function build_stripped_system(name, pep; n_data=51, t_interval=nothing, n_points=2)
    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, noise_level=0.0, nooutput=true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    model = pep_work.model.system; mq = pep_work.measured_quantities
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end

    roles = nothing
    si_tmpl = try
        ordered_model = ODEParameterEstimation.OrderedODESystem(model, ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model))
        t, _ = ODEParameterEstimation.prepare_si_template_with_structural_fix(
            ordered_model, mq, pep_work.data_sample, setup.good_DD, false;
            states=ModelingToolkit.unknowns(model), params=ModelingToolkit.parameters(model), infolevel=0)
        t
    catch; nothing; end

    function build_at(t_idx)
        ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_idx],
            precomputed_interpolants=setup.interpolants, si_template=si_tmpl)
    end

    fracs = n_points == 2 ? [0.25, 0.75] : collect(range(0.15, 0.85; length=n_points))
    t_indices = [max(2, min(n_t-1, round(Int, n_t * f))) for f in fracs]

    all_eqs = []; all_vars_list = []
    for t_idx in t_indices
        eqs, vars = build_at(t_idx)
        roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
        push!(all_eqs, eqs); push!(all_vars_list, vars)
    end

    param_set = Set(vn for (vn, r) in roles if r == :parameter)

    # Combine with renaming
    combined_eqs = Num[]
    eq_meta = []
    for (pt, eqs) in enumerate(all_eqs)
        if pt == 1
            for (i, eq) in enumerate(eqs)
                push!(combined_eqs, eq)
                nv = length(Symbolics.get_variables(eq))
                mo = maximum(get_deriv_order(v) for v in Symbolics.get_variables(eq))
                push!(eq_meta, (point=pt, is_data=nv==1, order=mo))
            end
        else
            rd = Dict{Any,Any}()
            for v in all_vars_list[pt]
                string(v) in param_set && continue
                rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt$(pt)"))
            end
            for (i, eq) in enumerate(eqs)
                push!(combined_eqs, Symbolics.substitute(eq, rd))
                nv = length(Symbolics.get_variables(eq))
                mo = maximum(get_deriv_order(v) for v in Symbolics.get_variables(eq))
                push!(eq_meta, (point=pt, is_data=nv==1, order=mo))
            end
        end
    end

    cvs = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs; union!(cvs, Symbolics.get_variables(eq)); end
    combined_vars = collect(cvs)
    n_eq = length(combined_eqs); n_var = length(combined_vars)

    # Top-down stripping with cascading
    struct_indices = [i for (i, m) in enumerate(eq_meta) if !m.is_data]
    data_indices = [i for (i, m) in enumerate(eq_meta) if m.is_data]
    struct_by_order = sort(struct_indices; by=i -> -eq_meta[i].order)

    kept = trues(n_eq)
    for idx in struct_by_order
        kept[idx] = false
        struct_vars = Set{Any}()
        for i in 1:n_eq; kept[i] && !eq_meta[i].is_data && union!(struct_vars, Symbolics.get_variables(combined_eqs[i])); end
        for di in data_indices
            !kept[di] && continue
            dv = first(Symbolics.get_variables(combined_eqs[di]))
            !(dv in struct_vars) && (kept[di] = false)
        end
        re = count(kept)
        rv_set = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq; kept[i] && union!(rv_set, Symbolics.get_variables(combined_eqs[i])); end
        if re == length(rv_set)
            break
        elseif re < length(rv_set)
            kept[idx] = true
            for di in data_indices; kept[di] || (kept[di] = true); end  # crude restore
            break
        end
    end

    remaining_eqs = combined_eqs[kept]
    rv = OrderedCollections.OrderedSet{Any}()
    for eq in remaining_eqs; union!(rv, Symbolics.get_variables(eq)); end
    remaining_vars = collect(rv)

    return (eqs=remaining_eqs, vars=remaining_vars, real_params=real_params,
            param_set=param_set, name=name, pep_work=pep_work)
end

# ═══════════════════════════════════════════════════════════════════════════

println("Building biohydrogenation 2-point stripped system...")
flush(stdout)
sys = build_stripped_system("biohydrogenation", ODEParameterEstimation.biohydrogenation();
    t_interval=[0.0, 1.0])

println("System: $(length(sys.eqs)) eqs, $(length(sys.vars)) vars")
println("Square: $(length(sys.eqs) == length(sys.vars))")
println("Variables: ", [string(v) for v in sys.vars])
println("True params: ", sys.real_params)
flush(stdout)

# Convert to HC.jl
println("\nConverting to HC.jl format...")
flush(stdout)
hc_system, hc_variables = ODEParameterEstimation.convert_to_hc_format(sys.eqs, sys.vars)
println("HC system created with $(length(hc_variables)) variables")
bez = try; HomotopyContinuation.bezout_number(hc_system); catch e; "error: $e"; end
println("Bezout bound: $bez")
flush(stdout)

# Save the HC system
serialize("experiments/multipoint/biohydro_hc_system.jls", (hc_system=hc_system, hc_variables=hc_variables,
    real_params=sys.real_params, param_set=sys.param_set))
println("Saved to experiments/multipoint/biohydro_hc_system.jls")

# Also save equations as strings for readability
open("experiments/multipoint/biohydro_equations.txt", "w") do io
    println(io, "# Biohydrogenation 2-point stripped system")
    println(io, "# $(length(sys.eqs)) equations, $(length(sys.vars)) variables")
    println(io, "# True params: $(sys.real_params)")
    println(io, "\n# Variables:")
    for (i, v) in enumerate(sys.vars)
        println(io, "#   $i. $(string(v))")
    end
    println(io, "\n# Equations:")
    for (i, eq) in enumerate(sys.eqs)
        println(io, "#   $i. $(string(eq)) = 0")
    end
end
println("Saved equations to experiments/multipoint/biohydro_equations.txt")
flush(stdout)

# ═══════════════════════════════════════════════════════════════════════════
# Try different HC.jl solving methods
# ═══════════════════════════════════════════════════════════════════════════

println("\n=== HC.jl solve attempts ===")
flush(stdout)

# Method 1: Default (polyhedral)
println("\n--- Method 1: Default polyhedral homotopy ---")
flush(stdout)
t0 = time()
try
    result = HomotopyContinuation.solve(hc_system; show_progress=false)
    elapsed = time() - t0
    real_sols = HomotopyContinuation.solutions(result; only_real=true, real_tol=1e-6)
    println("  $(HomotopyContinuation.nresults(result)) paths, $(length(real_sols)) real, $(round(elapsed; digits=1))s")
catch e
    println("  FAILED: $(sprint(showerror, e)[1:min(80,end)])")
end
flush(stdout)

# Method 2: Total degree — SKIPPED (Bezout 2.6M paths = hours)
println("\n--- Method 2: Total degree --- SKIPPED (too many paths)")
flush(stdout)

# Method 3: Monodromy
println("\n--- Method 3: Monodromy ---")
flush(stdout)
t0 = time()
try
    # Monodromy needs a known solution to start from.
    # Use Newton from a random starting point to find one.
    # Or use a parameter homotopy trick.

    # First try: just call monodromy_solve directly
    result = HomotopyContinuation.monodromy_solve(hc_system; show_progress=false, max_loops_no_progress=10)
    elapsed = time() - t0
    sols = HomotopyContinuation.solutions(result)
    println("  Found $(length(sols)) solutions, $(round(elapsed; digits=1))s")
    for (i, s) in enumerate(sols[1:min(3,end)])
        println("  sol$i: ", round.(Float64.(real.(s)); sigdigits=4))
    end
catch e
    println("  FAILED: $(sprint(showerror, e)[1:min(80,end)])")
end
flush(stdout)

# Method 4: Monodromy with a Newton-found starting solution
println("\n--- Method 4: Newton start + monodromy ---")
flush(stdout)
t0 = time()
try
    # Find a starting solution via Newton from random point
    f_sym = ODEParameterEstimation._compile_system_function(sys.eqs, sys.vars)

    best_newton = nothing
    best_res = Inf
    for trial in 1:20
        x0 = randn(length(sys.vars)) .* 5
        local xc = copy(x0)
        for iter in 1:50
            r = f_sym(xc)
            nr = norm(r)
            nr < 1e-10 && break
            J = ForwardDiff.jacobian(f_sym, xc)
            rank(J) < length(xc) && break
            xc = xc .- (J \ r)
        end
        r = norm(f_sym(xc))
        if r < best_res
            best_res = r
            best_newton = xc
        end
    end

    if best_res < 1e-6
        println("  Found Newton solution: residual=$(Printf.@sprintf("%.2e", best_res))")
        # Convert to HC solution format and use for monodromy
        start_sol = ComplexF64.(best_newton)
        result = HomotopyContinuation.monodromy_solve(hc_system, [start_sol];
            show_progress=false, max_loops_no_progress=10)
        elapsed = time() - t0
        sols = HomotopyContinuation.solutions(result)
        println("  Monodromy found $(length(sols)) solutions, $(round(elapsed; digits=1))s")

        # Score against true params
        pidxs = [i for (i, v) in enumerate(sys.vars) if string(v) in sys.param_set]
        pnames = [replace(string(sys.vars[i]), "_0" => "") for i in pidxs]
        for (si, sol) in enumerate(sols[1:min(5,end)])
            pvals = Float64.(real.(sol[pidxs]))
            me = maximum(haskey(sys.real_params, pn) ? abs(pvals[j]-sys.real_params[pn])/max(abs(sys.real_params[pn]),1e-10) : 0.0 for (j,pn) in enumerate(pnames))
            param_str = join([Printf.@sprintf("%s=%.3f", pn, pvals[j]) for (j, pn) in enumerate(pnames) if haskey(sys.real_params, pn)], " ")
            println("  sol$si: $param_str  err=$(@sprintf("%.4f", me))")
        end
    else
        println("  Newton failed to find solution (best residual=$(Printf.@sprintf("%.2e", best_res)))")
    end
catch e
    println("  FAILED: $(sprint(showerror, e)[1:min(80,end)])")
    println("  ", sprint(showerror, e))
end
flush(stdout)

println("\nDONE")
