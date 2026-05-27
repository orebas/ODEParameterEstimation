# Experiment: confirm branch-completion HC failure is caused by pure-monomial
# (mixed_volume=0) + In_0≈0 degeneracy, and that cascade-eliminating the
# single-variable equations before HC recovers the real algebraic branches.
using ODEParameterEstimation
using Symbolics
using HomotopyContinuation
using LinearAlgebra
const HC = HomotopyContinuation

# Variables in the exact dump order
@variables In_0 nu_0 a_0 E_0 In_1 N_0 N_1 E_1 In_2 b_0 S_0 In_3 E_2 S_1 In_4 E_3 N_2 S_2 E_4 In_5 S_3 N_3 In_6 E_5 N_4 S_4
varlist = [In_0, nu_0, a_0, E_0, In_1, N_0, N_1, E_1, In_2, b_0, S_0, In_3, E_2, S_1, In_4, E_3, N_2, S_2, E_4, In_5, S_3, N_3, In_6, E_5, N_4, S_4]

eq_strs = [
    "1.2795795700830634e-13 - In_0",
    "In_1 - E_0*nu_0 + In_0*a_0",
    "1000.0 - N_0",
    "N_1",
    "1.499999999999488 - In_1",
    "In_2 - E_1*nu_0 + In_1*a_0",
    "E_1*N_0 + E_0*N_0*nu_0 - In_0*S_0*b_0",
    "-0.5250000000023717 - In_2",
    "In_3 - E_2*nu_0 + In_2*a_0",
    "E_1*N_1 + E_2*N_0 + E_0*N_1*nu_0 + E_1*N_0*nu_0 - In_0*S_1*b_0 - In_1*S_0*b_0",
    "N_0*S_1 + In_0*S_0*b_0",
    "0.22785000003994654 - In_3",
    "In_4 - E_3*nu_0 + In_3*a_0",
    "E_1*N_2 + (2//1)*E_2*N_1 + E_3*N_0 + E_0*N_2*nu_0 + (2//1)*E_1*N_1*nu_0 + E_2*N_0*nu_0 - In_0*S_2*b_0 - (2//1)*In_1*S_1*b_0 - In_2*S_0*b_0",
    "N_0*S_2 + N_1*S_1 + In_0*S_1*b_0 + In_1*S_0*b_0",
    "N_2",
    "-0.09518250002782218 - In_4",
    "In_5 - E_4*nu_0 + In_4*a_0",
    "E_1*N_3 + (3//1)*E_2*N_2 + (3//1)*E_3*N_1 + E_4*N_0 + E_0*N_3*nu_0 + (3//1)*E_1*N_2*nu_0 + (3//1)*E_2*N_1*nu_0 + E_3*N_0*nu_0 - In_0*S_3*b_0 - (3//1)*In_1*S_2*b_0 - (3//1)*In_2*S_1*b_0 - In_3*S_0*b_0",
    "N_3",
    "N_0*S_3 + (2//1)*N_1*S_2 + N_2*S_1 + In_0*S_2*b_0 + (2//1)*In_1*S_1*b_0 + In_2*S_0*b_0",
    "0.03985228323336705 - In_5",
    "In_6 - E_5*nu_0 + In_5*a_0",
    "E_1*N_4 + (4//1)*E_2*N_3 + (6//1)*E_3*N_2 + (4//1)*E_4*N_1 + E_5*N_0 + E_0*N_4*nu_0 + (4//1)*E_1*N_3*nu_0 + (6//1)*E_2*N_2*nu_0 + (4//1)*E_3*N_1*nu_0 + E_4*N_0*nu_0 - In_0*S_4*b_0 - (4//1)*In_1*S_3*b_0 - (6//1)*In_2*S_2*b_0 - (4//1)*In_3*S_1*b_0 - In_4*S_0*b_0",
    "N_0*S_4 + (3//1)*N_1*S_3 + (3//1)*N_2*S_2 + N_3*S_1 + In_0*S_3*b_0 + (3//1)*In_1*S_2*b_0 + (3//1)*In_2*S_1*b_0 + In_3*S_0*b_0",
    "N_4",
]
eqs = [eval(Meta.parse(s)) for s in eq_strs]

println("="^70)
println("STEP 1: full 26x26 system — reproduce the failure + mixed volume")
println("="^70)
hc_full, hcv_full = ODEParameterEstimation.convert_to_hc_format(eqs, varlist)
println("mixed_volume(full) = ", HC.mixed_volume(hc_full))
sols_full, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs, varlist)
println("solve_with_hc(full) real-root count = ", length(sols_full))

println()
println("="^70)
println("STEP 2: cascade-eliminate single-variable equations, then HC")
println("="^70)
function cascade_eliminate(eqs)
    cascade_subst = Dict{Any,Any}()
    reduced = copy(eqs)
    changed = true
    passn = 0
    while changed
        changed = false
        passn += 1
        keep = eltype(reduced)[]
        for eq in reduced
            vs = Symbolics.get_variables(eq)
            if isempty(vs)
                continue
            elseif length(vs) == 1
                v = only(vs)
                haskey(cascade_subst, v) && continue
                try
                    cascade_subst[v] = Symbolics.symbolic_linear_solve(eq, v)
                    changed = true
                catch
                    push!(keep, eq)
                end
            else
                push!(keep, eq)
            end
        end
        reduced = changed ? Symbolics.substitute.(keep, Ref(cascade_subst)) : keep
    end
    return cascade_subst, reduced, passn
end
cascade_subst, reduced, passn = cascade_eliminate(eqs)
println("cascade passes = ", passn, ", eliminated vars = ", length(cascade_subst))
println("eliminated: ", sort(string.(keys(cascade_subst))))

rem_vars = Symbolics.OrderedSet()
rem_eqs = eltype(reduced)[]
for eq in reduced
    vs = Symbolics.get_variables(eq)
    if !isempty(vs)
        push!(rem_eqs, eq)
        union!(rem_vars, vs)
    end
end
rem_vars = collect(rem_vars)
println("reduced system: ", length(rem_eqs), " eqs, ", length(rem_vars), " vars")
println("reduced vars: ", string.(rem_vars))
for (i,eq) in enumerate(rem_eqs)
    println("  R$i: ", eq)
end

vidx(v) = findfirst(x -> isequal(x, v), rem_vars)
# anchor values for the reduced vars
anchor_map = Dict(
    nu_0 => 0.2667924533631822, E_0 => 5.62234793784651, a_0 => 0.08320754663852091,
    E_1 => -1.499999999999474, b_0 => 0.46047786217746406, S_0 => 420.01056337722684,
    E_2 => 0.6902970295183805, S_1 => -2.4747781139816777e-14, E_3 => -0.2857039603708308,
    S_2 => -0.29010834947374753, E_4 => 0.11968997068916998, S_3 => 0.10153792231630504,
    In_6 => -0.016559552554221674, E_5 => -0.04963986676340287, S_4 => -0.04346631016625864,
)
anchor_red = [Float64(anchor_map[v]) for v in rem_vars]

if length(rem_eqs) == length(rem_vars) && length(rem_vars) > 0
    hc_red, hcv_red = ODEParameterEstimation.convert_to_hc_format(rem_eqs, rem_vars)
    println("mixed_volume(reduced) = ", HC.mixed_volume(hc_red))

    # (a) is the anchor a genuine root of the reduced system?
    resid_anchor = norm(HC.evaluate(hc_red, ComplexF64.(anchor_red)))
    println("reduced-system residual at anchor = ", resid_anchor)

    # (b) Jacobian condition number at the anchor
    J = HC.jacobian(hc_red, ComplexF64.(anchor_red))
    println("cond(Jacobian at anchor) = ", cond(real.(J)))
    println("svdvals(Jacobian) min/max = ", minimum(svdvals(real.(J))), " / ", maximum(svdvals(real.(J))))

    # (c) Newton from anchor on the REDUCED system (full system rejected per doc)
    nr = HC.newton(hc_red, ComplexF64.(anchor_red); atol=1e-12, rtol=1e-12, max_iters=50, extended_precision=true)
    println("Newton-from-anchor (reduced): return=", nr.return_code, " accuracy=", nr.accuracy)
    xn = nr.x
    println("  Newton |Δ from anchor| = ", norm(real.(xn) .- anchor_red),
            "  max|imag| = ", maximum(abs.(imag.(xn))))

    # (d) global solve on reduced — characterize ALL solutions
    raw = HC.solve(hc_red, show_progress=false)
    allsol = HC.solutions(raw; only_nonsingular=false)
    println("reduced global solve: ", length(allsol), " total solutions")
    nu_i, a_i, b_i, S_i = vidx(nu_0), vidx(a_0), vidx(b_0), vidx(S_0)
    for (j,s) in enumerate(allsol)
        println("  root $j: a=", round(real(s[a_i]),digits=5), " b=", round(real(s[b_i]),digits=5),
                " nu=", round(real(s[nu_i]),digits=5), " S0=", round(real(s[S_i]),digits=3),
                "  max|imag|=", round(maximum(abs.(imag.(s))),sigdigits=3))
    end
    println()
    println("EXPECTED branches:")
    println("  branch 1: a=0.08321 b=0.46048 nu=0.26679 S0=420.011")
    println("  branch 2: a=0.06799 b=0.48915 nu=0.28201 S0=352.132")
else
    println("reduced system NOT square — needs further handling")
end
