#=
ERK Model Diagnostic Script
============================
Systematically tests each stage of the parameter estimation pipeline
to identify where and why the ERK model fails.

ERK model properties:
- 6 states: S0, C1, C2, S1, S2, E
- 6 parameters: kf1, kr1, kc1, kf2, kr2, kc2
- 3 observables: y0~S0, y1~S1, y2~S2  (only 3 of 6 states observed!)
- Bilinear terms: E*S0, E*S1 (products of states in RHS)
- Parameter scales: kf1=11.5, kr1=300.0, kc1=12.45, kf2=11.15, kr2=4.864, kc2=428.13

Hypothesized failure modes:
1. Derivative explosion: 13 levels of derivatives of bilinear terms → coefficient overflow
2. SIAN identifiability: under-observed system → underdetermined polynomial system
3. Enzyme AD: known to fail on adaptive ODE solvers
4. Parameter scale mismatch: ~100× range in parameter values
=#

using ModelingToolkit, DifferentialEquations
using ODEParameterEstimation
using OrderedCollections
using LinearAlgebra
using Logging

# Increase logging verbosity
global_logger(ConsoleLogger(stderr, Logging.Debug))

println("=" ^ 80)
println("ERK MODEL DIAGNOSTIC ANALYSIS")
println("=" ^ 80)

#==========================================================================
  STAGE 0: Define the ERK model
==========================================================================#
println("\n### STAGE 0: Model Definition ###")

@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
D = Differential(t)
states = [S0, C1, C2, S1, S2, E]
parameters = [kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [
    D(S0) ~ -kf1 * E * S0 + kr1 * C1,
    D(C1) ~ kf1 * E * S0 - (kr1 + kc1) * C1,
    D(C2) ~ kc1 * C1 - (kr2 + kc2) * C2 + kf2 * E * S1,
    D(S1) ~ -kf2 * E * S1 + kr2 * C2,
    D(S2) ~ kc2 * C2,
    D(E) ~ -kf1 * E * S0 + kr1 * C1 - kf2 * E * S1 + (kr2 + kc2) * C2,
]
@named model = ODESystem(eqs, t, states, parameters)
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]
ic = [5.0, 0, 0, 0, 0, 0.65]
time_interval = [0.0, 20.0]
p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]

println("States ($(length(states))): ", states)
println("Parameters ($(length(parameters))): ", parameters)
println("Observables ($(length(measured_quantities))): ", measured_quantities)
println("True parameters: ", p_true)
println("True ICs: ", ic)
println("Observation ratio: $(length(measured_quantities))/$(length(states)) = $(round(length(measured_quantities)/length(states), digits=2))")

#==========================================================================
  STAGE 1: Check derivative order computation
==========================================================================#
println("\n### STAGE 1: Derivative Order Analysis ###")

states_count = length(states)
ps_count = length(parameters)
n_obs = length(measured_quantities)

n_pe_formula = states_count + ps_count + 1
n_heuristic = Int64(ceil((states_count + ps_count) / n_obs) + 2)
n = max(n_pe_formula, n_heuristic, 3)

println("PE formula: states($states_count) + params($ps_count) + 1 = $n_pe_formula")
println("Heuristic: ceil(($states_count + $ps_count) / $n_obs) + 2 = $n_heuristic")
println("Selected n (max): $n")
println("Total equations: $n × $n_obs = $(n * n_obs)")
println("Total unknowns: $states_count + $ps_count = $(states_count + ps_count)")
println("→ Overdetermined by: $(n * n_obs - (states_count + ps_count)) equations")

#==========================================================================
  STAGE 2: Test symbolic derivative computation (expression growth)
==========================================================================#
println("\n### STAGE 2: Symbolic Derivative Expression Growth ###")

# Manually compute derivatives to see expression growth
model_completed = complete(model)
local_eqs = equations(model_completed)

# Build a substitution dict: D(state) → rhs
state_derivs = Dict{Num, Num}()
for eq in local_eqs
    state_derivs[eq.lhs] = eq.rhs
end

println("\nODE RHS expression sizes (# terms as proxy via string length):")
for eq in local_eqs
    rhs_str = string(eq.rhs)
    println("  $(eq.lhs) = $(length(rhs_str)) chars")
end

# Compute successive derivatives of each observable and measure expression size
println("\nObservable derivative expression growth:")
println("  (tracking string length of RHS as a complexity proxy)")

for (obs_idx, mq) in enumerate(measured_quantities)
    obs_name = string(mq.lhs)
    rhs = mq.rhs  # e.g., S0(t)

    println("\n  Observable $obs_name = $rhs:")

    current_rhs = rhs
    for level in 0:min(n, 8)  # cap at 8 to avoid blowup
        if level == 0
            rhs_size = length(string(current_rhs))
            println("    Level $level: $rhs_size chars")
        else
            # Differentiate
            deriv = expand_derivatives(D(current_rhs))
            # Substitute state derivatives
            substituted = deriv
            for (lhs_d, rhs_d) in state_derivs
                substituted = Symbolics.substitute(substituted, Dict(lhs_d => rhs_d))
            end
            substituted = Symbolics.simplify(substituted)
            rhs_size = length(string(substituted))
            println("    Level $level: $rhs_size chars")

            if rhs_size > 100000
                println("    ⚠ EXPRESSION BLOWUP — stopping at level $level")
                break
            end
            current_rhs = substituted
        end
    end
end

#==========================================================================
  STAGE 3: Test populate_derivatives directly
==========================================================================#
println("\n### STAGE 3: populate_derivatives (capped at n=$n) ###")

try
    DD = ODEParameterEstimation.populate_derivatives(model_completed, measured_quantities, n, Dict())
    println("Success! Computed $(length(DD.obs_rhs)) levels of observable derivatives")
    println("         Computed $(length(DD.states_rhs)) levels of state derivatives")

    # Show expression sizes at each level
    for level in 1:length(DD.obs_rhs)
        sizes = [length(string(expr)) for expr in DD.obs_rhs[level]]
        println("  obs_rhs level $(level-1): sizes = $sizes")
    end
catch e
    println("FAILED: ", typeof(e))
    println("  ", sprint(showerror, e))
end

#==========================================================================
  STAGE 4: Test data generation
==========================================================================#
println("\n### STAGE 4: Data Generation ###")

datasize = 100  # small for diagnostics
solver = Vern9()

try
    data_sample = ODEParameterEstimation.sample_data(
        model_completed,
        measured_quantities, time_interval,
        Dict(parameters .=> p_true), Dict(states .=> ic),
        datasize; solver=solver
    )
    println("Data generation: SUCCESS")
    println("  Time points: $(length(data_sample["t"]))")
    for key in keys(data_sample)
        if key != "t"
            vals = data_sample[key]
            println("  $key: range [$(minimum(vals)), $(maximum(vals))]")
        end
    end
catch e
    println("Data generation: FAILED")
    println("  ", sprint(showerror, e))
end

#==========================================================================
  STAGE 5: Test identifiability analysis
==========================================================================#
println("\n### STAGE 5: Identifiability Analysis ###")

try
    deriv_level, unident_dict, varlist, DD = ODEParameterEstimation.multipoint_local_identifiability_analysis(
        model_completed, measured_quantities, 3
    )
    println("Identifiability analysis: SUCCESS")
    println("  Derivative levels: ", deriv_level)
    println("  Unidentifiable parameters: ", keys(unident_dict))
    println("  Identifiable varlist ($(length(varlist))): ", varlist)
    println("  DD obs_rhs levels: ", length(DD.obs_rhs))
    println("  DD states_rhs levels: ", length(DD.states_rhs))
    println("  All unidentifiable: ", DD.all_unidentifiable)
catch e
    println("Identifiability analysis: FAILED")
    println("  ", typeof(e))
    println("  ", sprint(showerror, e))
    # Print full stacktrace
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end

#==========================================================================
  STAGE 6: Test SIAN/SI.jl equation system
==========================================================================#
println("\n### STAGE 6: StructuralIdentifiability.jl Analysis ###")

try
    name = "erk_diag"
    ordered_model, mq = ODEParameterEstimation.create_ordered_ode_system(
        name, states, parameters, eqs, measured_quantities
    )

    # Generate data for SI.jl
    data_sample = ODEParameterEstimation.sample_data(
        model_completed,
        measured_quantities, time_interval,
        Dict(parameters .=> p_true), Dict(states .=> ic),
        100; solver=solver
    )

    si_ode, symbol_map, gens = ODEParameterEstimation.convert_to_si_ode(ordered_model, measured_quantities)

    println("SI ODE conversion: SUCCESS")
    println("  SI parameters: ", si_ode.parameters)
    println("  SI x_vars (states): ", si_ode.x_vars)
    println("  SI y_vars (outputs): ", si_ode.y_vars)

    # Check identifiability
    using StructuralIdentifiability
    params_to_assess = vcat(si_ode.parameters, si_ode.x_vars)
    id_result = StructuralIdentifiability.assess_identifiability(
        si_ode;
        funcs_to_check=params_to_assess,
        prob_threshold=0.99,
        loglevel=Logging.Info,
    )

    println("\nIdentifiability results:")
    for (param, status) in id_result
        println("  $param: $status")
    end

    nonident = [k for (k, v) in id_result if v == :nonidentifiable]
    locally_ident = [k for (k, v) in id_result if v == :locally]
    globally_ident = [k for (k, v) in id_result if v == :globally]
    println("\n  Globally identifiable: $(length(globally_ident))")
    println("  Locally identifiable: $(length(locally_ident))")
    println("  Non-identifiable: $(length(nonident))")

    # Get polynomial system
    println("\nGetting polynomial system from SIAN...")
    result = ODEParameterEstimation.get_polynomial_system_from_sian(
        si_ode,
        params_to_assess;
        p=0.99,
        infolevel=1,
    )

    poly_system = result["polynomial_system"]
    y_deriv_dict = result["Y_eq"]
    println("  Polynomial system: $(length(poly_system)) equations")
    println("  Derivative dict: ", y_deriv_dict)

    if !isempty(poly_system)
        R = parent(poly_system[1])
        all_vars = Nemo.gens(R)
        println("  Variables in polynomial ring: $(length(all_vars))")
        println("  Variable names: ", [string(v) for v in all_vars])

        # Analyze polynomial degrees and sizes
        println("\n  Polynomial degrees:")
        for (i, poly) in enumerate(poly_system)
            deg = Nemo.total_degree(poly)
            nterms = length(poly)
            println("    Eq $i: degree=$deg, terms=$nterms")
        end
    end

    # Check identifiable functions
    id_funcs = find_identifiable_functions(si_ode)
    println("\nIdentifiable functions: ", id_funcs)

catch e
    println("SI.jl analysis: FAILED")
    println("  ", typeof(e))
    println("  ", sprint(showerror, e))
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end

#==========================================================================
  STAGE 7: Run full estimation with ForwardDiff (not Enzyme)
==========================================================================#
println("\n### STAGE 7: Full Estimation (ForwardDiff, small data) ###")

try
    name = "erk_diag_full"
    ordered_model, mq = ODEParameterEstimation.create_ordered_ode_system(
        name, states, parameters, eqs, measured_quantities
    )

    data_sample = ODEParameterEstimation.sample_data(
        model_completed,
        measured_quantities, time_interval,
        Dict(parameters .=> p_true), Dict(states .=> ic),
        100; solver=solver
    )

    pep = ParameterEstimationProblem(
        name,
        ordered_model,
        mq,
        data_sample,
        time_interval,
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )

    # Use ForwardDiff instead of Enzyme, minimal polishing
    opts = EstimationOptions(
        use_parameter_homotopy=false,  # simpler path first
        datasize=101,
        noise_level=0,
        system_solver=SolverHC,
        flow=FlowStandard,
        use_si_template=true,
        polish_solver_solutions=false,
        polish_solutions=false,
        polish_maxiters=50,
        polish_method=PolishLBFGS,
        opt_ad_backend=:forward,
        interpolator=InterpolatorAGPRobust,
        diagnostics=true
    )

    println("Starting estimation (no polish, no homotopy)...")
    meta, results = analyze_parameter_estimation_problem(pep, opts)

    println("Estimation completed!")
    println("  Number of results: ", length(results))

    if !isempty(results)
        # Show best result
        best = results[1]
        println("  Best result error: ", best.err)
        println("  Parameters:")
        for (k, v) in best.parameters
            println("    $k = $v")
        end
        println("  States:")
        for (k, v) in best.states
            println("    $k = $v")
        end
    else
        println("  ⚠ NO RESULTS RETURNED")
    end
catch e
    println("Full estimation: FAILED at some stage")
    println("  ", typeof(e))
    println("  ", sprint(showerror, e))
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end

println("\n" * "=" ^ 80)
println("DIAGNOSTIC ANALYSIS COMPLETE")
println("=" ^ 80)
