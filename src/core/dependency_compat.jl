# StructuralIdentifiability 0.5.25--0.5.31 builds input dictionaries from
# generators. On Julia 1.13, an empty generator can produce Dict{Any,Any},
# which does not dispatch to its strictly typed power-series solvers. This
# affects autonomous models during global identifiability analysis.
#
# Supply the missing types only for empty dictionaries, then call the existing
# upstream algorithms. These are additional methods, not replacements. Keep
# the version guard until an upstream release provides typed constructors in
# wronskian.jl and ODE.jl; recheck it when updating StructuralIdentifiability.
# Upstream PR #555 accepts empty Dicts directly. Its development checkout still
# reports 0.5.31, so inspect dispatch as well as the version before adding methods.
if VERSION >= v"1.13" && v"0.5.25" <= Base.pkgversion(StructuralIdentifiability) <= v"0.5.31" &&
   !hasmethod(StructuralIdentifiability.power_series_solution,
       Tuple{StructuralIdentifiability.ODE{Nemo.fpMPolyRingElem},
             Dict{Nemo.fpMPolyRingElem,Int}, Dict{Nemo.fpMPolyRingElem,Int}, Dict{Any,Any}, Int})
    function StructuralIdentifiability.power_series_solution(
        ode::StructuralIdentifiability.ODE{P},
        param_values::Dict{P,T},
        initial_conditions::Dict{P,T},
        input_values::Dict{Any,Any},
        prec::Int,
    ) where {T<:Union{Int,AbstractAlgebra.FieldElem},P<:AbstractAlgebra.MPolyRingElem}
        isempty(input_values) || throw(ArgumentError("untyped input values must be empty"))
        return StructuralIdentifiability.power_series_solution(
            ode, param_values, initial_conditions, Dict{P,Vector{T}}(), prec,
        )
    end

    function StructuralIdentifiability.ps_ode_solution(
        equations::Vector{P},
        initial_conditions::Dict{P,T},
        input_values::Dict{Any,Any},
        prec::Int,
    ) where {T<:Union{Int,AbstractAlgebra.FieldElem},P<:AbstractAlgebra.MPolyRingElem}
        isempty(input_values) || throw(ArgumentError("untyped input values must be empty"))
        return StructuralIdentifiability.ps_ode_solution(
            equations, initial_conditions, Dict{P,Vector{T}}(), prec,
        )
    end
end
