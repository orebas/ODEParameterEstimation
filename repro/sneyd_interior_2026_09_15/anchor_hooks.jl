# Research-process instrumentation only. Production files are never changed.
const HC = ODEPE.HomotopyContinuation
const HC_CALL_INDEX = Ref(0)
const INTERPOLANT_RECORDS = Dict{UInt,Dict{String,Any}}()
const ANCHOR_MODE = get(ENV, "ODEPE_SNEYD_ANCHOR_MODE", "exclude_zero")
record["anchor_mode"] = ANCHOR_MODE
record["generic_cache_path"] = get(ENV, "ODEPE_SNEYD_START_CACHE", "")

# Copy the existing selector under a diagnostic name, then remove only the
# first row in this owned worker. Interpolation still receives all 201 samples.
selector_path = joinpath(dirname(dirname(pathof(ODEPE))), "src/types/estimation_options.jl")
selector_source = read(selector_path, String)
selector_start = first(findfirst("function compute_shooting_indices(", selector_source))
selector_stop = last(findnext("\nend\n", selector_source, selector_start))
selector_body = replace(selector_source[selector_start:selector_stop],
    "function compute_shooting_indices(" => "function sneyd_original_shooting_indices("; count=1)
write(joinpath(out, "original_selector.jl"), selector_body)
Base.include_string(ODEPE, selector_body, "sneyd_original_selector.jl")

function record_shooting_selection(original, selected, n_total)
    @assert n_total == length(spec["original_data"]["times"])
    record["anchor_selection"] = (; original_indices=original, selected_indices=selected,
        selected_times=spec["original_data"]["times"][selected],
        all_samples_retained_for_interpolation=true)
    checkpoint()
    println("ANCHOR_SELECTION ", selected); flush(stdout)
end

@eval ODEPE function compute_shooting_indices(n_points::Int, n_total::Int;
        warp::Bool=true, beta::Float64=3.0)
    original = sneyd_original_shooting_indices(n_points, n_total; warp, beta)
    # Restrict the override to this study's explicit shooting-point request.
    n_points == 20 && n_total == 201 || return original
    mode = Main.ANCHOR_MODE
    selected = mode == "exclude_zero" ? filter(!=(1), original) :
        mode == "all" ? original : mode == "midpoint" ? [cld(n_total, 2)] :
        throw(ArgumentError("Unknown anchor mode $mode"))
    Main.record_shooting_selection(original, selected, n_total)
    return selected
end

function path_record(path)
    return (; return_code=string(path.return_code),
        success=HC.is_success(path), failed=HC.is_failed(path),
        at_infinity=HC.is_at_infinity(path), singular=HC.is_singular(path),
        solution_real=real.(path.solution), solution_imag=imag.(path.solution),
        homotopy_t=path.t, residual_at_homotopy_t=path.residual,
        accuracy=path.accuracy, condition_jacobian=path.condition_jacobian,
        accepted_steps=path.accepted_steps, rejected_steps=path.rejected_steps,
        path_number=path.path_number, extended_precision_used=path.extended_precision_used,
        last_point_real=real.(first(path.last_path_point)),
        last_point_imag=imag.(first(path.last_path_point)),
        last_point_t=last(path.last_path_point))
end

# A more-specific method delegates to the unchanged variadic production wrapper.
# Save inputs before solving, and retain every path's actual return code.
function ODEPE._hc_solve(system::HC.ModelKit.System, args...; kwargs...)
    index = (HC_CALL_INDEX[] += 1)
    started = time_ns()
    target = get(kwargs, :target_parameters, ComplexF64[])
    start = get(kwargs, :start_parameters, ComplexF64[])
    gamma = get(kwargs, :gamma, nothing)
    input = (; call=index, started_ns=started,
        kind=isempty(args) ? "fresh_polyhedral" : "continuation",
        target_real=real.(target), target_imag=imag.(target),
        start_real=real.(start), start_imag=imag.(start),
        gamma_real=isnothing(gamma) ? nothing : real(gamma),
        gamma_imag=isnothing(gamma) ? nothing : imag(gamma))
    write_json(joinpath(out, "hc_call_$(index)_input.json"), input)
    try
        result = invoke(ODEPE._hc_solve, Tuple{Vararg{Any}}, system, args...; kwargs...)
        paths = path_record.(HC.path_results(result))
        codes = Dict{String,Int}()
        for path in paths
            codes[path.return_code] = get(codes, path.return_code, 0) + 1
        end
        write_json(joinpath(out, "hc_call_$(index)_result.json"),
            (; call=index, seconds=(time_ns()-started)/1e9, return_codes=codes, paths))
        println("HC_CALL_RESULT ", index, " ", codes); flush(stdout)
        return result
    catch err
        write_json(joinpath(out, "hc_call_$(index)_error.json"),
            (; call=index, seconds=(time_ns()-started)/1e9,
                error=sprint(showerror, err, catch_backtrace())))
        rethrow()
    end
end

function ODEPE.evaluate_noise_frontier_data_vars_at_point(interpolants::AbstractDict,
        data_vars, measured_quantities, t_point)
    f = ODEPE.evaluate_noise_frontier_data_vars_at_point
    values = invoke(f, Tuple{Any,Any,Any,Any}, interpolants, data_vars, measured_quantities, t_point)
    id = objectid(interpolants)
    if !haskey(INTERPOLANT_RECORDS, id)
        control = invoke(f, Tuple{Any,Any,Any,Any}, interpolants, data_vars, measured_quantities, 0.0)
        INTERPOLANT_RECORDS[id] = Dict("index"=>length(INTERPOLANT_RECORDS)+1,
            "data_variables"=>string.(data_vars), "t_zero_control"=>control,
            "scope"=>"Extra t=0 evaluation is diagnostic only; zero remains excluded from shooting",
            "values_by_time"=>Dict{String,Any}())
    end
    packet = INTERPOLANT_RECORDS[id]
    packet["values_by_time"][string(t_point)] = values
    write_json(joinpath(out, "interpolated_targets_$(packet["index"]).json"), packet)
    return values
end

function ODEPE.solve_with_hc_parameterized(poly_system::AbstractVector, solve_vars,
        data_vars, param_values_list; options=Dict(),
        precomputed_generic_solutions=nothing, precomputed_generic_params=nothing)
    scales = get(options, :use_column_scaling, true) ?
        ODEPE.compute_column_scales(solve_vars, data_vars, param_values_list) : ones(length(solve_vars))
    input = (; unknowns=string.(solve_vars), data_variables=string.(data_vars),
        parameters=param_values_list, options, column_scales=scales,
        generic_parameters_real=real.(precomputed_generic_params),
        generic_parameters_imag=imag.(precomputed_generic_params),
        generic_solutions_real=[real.(root) for root in precomputed_generic_solutions],
        generic_solutions_imag=[imag.(root) for root in precomputed_generic_solutions])
    index = get(record, "parameter_homotopy_calls", 0) + 1
    record["parameter_homotopy_calls"] = index
    write_json(joinpath(out, "parameter_homotopy_$(index).json"), input)
    checkpoint()
    return invoke(ODEPE.solve_with_hc_parameterized, Tuple{Any,Any,Any,Any},
        poly_system, solve_vars, data_vars, param_values_list;
        options, precomputed_generic_solutions, precomputed_generic_params)
end
