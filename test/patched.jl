# Reproduce the modern dependency families with explicitly prepared upstream
# checkouts. This uses a temporary environment and never edits the caller's.
# Arguments: GP path, SIAN path, SI path, optional all|unit|benchmark|petab.
using Pkg
using TOML

length(ARGS) in (3, 4) || error("Usage: test/patched.jl GP_PATH SIAN_PATH SI_PATH [all|unit|benchmark|petab]")
gp_path, sian_path, si_path = abspath.(ARGS[1:3])
group = length(ARGS) == 4 ? ARGS[4] : "all"
(group in ("all", "unit", "benchmark", "petab") ||
 (basename(group) == group && isfile(joinpath(@__DIR__, group)))) ||
    error("Unknown test group or active test filename: $group")

mktempdir() do environment_dir
    # These constraints belong to this CI profile, not to the user's global
    # environment. They prevent a green run on an unintended older stack.
    project = Dict(
        "deps" => Dict(
            "Optim" => "429524aa-4258-5aef-a3af-852621145aeb",
            "OrdinaryDiffEq" => "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed",
            "SciMLBase" => "0bca4576-84f4-4d90-8ffe-ffa030f20462",
            "OrderedCollections" => "bac558e1-5e72-5ebc-8fee-abe8a469f55d",
        ),
        "compat" => Dict("Optim" => "2", "OrdinaryDiffEq" => "7",
                         "SciMLBase" => "3", "OrderedCollections" => "2"),
    )
    if group == "petab"
        # Keep PEtab and the adapter's fixtures in a separate CI environment;
        # importing the core package does not install benchmark dependencies.
        merge!(project["deps"], Dict(
            "PEtab" => "48d54b35-e43e-4a66-a5a1-dde6b987cf69",
            "Test" => "8dfed614-e22c-5e08-85e1-65c5234f0b40",
            "ModelingToolkit" => "961ee093-0014-501f-94e3-6117800e7a78",
            "Symbolics" => "0c5d862f-8b57-4792-8d23-62f2024744c7",
        ))
        project["compat"]["PEtab"] = "~5.4.3"
    end
    open(joinpath(environment_dir, "Project.toml"), "w") do io
        TOML.print(io, project)
    end
    Pkg.activate(environment_dir)
    Pkg.develop([
        PackageSpec(path=dirname(@__DIR__)),
        PackageSpec(path=gp_path),
        PackageSpec(path=sian_path),
        PackageSpec(path=si_path),
    ])
    Pkg.status(; mode=Pkg.PKGMODE_MANIFEST)
    if group == "petab"
        include(joinpath(@__DIR__, "petab", "runtests.jl"))
    else
        Pkg.test("ODEParameterEstimation"; allow_reresolve=false, test_args=[group],
                 coverage=get(ENV, "ODEPE_TEST_COVERAGE", "false") == "true")
    end
end
