# Small execution check for the research observer and cache, not an estimation gate.
include("dense_common.jl")
out = abspath(only(ARGS))
ispath(out) && error("Use a fresh validation directory")
mkpath(out)
spec = Dict("original_data" => Dict("times" => collect(range(0.0, 0.98; length=201))))
phase = "validation"
record = Dict{String,Any}("estimation_started_ns"=>time_ns(),
    "julia_version"=>string(VERSION), "versions"=>Dict(),
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))))
checkpoint() = write_json(joinpath(out, "validation.json"), record)
ENV["ODEPE_SNEYD_START_CACHE"] = joinpath(out, "toy_cache.json")
ENV["ODEPE_SNEYD_ANCHOR_MODE"] = "exclude_zero"
include("anchor_hooks.jl")
include("capture_and_solve.jl")
indices = ODEPE.compute_shooting_indices(20, 201)
@assert indices == [3,5,7,10,14,18,22,28,34,41,50,60,72,86,102,122,144,170,201]
@assert spec["original_data"]["times"][first(indices)] == 0.0098
@assert ODEPE.compute_shooting_indices(3, 7) == ODEPE.sneyd_original_shooting_indices(3, 7)
S.@variables x d
S.@variables y1_0 y1_1 y1_2
interpolants = Dict(S.diff2term(x) => (t -> t^2))
jets = ODEPE.evaluate_noise_frontier_data_vars_at_point(interpolants,
    [y1_0,y1_1,y1_2], [d~x], 0.5)
@assert jets ≈ [0.25,1.0,2.0]
@assert isfile(joinpath(out, "interpolated_targets_1.json"))
polynomials, unknowns, data = [x^2-d], [x], [d]
roots, p0 = ODEPE.compute_generic_start_solutions(polynomials, unknowns, data; gamma_seed=23)
@assert length(roots) == 2
@assert !record["generic_start_from_cache"]
reloaded, cached_p0 = ODEPE.compute_generic_start_solutions(polynomials, unknowns, data; gamma_seed=23)
@assert record["generic_start_from_cache"] && reloaded == roots && cached_p0 == p0
system, _, _ = ODEPE.convert_to_hc_format_with_params(polynomials, unknowns, data)
target_result = ODEPE._track_gamma_straight(system, roots, p0, [1.0])
@assert length(HC.solutions(target_result)) == 2
@assert all(HC.is_success, HC.path_results(target_result))
ODEPE.solve_with_hc_parameterized(polynomials, unknowns, data, [[1.0]];
    precomputed_generic_solutions=roots, precomputed_generic_params=p0)
@assert record["parameter_homotopy_calls"] == 1
@assert isfile(joinpath(out, "parameter_homotopy_1.json"))
record["status"] = "passed"
checkpoint()
println("VALIDATION_PASSED")
