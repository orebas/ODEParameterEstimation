# Create an isolated PEtab pilot environment without changing the active global environment.
# Invoke from the global environment: julia --startup-file=no repro/petab/setup.jl
using Pkg
using TOML

repo = normpath(joinpath(@__DIR__, "..", ".."))
env_dir = get(ENV, "ODEPE_PETAB_ENV", joinpath(tempdir(), "odepe-petab-pilot-env"))
baseline = Dict(d.name => d for d in values(Pkg.dependencies()))
root_project = TOML.parsefile(joinpath(repo, "Project.toml"))
deps = Dict{String, String}(root_project["deps"])
deps["ODEParameterEstimation"] = root_project["uuid"]
merge!(deps, Dict(
    "PEtab" => "48d54b35-e43e-4a66-a5a1-dde6b987cf69",
    "Fides" => "18b51ec4-043b-11f0-1953-6f1d11d509fa",
    "CSV" => "336ed68f-0bac-5ca0-87d4-7b16caf5d00b",
    "DataFrames" => "a93c6f00-e57d-5684-b7b6-d8193f3e46c0",
    "JSON" => "682c06a0-de6a-54ab-a142-c8b1cf79cde6",
    "YAML" => "ddb6d928-2868-570f-bddf-ab3f9cf99eb6",
    "Test" => "8dfed614-e22c-5e08-85e1-65c5234f0b40",
))
# Pin every existing non-development direct dependency, not merely the major versions.
# New CSV requires Parsers 2; Parsers is intentionally not pinned or made a direct dep.
compat = Dict{String, String}("PEtab" => "=5.4.3", "julia" => "1.13")
sources = Dict{String, Any}("ODEParameterEstimation" => Dict("path" => repo))
for name in keys(deps)
    haskey(baseline, name) || continue
    d = baseline[name]
    if d.is_tracking_path
        sources[name] = Dict("path" => d.source)
    elseif !isnothing(d.version)
        compat[name] = "=$(d.version)"
    end
end
mkpath(env_dir)
open(joinpath(env_dir, "Project.toml"), "w") do io
    TOML.print(io, Dict("deps" => deps, "compat" => compat, "sources" => sources); sorted=true)
end
println("Global environment retained: ", Base.active_project())
println("Isolated PEtab environment: ", env_dir)
flush(stdout)
ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"
Pkg.activate(env_dir)
Pkg.resolve()
Pkg.instantiate(; allow_autoprecomp=false)
for d in sort!(collect(values(Pkg.dependencies())); by=d -> d.name)
    if d.is_direct_dep || d.name == "Parsers"
        println((; name=d.name, version=d.version, path=d.is_tracking_path, source=d.source))
    end
end
