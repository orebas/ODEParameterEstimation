# Direct integration of the seir model to verify ICs/params produce the bilby data.

using ModelingToolkit
using OrdinaryDiffEq
using ModelingToolkit: D_nounits as D, t_nounits as t

@parameters a b nu
@variables S(t) E(t) In(t) Npop(t)

eqs = [
    D(S) ~ (-15840.0*b*In*S) / (3960000.0*Npop),
    D(E) ~ ((15840.0*b*In*S) / (2000.0*Npop) - 6.0*nu*E) / 20.0,
    D(In) ~ (-4.0*a*In + 6.0*nu*E) / 10.0,
    D(Npop) ~ 0.0,
]

@named sys = ODESystem(eqs, t, [S, E, In, Npop], [a, b, nu])
sys = complete(sys)
tspan = (0.0, 60.0)

u0_map = [S => 0.647, E => 0.182, In => 0.418, Npop => 0.321]
p_map = [a => 0.187, b => 0.414, nu => 0.277]

prob = ODEProblem(sys, u0_map, tspan, p_map)
sol = solve(prob, AutoVern9(Rodas4P()), abstol=1e-14, reltol=1e-14)

println("My setup integration results:")
for τ in [0.0, 0.04, 1.0, 4.0, 10.0, 30.0, 60.0]
    state = sol(τ)
    println("t=$τ:  S=$(state[1])  E=$(state[2])  In=$(state[3])  Npop=$(state[4])")
    println("       y1=10*In=$(10*state[3])  y2=2000*Npop=$(2000*state[4])")
end

println()
println("Compare to bilby data.csv:")
println("t=0.00: y1=4.214244978  y2=642.015624")
println("t=0.04: y1=4.197399135  y2=642.095731")
println("t=4.00: y1=5.530080643  y2=642.000067")
