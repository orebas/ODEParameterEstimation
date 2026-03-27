# Detailed analysis of lotka_volterra equation selection problem
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using Random; include("experiments/multipoint/analyze_lv_equations.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using Random

function analyze_lotka()
    pep = ODEParameterEstimation.lotka_volterra()
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=51, nooutput=true))
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_data; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    model = pep_data.model.system; mq = pep_data.measured_quantities; t_vec = pep_data.data_sample["t"]; n_t = length(t_vec)

    t_a = round(Int, n_t*0.25); t_b = round(Int, n_t*0.75)
    println("Point A: t=$(t_vec[t_a]),  Point B: t=$(t_vec[t_b])")

    ea, va = ODEParameterEstimation.construct_equation_system_from_si_template(model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD; interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_a], precomputed_interpolants=setup.interpolants)
    eb, vb = ODEParameterEstimation.construct_equation_system_from_si_template(model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD; interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_b], precomputed_interpolants=setup.interpolants)

    roles = ODEParameterEstimation._classify_polynomial_variables(string.(va), pep_data)
    param_names = Set(vn for (vn, r) in roles if r == :parameter)
    rd = Dict{Any,Any}()
    for v in vb
        string(v) in param_names && continue
        rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt2"))
    end
    ebr = [Symbolics.substitute(eq, rd) for eq in eb]

    combined = vcat(ea, ebr)
    cvs = OrderedCollections.OrderedSet{Any}()
    for eq in combined; union!(cvs, Symbolics.get_variables(eq)); end
    cv = collect(cvs)
    n_per = length(ea)
    n_var = length(cv)

    println("\n=== SYSTEM: $(length(combined)) equations, $n_var variables ===\n")

    # Variables
    println("VARIABLES ($n_var):")
    for (i, v) in enumerate(cv)
        parsed = ODEParameterEstimation.parse_derivative_variable_name(string(v))
        ord = isnothing(parsed) ? 0 : parsed[2]
        shared = string(v) in param_names
        println("  $(rpad(i, 3)) $(rpad(string(v), 14)) order=$ord $(shared ? " SHARED" : "")")
    end

    # Equations with derivative order
    eq_ords = Int[]
    println("\nEQUATIONS ($n_per from A + $n_per from B = $(length(combined))):")
    for (i, eq) in enumerate(combined)
        src = i <= n_per ? "A$(lpad(i, 2))" : "B$(lpad(i-n_per, 2))"
        mo = 0
        for v in Symbolics.get_variables(eq)
            p = ODEParameterEstimation.parse_derivative_variable_name(string(v))
            !isnothing(p) && (mo = max(mo, p[2]))
        end
        push!(eq_ords, mo)
        nv = length(Symbolics.get_variables(eq))
        is_data = nv == 1
        println("  $(rpad(i, 3)) [$src] ord=$mo $(is_data ? "DATA  " : "STRUCT") nv=$nv : $(string(eq))")
    end

    # Full Jacobian
    rp = randn(n_var) .* 10
    f = ODEParameterEstimation._compile_system_function(combined, cv)
    J = ForwardDiff.jacobian(f, rp)
    println("\nFull Jacobian: $(size(J)), rank=$(rank(J; atol=1e-8)) (need $n_var)")

    # Interleaved greedy trace
    println("\n=== INTERLEAVED GREEDY (A1,B1,A2,B2,...) ===")
    interleaved = Int[]
    for i in 1:n_per; push!(interleaved, i); push!(interleaved, n_per + i); end

    sel = Int[]; cur = zeros(eltype(J), 0, n_var); cr = 0
    for idx in interleaved
        test = vcat(cur, J[idx:idx, :]); r = rank(test; atol=1e-8)
        src = idx <= n_per ? "A$(idx)" : "B$(idx-n_per)"
        if r > cr
            push!(sel, idx); cur = test; cr = r
            @printf("  +Eq%-3d (%s) ord=%d  rank -> %d\n", idx, src, eq_ords[idx], cr)
        else
            @printf("  -Eq%-3d (%s) ord=%d  REJECTED (rank stays %d)\n", idx, src, eq_ords[idx], cr)
        end
        cr == n_var && (println("  DONE - SQUARE"); break)
    end
    println("  Result: $(length(sel))/$n_var")

    rejected = setdiff(Set(1:length(combined)), Set(sel))
    if length(sel) < n_var
        println("\n  STUCK! Rejected equations: $(sort(collect(rejected)))")
        println("  Pairs that would reach rank $n_var:")
        for i in sort(collect(rejected))
            for j in sort(collect(rejected))
                i >= j && continue
                test = vcat(cur, J[i:i, :], J[j:j, :])
                r = rank(test; atol=1e-8)
                si = i <= n_per ? "A$(i)" : "B$(i-n_per)"
                sj = j <= n_per ? "A$(j)" : "B$(j-n_per)"
                r > cr && @printf("    Eq%d (%s) + Eq%d (%s) -> rank=%d\n", i, si, j, sj, r)
            end
        end
    end

    # Find a working permutation
    println("\n=== SEARCHING FOR WORKING PERMUTATIONS ===")
    found_count = 0
    for trial in 1:200
        perm = randperm(length(combined))
        sel2 = Int[]; cur2 = zeros(eltype(J), 0, n_var); cr2 = 0
        for idx in perm
            test = vcat(cur2, J[idx:idx, :]); r = rank(test; atol=1e-8)
            if r > cr2; push!(sel2, idx); cur2 = test; cr2 = r; end
            cr2 == n_var && break
        end
        if length(sel2) == n_var
            found_count += 1
            a_in = sort(filter(i -> i <= n_per, sel2))
            b_in = sort(filter(i -> i > n_per, sel2))
            a_out = setdiff(1:n_per, a_in)
            b_out = setdiff(1:n_per, b_in .- n_per)
            if found_count <= 5
                println("  Trial $trial: A kept=$a_in dropped=$(collect(a_out))  B kept=$(b_in .- n_per) dropped=$(collect(b_out))")
            end
        end
    end
    println("  Found $found_count / 200 working permutations")

    # The principled approach: just use ALL equations and compute the rank-revealing factorization
    println("\n=== PRINCIPLED APPROACH: RANK-REVEALING QR ===")
    # QR with column pivoting on J^T gives us the best n_var rows
    F = qr(transpose(J), ColumnNorm())
    # The first n_var pivots give the best rows
    pivot_rows = F.p[1:n_var]
    println("  QR pivot selection: equations $(sort(pivot_rows))")
    a_qr = sort(filter(i -> i <= n_per, pivot_rows))
    b_qr = sort(filter(i -> i > n_per, pivot_rows))
    println("  From A: $a_qr ($(length(a_qr)) eqs)")
    println("  From B: $(b_qr .- n_per) ($(length(b_qr)) eqs)")

    # Check rank
    J_qr = J[pivot_rows, :]
    println("  Rank of QR selection: $(rank(J_qr; atol=1e-8))/$n_var")
end

analyze_lotka()
