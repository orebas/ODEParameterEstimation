# Quick verification: does oracle_error_stats fail (return empty errorvec) on the
# result.csv rows for daisy_mamil3_7_1em4? If yes, that's the smoking gun.
#
# We don't run the pipeline — just simulate what oracle_error_stats would do given
# the saved CSV rows + the truth from the pep.

using CSV
using OrderedCollections
using ModelingToolkit
using ODEParameterEstimation
using ModelingToolkit: D_nounits as D, t_nounits as t
using Symbolics

const ODEPE = ODEParameterEstimation

parameters = @parameters a12 a13 a21 a31 a01
states = @variables x1(t) x2(t) x3(t)
observables = @variables y1(t) y2(t)

p_true = OrderedDict(parameters .=> [0.52, 0.7, 0.367, 0.839, 0.79])
ic_true = OrderedDict(states .=> [0.139, 0.303, 0.457])

println("p_true keys (Symbolics):")
for (k, v) in p_true
    println("  $(k)  | string=$(string(k)) | hash=$(hash(k))")
end
println()
println("ic_true keys:")
for (k, v) in ic_true
    println("  $(k)  | string=$(string(k)) | hash=$(hash(k))")
end

# Simulate building a candidate's parameters dict the way the pipeline does after
# rebuilding the MTK system. Try a few approaches.
println("\n--- Test 1: same Symbolics objects (should match) ---")
test1 = OrderedDict(parameters .=> [0.5, 0.5, 0.5, 0.5, 0.5])
for (k, v) in p_true
    matched = haskey(test1, k)
    println("  haskey(test1, $k) = $matched")
end

# Test with a fresh `@parameters` declaration (this is what may happen if the system is rebuilt)
println("\n--- Test 2: fresh @parameters call (different objects) ---")
parameters2 = @parameters a12 a13 a21 a31 a01
test2 = OrderedDict(parameters2 .=> [0.5, 0.5, 0.5, 0.5, 0.5])
println("  parameters[1] === parameters2[1]: $(parameters[1] === parameters2[1])")
println("  parameters[1] == parameters2[1]:  $(parameters[1] == parameters2[1])")
println("  hash(parameters[1]):  $(hash(parameters[1]))")
println("  hash(parameters2[1]): $(hash(parameters2[1]))")
for (k, v) in p_true
    matched = haskey(test2, k)
    println("  haskey(test2, $k) = $matched")
end

# Test with create_ordered_ode_system (which is what the pipeline does)
println("\n--- Test 3: create_ordered_ode_system rebuild ---")
state_eqs = [
    D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
    D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
    D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
]
mq_orig = [y1 ~ 0.5 * x1, y2 ~ x2]
model, mq = ODEPE.create_ordered_ode_system("daisy", states, parameters, state_eqs, mq_orig)
println("  model type: $(typeof(model))")
# What params does the rebuilt system carry?
sys_params = ModelingToolkit.parameters(model.system)
println("  rebuilt sys params: $sys_params")
for (k, v) in p_true
    matched = any(p -> p === k, sys_params)
    matched_eq = any(p -> p == k, sys_params)
    println("  $(k):  ===any: $matched   ==any: $matched_eq")
end

println("\nORACLE_DEBUG_DONE")
