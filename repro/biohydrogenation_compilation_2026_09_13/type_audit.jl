using ODEParameterEstimation, TOML, InteractiveUtils
const ODEPE = ODEParameterEstimation
const S = ODEPE.Symbolics
capture = TOML.parsefile("repro/biohydrogenation_compilation_2026_09_13/actual_system.toml")
for name in vcat(capture["solve_variables"], capture["data_variables"])
    Core.eval(Main, Expr(:(=), Symbol(name), QuoteNode(S.variable(Symbol(name)))))
end
vars = S.Num[getfield(Main, Symbol(n)) for n in capture["solve_variables"]]
dvars = S.Num[getfield(Main, Symbol(n)) for n in capture["data_variables"]]
equations = S.Num[Core.eval(Main, Meta.parse(s)) for s in capture["equations"]]
data = Float64.(first(capture["data_values"]))
x = Float64.(first(first(capture["roots"])))
for method in (:forwarddiff, :symbolic)
    kernel = ODEPE.prepare_robust_system(equations, vars; data_vars=dvars, jacobian=method)
    residual! = (r,u) -> kernel.residual!(r,u,data)
    jac! = ODEPE._bind_robust_jacobian(kernel,residual!,data)
    r,J = zeros(length(equations)),zeros(length(equations),length(vars))
    println("METHOD ", method, " RESIDUAL")
    @code_warntype kernel.residual!(r,x,data)
    println("METHOD ", method, " JACOBIAN")
    @code_warntype jac!(J,x)
end
