using ODEParameterEstimation
using Documenter

DocMeta.setdocmeta!(ODEParameterEstimation, :DocTestSetup, :(using ODEParameterEstimation); recursive=true)

makedocs(;
    modules=[ODEParameterEstimation],
    checkdocs=:exports,
    # These replace external dependencies behind private adapters. Their
    # contracts and attribution live beside the source, outside the public API.
    checkdocs_ignored_modules=[ODEParameterEstimation.GPBackend, ODEParameterEstimation.SIANBackend],
    authors="Oren Bassik <orebas@yahoo.com> and contributors",
    sitename="ODEParameterEstimation.jl",
    format=Documenter.HTML(;
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API types" => "api_types.md",
        "API functions" => "api_functions.md",
        "API constants and macros" => "api_other.md",
    ],
)
