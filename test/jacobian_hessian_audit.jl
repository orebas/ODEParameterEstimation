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
dd = d_prod .- d_true

sols = solve_multipoint_direct(ev)
x_hc = let best = Float64[], bd = Inf
    for s in sols
        d2 = norm(Float64.(s) .- x_true)
        if d2 < bd; bd = d2; best = Float64.(s); end
    end
    best
end

n_x = length(mpt.solve_vars); n_d = length(mpt.data_vars)
combined_vars = [mpt.solve_vars..., mpt.data_vars...]
mp_xl = string.(mpt.solve_vars)
f = ODEPE._compile_system_function(mpt.stripped_equations, combined_vars)

bad_vars = ["a31_0", "a13_0", "a01_0", "x3_0", "x3_1", "x3_0_pt2", "x3_1_pt2", "x3_2_pt2"]

# ═══════════════════════════════════════════════════════════════════════════
pt_true = [x_true..., d_true...]
pt_hc = [x_hc..., d_prod...]

J_true = ForwardDiff.jacobian(f, pt_true)
J_hc = ForwardDiff.jacobian(f, pt_hc)
Jx_true = J_true[:, 1:n_x]; Jd_true = J_true[:, n_x+1:end]
Jx_hc = J_hc[:, 1:n_x]; Jd_hc = J_hc[:, n_x+1:end]
S_true = -(Jx_true \ Jd_true)
S_hc = -(Jx_hc \ Jd_hc)

println("=" ^ 70)
println("1. JACOBIAN COMPARISON: true point vs HC point")
println("=" ^ 70)
@printf("\nκ(Jx) at true:  %.4e\n", cond(Jx_true))
@printf("κ(Jx) at HC:    %.4e\n", cond(Jx_hc))
@printf("\n‖Jx_true - Jx_hc‖ / ‖Jx_true‖ = %.6f\n", norm(Jx_true - Jx_hc) / norm(Jx_true))
@printf("‖Jd_true - Jd_hc‖ / ‖Jd_true‖ = %.6f\n", norm(Jd_true - Jd_hc) / norm(Jd_true))
@printf("‖S_true - S_hc‖ / ‖S_true‖     = %.6f\n", norm(S_true - S_hc) / norm(S_true))

println("\nPer-row S comparison for x3-coupled variables:")
@printf("%-12s  %12s  %12s  %12s\n", "Variable", "‖S_true[i,:]‖", "‖S_hc[i,:]‖", "relative Δ")
for label in bad_vars
    i = findfirst(==(label), mp_xl); isnothing(i) && continue
    st = norm(S_true[i, :]); sh = norm(S_hc[i, :])
    @printf("%-12s  %12.4e  %12.4e  %12.6f\n", label, st, sh, norm(S_true[i, :] - S_hc[i, :]) / max(st, 1e-300))
end

# ═══════════════════════════════════════════════════════════════════════════
dx_order1 = S_true * dd
dx_actual = x_hc .- x_true
dx_at_hc = S_hc * dd

pt_mid = 0.5 .* (pt_true .+ pt_hc)
J_mid = ForwardDiff.jacobian(f, pt_mid)
S_mid = -(J_mid[:, 1:n_x] \ J_mid[:, n_x+1:end])
dx_mid = S_mid * dd

println("\n" * "=" ^ 70)
println("2. PREDICTIONS WITH S AT DIFFERENT POINTS")
println("=" ^ 70)
@printf("\n%-12s  %12s  %12s  %12s  %12s\n", "Variable", "Δx_actual", "S_true·Δd", "S_hc·Δd", "S_mid·Δd")
println("-" ^ 64)
for label in bad_vars
    i = findfirst(==(label), mp_xl); isnothing(i) && continue
    @printf("%-12s  %+12.4e  %+12.4e  %+12.4e  %+12.4e\n",
        label, dx_actual[i], dx_order1[i], dx_at_hc[i], dx_mid[i])
end

@printf("\nNonlinearity (‖pred-actual‖/‖actual‖):\n")
@printf("  S_true·Δd: %.1f\n", norm(dx_order1 - dx_actual) / norm(dx_actual))
@printf("  S_hc·Δd:   %.1f\n", norm(dx_at_hc - dx_actual) / norm(dx_actual))
@printf("  S_mid·Δd:  %.1f\n", norm(dx_mid - dx_actual) / norm(dx_actual))

# ═══════════════════════════════════════════════════════════════════════════
println("\n" * "=" ^ 70)
println("3. NEWTON ITERATION FROM FIRST-ORDER GUESS")
println("=" ^ 70)

x_guess = copy(x_true .+ dx_order1)
for newton_iter in 1:5
    pt_g = [x_guess..., d_prod...]
    res = f(pt_g)
    rn = norm(res)
    J_g = ForwardDiff.jacobian(f, pt_g)
    step = -(J_g[:, 1:n_x] \ res)
    x_guess .+= step
    @printf("  Newton %d: ‖F‖=%.4e, ‖step‖=%.4e, ‖x-x_hc‖=%.4e\n",
        newton_iter, rn, norm(step), norm(x_guess .- x_hc))
end

println("\nFinal comparison (x3-coupled):")
@printf("%-12s  %12s  %12s  %12s  %12s\n", "Variable", "true", "HC", "IFT_order1", "Newton")
for label in bad_vars
    i = findfirst(==(label), mp_xl); isnothing(i) && continue
    @printf("%-12s  %+12.6f  %+12.6f  %+12.2f  %+12.6f\n",
        label, x_true[i], x_hc[i], x_true[i] + dx_order1[i], x_guess[i])
end

# ═══════════════════════════════════════════════════════════════════════════
println("\n" * "=" ^ 70)
println("4. CHECK: IS THE POLYNOMIAL SYSTEM ACTUALLY QUADRATIC?")
println("=" ^ 70)

# Check max degree of equations w.r.t. solve_vars
# If it's quadratic, the Hessian is constant and the issue is something else
println("\nF(x_true, d_true) residual: $(norm(f(pt_true)))")
println("F(x_hc, d_prod) residual:   $(norm(f(pt_hc)))")

# Check if Jacobian is actually constant (linear system)
# by comparing at several random perturbations of x_true
println("\nJacobian variability check (is system linear in x?):")
for trial in 1:3
    perturb = x_true .+ 0.01 .* randn(n_x)
    pt_p = [perturb..., d_true...]
    J_p = ForwardDiff.jacobian(f, pt_p)
    Jx_p = J_p[:, 1:n_x]
    @printf("  Trial %d: ‖Jx - Jx_true‖/‖Jx_true‖ = %.6e\n",
        trial, norm(Jx_p - Jx_true) / norm(Jx_true))
end
