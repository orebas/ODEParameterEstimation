# Do the two "branches" reproduce the observed In(t) curve, or are they bad roots?
using OrdinaryDiffEq

# D(S)=-b S In/N ; D(E)= b S In/N - nu E ; D(In)= nu E - a In ; D(N)=0
function seir!(du, u, p, t)
    S, E, In, N = u
    a, b, nu = p
    du[1] = -b*S*In/N
    du[2] =  b*S*In/N - nu*E
    du[3] =  nu*E - a*In
    du[4] = 0.0
end

tspan = (0.0, 60.0)
tsamp = range(0.0, 60.0, length=11)

cases = [
  ("TRUTH   ", [990.0, 10.0, 0.0, 1000.0],                                   [0.2, 0.4, 0.15]),
  ("BRANCH-1", [420.01056337722684, 5.62234793784651, 1.2795795700830634e-13, 1000.0], [0.08320754663852091, 0.46047786217746406, 0.2667924533631822]),
  ("BRANCH-2", [352.1317801877017, 5.319028342517032, -2.3808610440999783e-14, 1000.0], [0.06799360647273368, 0.48915369730500985, 0.28200639353832047]),
]

# reference: TRUE In(t)
soltrue = solve(ODEProblem(seir!, cases[1][2], tspan, cases[1][3]), Vern9(), abstol=1e-12, reltol=1e-12)
In_true = [soltrue(t)[3] for t in tsamp]

println("Observed-In curve from TRUTH (what the data actually is):")
for (i,t) in enumerate(tsamp)
    println("  t=", round(t,digits=1), "  In=", round(In_true[i], digits=5))
end
println()

for (name, u0, p) in cases
    sol = solve(ODEProblem(seir!, u0, tspan, p), Vern9(), abstol=1e-12, reltol=1e-12)
    In_curve = [sol(t)[3] for t in tsamp]
    maxdiff = maximum(abs.(In_curve .- In_true))
    println(name, " : max|In - In_true| over [0,60] = ", maxdiff)
    println("           In(t) = ", round.(In_curve, digits=4))
end

println()
println("=== local jet at t0 (In and derivatives), TRUE ===")
# In_0=0, In_1=nu*E0=1.5, In_2 = nu*E' - a*In' = nu*(bS In/N - nuE) - a*(nuE) at t0
E0=10.0; nu=0.15; a=0.2; b=0.4; S0=990.0; N=1000.0; In0=0.0
In1 = nu*E0 - a*In0
Ep0 = b*S0*In0/N - nu*E0
In2 = nu*Ep0 - a*In1
println("In_0=", In0, "  In_1=", In1, "  In_2=", In2)
println("(anchor instantiated eqs had In_1=1.4999999999, In_2=-0.5250000000 — i.e. the TRUE jet)")
