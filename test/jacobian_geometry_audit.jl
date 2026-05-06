using ODEParameterEstimation, ModelingToolkit, OrderedCollections, CSV, Printf, LinearAlgebra, ForwardDiff
using ModelingToolkit: t_nounits as t, D_nounits as D
const ODEPE = ODEParameterEstimation

parameters = @parameters a12 a13 a21 a31 a01
states = @variables x1(t) x2(t) x3(t)
observables = @variables y1(t) y2(t)
state_equations = [
    D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
    D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
    D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
]
measured_quantities = [y1 ~ 0.5 * x1, y2 ~ x2]
ic = [0.139, 0.303, 0.457]; p_true = [0.52, 0.7, 0.367, 0.839, 0.79]
model, mq = create_ordered_ode_system("daisy_mamil3", states, parameters, state_equations, measured_quantities)
datadir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4"
csv_data = CSV.read(joinpath(datadir, "data.csv"), Tuple, header = false)
data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq); data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1]); end
pep = ParameterEstimationProblem("daisy_mamil3", model, mq, data_sample, [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)
setup = ODEPE.setup_parameter_estimation(pep; interpolator = aaad_gpr_pivot, nooutput = true)
max_order = maximum(values(setup.good_deriv_level))
t_vec = data_sample["t"]; n_t = length(t_vec)
ordered_model = isa(pep.model.system, OrderedODESystem) ? pep.model.system : begin
    (_, _, s, p) = ODEPE.unpack_ODE(pep.model.system); OrderedODESystem(pep.model.system, s, p); end
si_template, _ = ODEPE.prepare_si_template_with_structural_fix(ordered_model, pep.measured_quantities, pep.data_sample,
    setup.good_DD, false; states = setup.states, params = setup.params)

mpt_s = (good_deriv_level = setup.good_deriv_level, good_udict = setup.good_udict,
    good_varlist = setup.good_varlist, good_DD = setup.good_DD, interpolants = setup.interpolants)
mpt = build_multipoint_template(pep, mpt_s, si_template; n_points = 2)
mp_tv = [t_vec[max(2, round(Int, n_t * 0.25))], t_vec[min(n_t - 1, round(Int, n_t * 0.75))]]

mp_sts = []; mp_ots = []
for te in mp_tv
    st = ODEPE.compute_oracle_taylor_coefficients(pep, te, max_order + 2)
    ot = ODEPE.compute_observable_taylor_coefficients(pep, st, te, max_order + 2)
    push!(mp_sts, st); push!(mp_ots, ot)
end

x_true = [ODEPE._lookup_multipoint_true_value(string(v), pep, mp_tv, mp_sts, mp_ots) for v in mpt.solve_vars]
d_true = [ODEPE._lookup_multipoint_true_value(string(v), pep, mp_tv, mp_sts, mp_ots) for v in mpt.data_vars]
ti = [argmin(abs.(t_vec .- te)) for te in mp_tv]
ev = evaluate_multipoint_template(mpt, ti, setup.interpolants, pep.data_sample)
d_prod = Float64.(ev.data_values)

sols = solve_multipoint_direct(ev)
x_hc = let best = Float64[], bd = Inf
    for s in sols; d2 = norm(Float64.(s) .- x_true); if d2 < bd; bd = d2; best = Float64.(s); end; end; best; end

n_x = length(mpt.solve_vars); n_d = length(mpt.data_vars)
mp_xl = string.(mpt.solve_vars)
combined_vars = [mpt.solve_vars..., mpt.data_vars...]
f = ODEPE._compile_system_function(mpt.stripped_equations, combined_vars)

pt_true = [x_true..., d_true...]
pt_hc = [x_hc..., d_prod...]

J_true = ForwardDiff.jacobian(f, pt_true)
J_hc = ForwardDiff.jacobian(f, pt_hc)
Jx_true = J_true[:, 1:n_x]
Jx_hc = J_hc[:, 1:n_x]

# ═══════════════════════════════════════════════════════════════════════════
println("=" ^ 70)
println("GEOMETRY OF ILL-CONDITIONING IN MP Jx")
println("=" ^ 70)

# SVD at true point
U_t, σ_t, V_t = svd(Jx_true)
U_h, σ_h, V_h = svd(Jx_hc)

println("\n1. SINGULAR VALUE SPECTRUM")
println()
@printf("%-5s  %15s  %15s  %12s\n", "#", "σ (at true)", "σ (at HC)", "ratio HC/true")
println("-" ^ 52)
for i in 1:n_x
    ratio = σ_t[i] > 1e-300 ? σ_h[i] / σ_t[i] : NaN
    flag = i >= n_x - 2 ? " ← SMALL" : ""
    @printf("%-5d  %15.6e  %15.6e  %12.4f%s\n", i, σ_t[i], σ_h[i], ratio, flag)
end
@printf("\nκ(Jx_true) = %.4e\n", σ_t[1] / σ_t[end])
@printf("κ(Jx_hc)   = %.4e\n", σ_h[1] / σ_h[end])

# ═══════════════════════════════════════════════════════════════════════════
println("\n2. NEAR-NULL RIGHT SINGULAR VECTORS AT TRUE POINT")
println("   (directions in x-space that Jx nearly annihilates)")
println()

# The last few columns of V are the near-null directions
for k in 0:2
    idx = n_x - k
    v = V_t[:, idx]
    println("v_$(idx) (σ = $(@sprintf("%.4e", σ_t[idx]))):")
    # Show which variables have large components
    sorted = sortperm(abs.(v); rev = true)
    for j in sorted[1:min(8, n_x)]
        if abs(v[j]) > 0.01
            @printf("  %-20s  %+.4f\n", mp_xl[j], v[j])
        end
    end
    println()
end

# ═══════════════════════════════════════════════════════════════════════════
println("3. NEAR-NULL RIGHT SINGULAR VECTORS AT HC POINT")
println()
for k in 0:2
    idx = n_x - k
    v = V_h[:, idx]
    println("v_$(idx) (σ = $(@sprintf("%.4e", σ_h[idx]))):")
    sorted = sortperm(abs.(v); rev = true)
    for j in sorted[1:min(8, n_x)]
        if abs(v[j]) > 0.01
            @printf("  %-20s  %+.4f\n", mp_xl[j], v[j])
        end
    end
    println()
end

# ═══════════════════════════════════════════════════════════════════════════
println("4. WHAT MAKES Jx ILL-CONDITIONED AT TRUE?")
println()

# The actual displacement Δx = x_hc - x_true projected onto singular vectors
dx = x_hc .- x_true
println("Displacement Δx projected onto right singular vectors of Jx_true:")
@printf("%-5s  %12s  %12s  %15s\n", "k", "σ_k", "Δx·v_k", "σ_k × |Δx·v_k|")
println("-" ^ 48)
for k in 1:n_x
    proj = dot(dx, V_t[:, k])
    product = σ_t[k] * abs(proj)
    flag = k >= n_x - 2 ? " ← near-null" : ""
    @printf("%-5d  %12.4e  %+12.4e  %15.4e%s\n", k, σ_t[k], proj, product, flag)
end

println()
println("If Δx has large projection onto the near-null vectors,")
println("it means the actual displacement goes mostly in directions")
println("where Jx can't distinguish — the nonlinearity resolves the")
println("ambiguity that the linearization can't.")

# ═══════════════════════════════════════════════════════════════════════════
println("\n5. WHY IS Jx NEAR-SINGULAR AT TRUE BUT NOT AT HC?")
println()

# The key: x3 is very small at the true values (x3 ≈ 0.15-0.46)
# The equations have terms like a13*x3 and a31*x1.
# At x_true, x3_0 = 0.1508, x1_0 = 0.1097 — both small.
# The derivatives ∂(a13*x3)/∂a13 = x3 and ∂(a13*x3)/∂x3 = a13.
# When x3 is small, the column of Jx for a13 has small entries,
# making it nearly parallel to other columns → near-singularity.

# At x_hc, a13_hc = 1.19 and x3_0_hc = 0.219 — larger values
# → better-conditioned columns.

println("Key variable values comparison:")
@printf("%-12s  %12s  %12s  %12s\n", "Variable", "true", "HC", "ratio")
println("-" ^ 52)
for label in ["a13_0", "a31_0", "a01_0", "x3_0", "x3_0_pt2", "x1_0", "x2_0"]
    i = findfirst(==(label), mp_xl)
    isnothing(i) && continue
    ratio = abs(x_true[i]) > 1e-300 ? x_hc[i] / x_true[i] : NaN
    @printf("%-12s  %+12.6f  %+12.6f  %12.4f\n", label, x_true[i], x_hc[i], ratio)
end

println()
println("The equations contain bilinear terms like a13*x3 and a31*x1.")
println("∂F/∂a13 contains x3 as a coefficient, and ∂F/∂x3 contains a13.")
println()
println("At true values: x3_0 = $(round(x_true[findfirst(==("x3_0"), mp_xl)]; digits=4)),",
    " a13 = $(round(x_true[findfirst(==("a13_0"), mp_xl)]; digits=4))")
println("At HC values:   x3_0 = $(round(x_hc[findfirst(==("x3_0"), mp_xl)]; digits=4)),",
    " a13 = $(round(x_hc[findfirst(==("a13_0"), mp_xl)]; digits=4))")
println()
println("The products a13*x3 are:")
i_a13 = findfirst(==("a13_0"), mp_xl)
i_x3 = findfirst(==("x3_0"), mp_xl)
println("  At true: $(round(x_true[i_a13] * x_true[i_x3]; digits=6))")
println("  At HC:   $(round(x_hc[i_a13] * x_hc[i_x3]; digits=6))")
println()
println("When x3 is small, the column ∂F/∂a13 (which is proportional to x3)")
println("becomes nearly zero, making Jx rank-deficient. At the HC solution,")
println("x3 and a13 are both larger, so the cross-terms are better balanced")
println("and Jx is better conditioned.")
