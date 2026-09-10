# Resolve this checkout in a fresh environment, without inheriting development
# overrides from the caller's environment. Run from the repo root with:
#   julia --startup-file=no test/registered.jl
# Optional argument: unit or benchmark, as accepted by test/runtests.jl.
using Pkg

group = isempty(ARGS) ? "all" : only(ARGS)
group in ("all", "unit", "benchmark") || error("Unknown test group: $group")

mktempdir() do environment_dir
    Pkg.activate(environment_dir)
    Pkg.develop(path=dirname(@__DIR__))

    overrides = sort!([
        dependency.name for dependency in values(Pkg.dependencies())
        if dependency.name != "ODEParameterEstimation" &&
           (dependency.is_tracking_path || dependency.is_tracking_repo)
    ])
    isempty(overrides) || error("Expected registered dependencies; found overrides: $(join(overrides, ", "))")

    Pkg.test("ODEParameterEstimation"; allow_reresolve=false, test_args=[group],
             coverage=get(ENV, "ODEPE_TEST_COVERAGE", "false") == "true")
end
