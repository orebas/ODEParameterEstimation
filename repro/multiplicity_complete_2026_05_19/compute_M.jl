### Path C implementation: compute the algebraic multiplicity M directly from
### SIAN-Julia's Et polynomial system, harvesting length(quotient_basis(gb)).
###
### M is the number of distinct (state, parameter) tuples in the identifiable
### subspace that produce identical observation trajectories. The math: SIAN
### builds Et (polynomial system whose roots ARE the algebraic solutions),
### substitutes random leader values to get Et_hat over (state, parameter),
### computes a Groebner basis of <Et_hat, z_aux*Q_hat - 1> (Rabinowitsch
### saturation), and `length(Groebner.quotient_basis(gb))` is M.
###
### SIAN uses the gb internally for global-vs-local identifiability tests
### but never calls quotient_basis. This function reproduces SIAN's path
### up to the gb computation (using SIAN's exported building blocks) and
### then takes the one missing step.
###
### See M_INFERENCE_TECHNICAL.md in this directory for the full discussion.

using SIAN
using SIAN.Nemo
using SIAN.Groebner
using Logging
using LinearAlgebra

"""
    compute_algebraic_multiplicity(ode::SIAN.ODE; p=0.99, infolevel=0) -> Int

Compute the algebraic multiplicity M of a `SIAN.ODE` object (returned by the
`SIAN.@ODEmodel` macro). M = number of distinct algebraic solutions for the
(state, parameter) tuple given a generic observation.

Reuses SIAN-Julia's `identifiability_ode` pipeline up through the Groebner
basis step at SIAN.jl:267, then returns `length(Groebner.quotient_basis(gb))`.

Returns:
- Positive Int: the multiplicity M
- 0: when the system has no locally identifiable parameters at all (M
  ill-defined / continuous family)

The probability of correctness is `p` (default 0.99), inherited from SIAN's
own sampling-bound machinery.
"""
function compute_algebraic_multiplicity(ode; p::Float64=0.99, infolevel::Int=0)
    # NB: `ode` may be either SIAN.ODE or StructuralIdentifiability.ODE.
    # SIAN.identifiability_ode also accepts both (its signature is untyped).
    # We only call SIAN exports + Nemo + Groebner — no method dispatch tied to
    # either ODE type. StructuralIdentifiability.@ODEmodel is preferred for
    # users because it accepts Float64 literals (SIAN's macro does not).
    # === Borrows the entire control flow of SIAN.identifiability_ode through ===
    # === the Groebner basis computation. The only NEW step is the final     ===
    # === `length(Groebner.quotient_basis(gb))` at the bottom.                ===

    if infolevel > 0
        @info "compute_algebraic_multiplicity: starting"
    end

    # --- (1) Construct the maximal polynomial system Et ---
    eqs, Q, x_eqs, y_eqs, x_vars, y_vars, u_vars, mu, all_indets, gens_Rjet = SIAN.get_equations(ode)

    non_jet_ring = ode.poly_ring
    z_aux = gens_Rjet[end-length(mu)]
    Rjet = gens_Rjet[1].parent

    n = length(x_vars)
    m = length(y_vars)
    u = length(u_vars)
    s = length(mu) + n

    not_int_cond_params = gens_Rjet[(end-length(ode.parameters)+1):end]
    all_params = vcat(not_int_cond_params, gens_Rjet[1:n])
    x_variables = gens_Rjet[1:n]
    for i in 1:(s+1)
        x_variables = vcat(x_variables, gens_Rjet[(i*(n+m+u)+1):(i*(n+m+u)+n)])
    end
    u_variables = gens_Rjet[(n+m+1):(n+m+u)]
    for i in 1:(s+1)
        u_variables = vcat(u_variables, gens_Rjet[((n+m+u)*i+n+m+1):((n+m+u)*(i+1))])
    end

    X, X_eq = SIAN.get_x_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
    Y, Y_eq = SIAN.get_y_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)

    # --- (2) D1 sampling for the Jacobian-based local-ID check ---
    d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(Q * eq[2])[1]) for eq in eqs], Nemo.total_degree(Q))))

    params_to_assess = SIAN.get_parameters(ode)
    params_to_assess_ = [SIAN.add_to_var(param, Rjet, 0) for param in params_to_assess]

    D1 = floor(BigInt, (length(params_to_assess) + 1) * 2 * d0 * s * (n + 1) * (1 + 2 * d0 * s) / (1 - p))
    sample = SIAN.sample_point(D1, x_vars, y_vars, u_variables, all_params, X_eq, Y_eq, Q)
    all_subs = sample[4]
    u_hat = sample[2]
    y_hat = sample[1]

    # --- (3) Build Et by iterative prolongation (SIAN.jl:109-156 verbatim) ---
    alpha = [1 for i in 1:n]
    beta = [0 for i in 1:m]
    Et = Array{QQMPolyRingElem}(undef, 0)
    x_theta_vars = all_params
    prolongation_possible = [1 for i in 1:m]

    all_x_theta_vars_subs = SIAN.insert_zeros_to_vals(all_subs[1], all_subs[2])
    eqs_i_old = Array{QQMPolyRingElem}(undef, 0)
    evl_old = Array{QQMPolyRingElem}(undef, 0)
    while sum(prolongation_possible) > 0
        for i in 1:m
            if prolongation_possible[i] == 1
                eqs_i = vcat(Et, Y[i][beta[i]+1])
                evl = [Nemo.evaluate(eq, vcat(u_hat[1], y_hat[1]), vcat(u_hat[2], y_hat[2])) for eq in eqs_i if !(eq in eqs_i_old)]
                evl_old = vcat(evl_old, evl)
                JacX = SIAN.jacobi_matrix(evl_old, x_theta_vars, all_x_theta_vars_subs)
                eqs_i_old = eqs_i
                if LinearAlgebra.rank(JacX) == length(eqs_i)
                    Et = vcat(Et, Y[i][beta[i]+1])
                    beta[i] = beta[i] + 1
                    polys_to_process = vcat(Et, [Y[k][beta[k]+1] for k in 1:m])
                    while length(polys_to_process) != 0
                        new_to_process = Array{QQMPolyRingElem}(undef, 0)
                        vrs = Set{QQMPolyRingElem}()
                        for poly in polys_to_process
                            vrs = union(vrs, [v for v in Nemo.vars(poly) if v in x_variables])
                        end
                        vars_to_add = Set{QQMPolyRingElem}(v for v in vrs if !(v in x_theta_vars))
                        for v in vars_to_add
                            x_theta_vars = vcat(x_theta_vars, v)
                            ord_var = SIAN.get_order_var2(v, all_indets, n + m + u, s)
                            var_idx = Nemo.var_index(ord_var[1])
                            poly = X[var_idx][ord_var[2]]
                            Et = vcat(Et, poly)
                            new_to_process = vcat(new_to_process, poly)
                            alpha[var_idx] = max(alpha[var_idx], ord_var[2] + 1)
                        end
                        polys_to_process = new_to_process
                    end
                else
                    prolongation_possible[i] = 0
                end
            end
        end
    end

    max_rank = length(Et)
    for i in 1:m
        for j in (beta[i]+1):length(Y[i])
            to_add = true
            for v in SIAN.get_vars(Y[i][j], x_vars, all_indets, n + m + u, s)
                if !(v in x_theta_vars)
                    to_add = false
                end
            end
            if to_add
                beta[i] = beta[i] + 1
                Et = vcat(Et, Y[i][j])
            end
        end
    end

    # --- (4) Assess local identifiability per parameter ---
    theta_l = Array{QQMPolyRingElem}(undef, 0)
    Et_eval_base = [Nemo.evaluate(e, vcat(u_hat[1], y_hat[1]), vcat(u_hat[2], y_hat[2])) for e in Et]
    for param_0 in params_to_assess_
        other_params = [v for v in x_theta_vars if v != param_0]
        Et_subs = [Nemo.evaluate(e, [param_0], [Nemo.evaluate(param_0, all_x_theta_vars_subs)]) for e in Et_eval_base]
        JacX = SIAN.jacobi_matrix(Et_subs, other_params, all_x_theta_vars_subs)
        if LinearAlgebra.rank(JacX) != max_rank
            theta_l = vcat(theta_l, param_0)
        end
    end
    if length(theta_l) == 0
        @warn "compute_algebraic_multiplicity: no locally identifiable parameters; M is not well-defined for this system as posed."
        return 0
    end

    # --- (5) D2 sampling and the Groebner basis step (SIAN.jl:209-267) ---
    deg_variety = foldl(*, [BigInt(Nemo.total_degree(e)) for e in Et])
    D2 = floor(BigInt, 6 * length(theta_l) * deg_variety * (1 + 2 * d0 * maximum(beta)) / (1 - p))

    sample = SIAN.sample_point(D2, x_vars, y_vars, u_variables, all_params, X_eq, Y_eq, Q)
    y_hat = sample[1]
    u_hat = sample[2]

    Et_hat = [Nemo.evaluate(e, vcat(y_hat[1], u_hat[1]), vcat(y_hat[2], u_hat[2])) for e in Et]

    Et_x_vars = Set{QQMPolyRingElem}()
    for poly in Et_hat
        Et_x_vars = union(Et_x_vars, Set(Nemo.vars(poly)))
    end
    Et_x_vars = setdiff(Et_x_vars, not_int_cond_params)
    Q_hat = Nemo.evaluate(Q, u_hat[1], u_hat[2])
    vrs_sorted = vcat(
        sort([e for e in Et_x_vars], lt=(x, y) -> SIAN.compare_diff_var(x, y, all_indets, n + m + u, s)),
        z_aux,
        sort(not_int_cond_params, rev=true),
    )

    Rjet_new, _ = Nemo.polynomial_ring(Nemo.QQ, [string(v) for v in vrs_sorted], internal_ordering=:degrevlex)
    Et_hat = [SIAN.parent_ring_change(e, Rjet_new) for e in Et_hat]
    gb_input = vcat(Et_hat, SIAN.parent_ring_change(z_aux * Q_hat, Rjet_new) - 1)

    # Compute Groebner basis. The biohydrogenation crash that motivated an
    # earlier fallback cascade was fixed upstream in Groebner.jl PR #218
    # (align_up bitmask only worked for power-of-two `n`, breaking when
    # tasks ∉ {1,2,4,8}). With that patch in we can use the default path.
    gb = Groebner.groebner(gb_input)

    # --- (6) THE NEW STEP: M = quotient_basis dim of the zero-dim ideal ---
    M = length(Groebner.quotient_basis(gb))

    if infolevel > 0
        @info "compute_algebraic_multiplicity: M = $M  (|Et|=$(length(Et)), |theta_l|=$(length(theta_l)), |gb|=$(length(gb)))"
    end
    return M
end
