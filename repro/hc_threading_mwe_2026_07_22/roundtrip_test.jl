using HomotopyContinuation
const HC = HomotopyContinuation
@var x y z
F = System([x^2 + y^2 - 1.0, 3.0*x - y*z + 2, z^3 - x])
# Capture expressions + variables as strings
exprs = string.(F.expressions)
vars  = string.(F.variables)
println("VARS: ", vars)
println("EXPRS:"); for e in exprs; println("  ", e); end
# Round-trip: rebuild in a fresh scope from strings only
m = Module()
Core.eval(m, :(using HomotopyContinuation))
Core.eval(m, Meta.parse("@var " * join(vars, " ")))
rebuilt_exprs = [Core.eval(m, Meta.parse(e)) for e in exprs]
G = Core.eval(m, :(System([$(rebuilt_exprs...)])))
println("Rebuilt system OK: ", G)
# Confirm identical by solving both
rF = HC.solve(F; threading=false, show_progress=false)
rG = HC.solve(G; threading=false, show_progress=false)
println("nsol F=", HC.nsolutions(rF), " G=", HC.nsolutions(rG))
