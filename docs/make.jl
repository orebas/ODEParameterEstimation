using ODEParameterEstimation
using Documenter

DocMeta.setdocmeta!(ODEParameterEstimation, :DocTestSetup, :(using ODEParameterEstimation); recursive=true)

makedocs(;
    modules=[ODEParameterEstimation],
    authors="Oren Bassik <orebas@yahoo.com> and contributors",
    sitename="ODEParameterEstimation.jl",
    format=Documenter.HTML(;
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
