# Diagnostic: instrument LSO residual!/jacobian! to see how the deadline check
# behaves under heavy ForwardDiff load.
#
# Run: julia --startup-file=no /home/orebas/.julia/dev/ODEParameterEstimation/repro/diag_polish_maxtime.jl

using ODEParameterEstimation
using ODEParameterEstimation: simple, _build_polish_context, _polish_single_from_context,
    sample_problem_data, merge_options
using LeastSquaresOptim
using ForwardDiff
using OrdinaryDiffEq
using ModelingToolkit
using Printf

base_opts = EstimationOptions(
    datasize = 201,
    noise_level = 0.0,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    interpolator = InterpolatorAAAD,
    shooting_points = 0,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    use_parameter_homotopy = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)
pep = sample_problem_data(simple(), base_opts)
p_size = length(pep.ic) + length(pep.p_true)
polish_opts = merge_options(
    base_opts;
    polish_method = PolishLSOBoundedLog,
    opt_lb = fill(1e-3, p_size),
    opt_ub = fill(50.0, p_size),
    polish_maxiters = 100_000,
    abstol = 1e-12,
    reltol = 1e-12,
)
ctx = _build_polish_context(pep; opts = polish_opts)

# Build our own residual!/jacobian! mirroring polish_residual.jl, but with counters
# and timing. Then call LSO directly so we can see what happens.
const t_start = Ref(0.0)
const f_calls = Ref(0)
const g_calls = Ref(0)
const last_log = Ref(0.0)

p_true_vec = vcat(Float64.(collect(values(pep.ic))), Float64.(collect(values(pep.p_true))))
p_seed_external = clamp.(0.5 .* p_true_vec, 1e-3, 50.0)
p_seed_internal = ODEParameterEstimation._polish_external_to_internal(
    p_seed_external, ctx.coordinate_transforms, ctx.coordinate_shifts,
)

n_obs = sum(length(t) for t in ctx.data_targets)
residual_count = n_obs

deadline = Ref(Inf)

function my_residual!(res, p_internal, _ = nothing)
    f_calls[] += 1
    elapsed = time() - t_start[]
    # Log every iteration so we can see the cadence
    if eltype(res) === Float64
        @printf("  [f%04d g%04d] t=%7.3fs el=%-3s eltype=Float64\n",
            f_calls[], g_calls[], elapsed, time() > deadline[] ? "OVR" : "ok")
    else
        @printf("  [f%04d g%04d] t=%7.3fs el=%-3s eltype=Dual\n",
            f_calls[], g_calls[], elapsed, time() > deadline[] ? "OVR" : "ok")
    end
    if time() > deadline[]
        @printf("  >>> THROWING TIMEOUT SIGNAL (elapsed %.3fs > deadline) <<<\n", elapsed)
        error("__POLISH_TIMEOUT__")
    end
    p_all = ODEParameterEstimation._polish_internal_to_external(
        p_internal, ctx.coordinate_transforms, ctx.coordinate_shifts,
    )
    ic_guess = @view p_all[1:ctx.n_ic]
    param_guess = @view p_all[(ctx.n_ic + 1):end]
    prob_opt = remake(
        ctx.base_ode_prob;
        u0 = Dict(ctx.unknown_syms .=> ic_guess),
        p = Dict(ctx.param_syms .=> param_guess),
        build_initializeprob = false,
    )
    t_solve = time()
    sol_opt = ModelingToolkit.solve(
        prob_opt, ctx.solver;
        saveat = ctx.t_vector, abstol = ctx.abstol, reltol = ctx.reltol,
        maxiters = ctx.polish_ode_maxiters,
        unstable_check = (dt, u, p, ti) -> time() > deadline[],
    )
    solve_dt = time() - t_solve
    if sol_opt.retcode != ReturnCode.Success
        @printf("    solve aborted retcode=%s after %.3fs\n", sol_opt.retcode, solve_dt)
        fill!(res, 1e6)
        return nothing
    end
    if solve_dt > 1.0
        @printf("    slow solve %.3fs\n", solve_dt)
    end
    idx = 1
    @inbounds for (j, f) in enumerate(ctx.obs_funcs)
        data_true = ctx.data_targets[j]
        for i in eachindex(ctx.t_vector)
            res[idx] = f(sol_opt.u[i], param_guess) - data_true[i]
            idx += 1
        end
    end
    return nothing
end

function my_residual_vec(p_internal)
    r = Vector{eltype(p_internal)}(undef, residual_count)
    my_residual!(r, p_internal)
    return r
end

function my_jacobian!(J, p_internal, _ = nothing)
    g_calls[] += 1
    ForwardDiff.jacobian!(J, my_residual_vec, p_internal)
    return nothing
end

println("=== Phase 1: warmup with maxtime=Inf, just so JIT compiles ===")
deadline[] = Inf
warmup_res = zeros(residual_count)
my_residual!(warmup_res, p_seed_internal)
println()

println("=== Phase 2: LSO with maxtime=2.0 — watch the call pattern ===")
problem = LeastSquaresOptim.LeastSquaresProblem(
    x = copy(p_seed_internal),
    f! = my_residual!,
    g! = my_jacobian!,
    output_length = residual_count,
)
f_calls[] = 0
g_calls[] = 0
t_start[] = time()
deadline[] = t_start[] + 2.0

try
    result = LeastSquaresOptim.optimize!(
        problem,
        LeastSquaresOptim.LevenbergMarquardt();
        x_tol = 1e-14, f_tol = 1e-14, g_tol = 1e-14,
        iterations = 100_000,
        Δ = 10.0,
        lower = ctx.internal_lb,
        upper = ctx.internal_ub,
    )
    @printf("LSO returned normally. converged=%s f_calls=%d g_calls=%d total=%.3fs\n",
        result.converged, f_calls[], g_calls[], time() - t_start[])
catch e
    @printf("LSO threw %s after f_calls=%d g_calls=%d total=%.3fs\n",
        typeof(e), f_calls[], g_calls[], time() - t_start[])
    if isa(e, ErrorException)
        println("  msg: ", e.msg)
    end
end
