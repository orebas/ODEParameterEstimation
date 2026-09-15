# Run from an environment containing Symbolics; no ODEPE, SIAN or PEtab needed.
# julia --startup-file=no repro/polynomial_zero_2026_09_15/simplify.jl [equation|fragment|expand]
using Symbolics
using Pkg

mode = isempty(ARGS) ? "equation" : only(ARGS)
mode in ("equation", "fragment", "expand") || error("Unknown mode: $mode")
include("sneyd_equation.jl")
fragment = IPR_O_10*l4_0*(100.0 + l_2_0^2)*l_6_0 +
    IPR_O_9*l6_0*l_2_0*l_4_0*(21.0 + l_6_0)
expression = mode == "fragment" ? fragment : sneyd_equation
println("Julia ", VERSION, "; mode=", mode)
for dependency in values(Pkg.dependencies())
    dependency.name in ("Symbolics", "SymbolicUtils") || continue
    println(dependency.name, " ", dependency.version, "; tree=", dependency.tree_hash)
end
# Load the generic operation before measuring the actual polynomial.
operation = mode == "expand" ? Symbolics.expand : Symbolics.simplify
operation(l4_0 + l4_0)
println("START operation; variables=", length(Symbolics.get_variables(expression)))
flush(stdout)
for trial in 1:2
    measurement = @timed operation(expression)
    println("trial=", trial, "; seconds=", measurement.time, "; bytes=", measurement.bytes,
        "; gc_seconds=", measurement.gctime, "; iszero=", isequal(measurement.value, 0))
    flush(stdout)
end
