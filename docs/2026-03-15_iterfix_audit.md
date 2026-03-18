# Iterative-Fixing Audit

- Generated: 2026-03-15T00:55:06.896
- Audit root: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351`
- Summary TSV: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/summary.tsv`

## Totals

- Models audited: 70
- Entered iterative-fix loop: 62
- Fixed at least one parameter: 23
- Used more than one iteration: 23
- Non-completed runs: 11

## Status Counts

- `completed`: 59
- `error`: 9
- `timeout`: 2

## Convergence Reasons

- `determined`: 61
- `exception_before_result`: 7
- `timeout`: 2

## Models That Actually Fixed Parameters

- `aircraft_pitch` (`structural_unidentifiability`): iterations=4, fixed=M_delta_e, V_air, Z_alpha
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/aircraft_pitch.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/aircraft_pitch.log`
- `bicycle_model` (`green`): iterations=3, fixed=lf, m
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/bicycle_model.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/bicycle_model.log`
- `bicycle_model_identifiable` (`green`): iterations=2, fixed=Cf
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/bicycle_model_identifiable.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/bicycle_model_identifiable.log`
- `bicycle_model_sinusoidal` (`hard`): iterations=2, fixed=Cf
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/bicycle_model_sinusoidal.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/bicycle_model_sinusoidal.log`
- `bilinear_system` (`green`): iterations=7, fixed=b1, a11, n1, n2, a22, a12
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/bilinear_system.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/bilinear_system.log`
- `boost_converter` (`limitations`): iterations=3, fixed=R, L
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/boost_converter.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/boost_converter.log`
- `cart_pole_linear` (`hard`): iterations=2, fixed=m
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/cart_pole_linear.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/cart_pole_linear.log`
- `cstr_fixed_activation` (`limitations`): iterations=2, fixed=dH_rhoCP
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/cstr_fixed_activation.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/cstr_fixed_activation.log`
- `cstr_reparametrized` (`limitations`): iterations=2, fixed=Cin
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/cstr_reparametrized.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/cstr_reparametrized.log`
- `dc_motor` (`green`): iterations=5, fixed=V, R, b, J
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/dc_motor.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/dc_motor.log`
- `dc_motor_identifiable` (`structural_unidentifiability`): iterations=2, fixed=Kt
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/dc_motor_identifiable.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/dc_motor_identifiable.log`
- `dc_motor_sinusoidal` (`hard`): iterations=2, fixed=Kt
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/dc_motor_sinusoidal.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/dc_motor_sinusoidal.log`
- `flexible_arm` (`green`): iterations=2, fixed=bt
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/flexible_arm.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/flexible_arm.log`
- `forced_lotka_volterra` (`hard`): iterations=2, fixed=b
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/forced_lotka_volterra.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/forced_lotka_volterra.log`
- `global_unident_test` (`structural_unidentifiability`): iterations=2, fixed=b
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/global_unident_test.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/global_unident_test.log`
- `maglev_linear` (`green`): iterations=3, fixed=delta_V, Ki
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/maglev_linear.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/maglev_linear.log`
- `mass_spring_damper` (`structural_unidentifiability`): iterations=2, fixed=m
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/mass_spring_damper.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/mass_spring_damper.log`
- `quadrotor_altitude` (`green`): iterations=3, fixed=d, g
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/quadrotor_altitude.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/quadrotor_altitude.log`
- `sum_test` (`green`): iterations=2, fixed=c
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/sum_test.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/sum_test.log`
- `thermal_system` (`green`): iterations=3, fixed=Q, Ta
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/thermal_system.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/thermal_system.log`
- `treatment` (`structural_unidentifiability`): iterations=2, fixed=d
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/treatment.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/treatment.log`
- `trivial_unident` (`structural_unidentifiability`): iterations=2, fixed=b
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/trivial_unident.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/trivial_unident.log`
- `two_compartment_pk` (`structural_unidentifiability`): iterations=4, fixed=V2, V1, k21
  raw log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/raw/two_compartment_pk.log`
  key log: `/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/iterfix_audit/2026-03-14_231351/key/two_compartment_pk.log`

## Models With Multiple Iterations But No Recorded Fix

None.

## Non-Completed Models

- `ball_beam` (`limitations`): status=`error`, reason=`exception_before_result`
  exception: `Incomplete symbolic substitution in multipoint_numerical_jacobian:
  Expression: Differential(t, 2)(r(t))
  After substitution: -Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.019225435134670642,0.0,0.0,0.0,0.0,0.0,0.03885913993906899,0.0,0.0,0.1950561202425888) + Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.6055691739905238,0.0,0.0,0.0,0.7142857142857143,0.0,0.0,0.0,0.0,0.0)sin(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.5258970668974733,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0))
  Result type: SymbolicUtils.BasicSymbolicImpl.var"typeof(BasicSymbolicImpl)"{SymbolicUtils.SymReal}
  obs_rhs index: i=3, j=1
  Number of derivative levels in states_lhs: 10
  Number of derivative levels in obs_rhs: 10
  Dict keys (first 20): Symbolics.Num[m, R, J_beam, g, tau, r(t), rdot(t), theta(t), omega(t), Differential(t, 1)(r(t)), Differential(t, 1)(rdot(t)), Differential(t, 1)(theta(t)), Differential(t, 1)(omega(t)), Differential(t, 2)(r(t)), Differential(t, 2)(rdot(t)), Differential(t, 2)(theta(t)), Differential(t, 2)(omega(t)), Differential(t, 3)(r(t)), Differential(t, 3)(rdot(t)), Differential(t, 3)(theta(t))]`
- `cart_pole` (`limitations`): status=`error`, reason=`exception_before_result`
  exception: `Incomplete symbolic substitution in multipoint_numerical_jacobian:
  Expression: Differential(t, 2)(x(t))
  After substitution: (Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.9336960945172591,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0) + Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.40213572722099133,0.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)sin(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.6242285564200162,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0))*(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.19338243646697206,0.0,0.0,0.6025624463559692,0.0,0.0,0.0,0.0,0.0,0.4982484916048356) + Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.24564544250440035,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,0.0)cos(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.6242285564200162,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0)))) / (Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.6423830284731114,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0) + Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.40213572722099133,0.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)(sin(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.6242285564200162,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0))^2))
  Result type: SymbolicUtils.BasicSymbolicImpl.var"typeof(BasicSymbolicImpl)"{SymbolicUtils.SymReal}
  obs_rhs index: i=3, j=1
  Number of derivative levels in states_lhs: 10
  Number of derivative levels in obs_rhs: 10
  Dict keys (first 20): Symbolics.Num[M, m, l, g, F, x(t), v(t), theta(t), omega(t), Differential(t, 1)(x(t)), Differential(t, 1)(v(t)), Differential(t, 1)(theta(t)), Differential(t, 1)(omega(t)), Differential(t, 2)(x(t)), Differential(t, 2)(v(t)), Differential(t, 2)(theta(t)), Differential(t, 2)(omega(t)), Differential(t, 3)(x(t)), Differential(t, 3)(v(t)), Differential(t, 3)(theta(t))]`
- `crauste_revised` (`limitations`): status=`error`, reason=`determined`
  exception: `OverflowError: 21 is too large to look up in the table; consider using 'factorial(big(21))' instead`
- `cstr` (`limitations`): status=`timeout`, reason=`timeout`
- `cstr_reparametrized` (`limitations`): status=`timeout`, reason=`timeout`
- `magnetic_levitation` (`limitations`): status=`error`, reason=`exception_before_result`
  exception: `ArgumentError: invalid argument #4 to LAPACK call`
- `seir` (`limitations`): status=`error`, reason=`determined`
  exception: `State S is missing from the SIAN re-solve output and is not directly reconstructible. Refusing to fabricate a fallback value without polish.`
- `sirsforced` (`limitations`): status=`error`, reason=`exception_before_result`
- `swing_equation` (`limitations`): status=`error`, reason=`exception_before_result`
  exception: `Incomplete symbolic substitution in multipoint_numerical_jacobian:
  Expression: Differential(t, 1)(Delta_omega(t))
  After substitution: Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.4430026874593673,-0.7465459385499756,0.0,0.0,0.842597527829275,0.0,0.0,0.0)(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.19057566622752287,0.0,-0.532368872053009,0.0,0.0,1.0,0.0,-0.4563155841431171) - Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.9451411958941817,0.0,0.0,1.0,0.0,0.0,0.0,0.0)sin(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.39723359033175487,0.0,0.0,0.0,0.0,0.0,1.0,0.0)))
  Result type: SymbolicUtils.BasicSymbolicImpl.var"typeof(BasicSymbolicImpl)"{SymbolicUtils.SymReal}
  obs_rhs index: i=2, j=1
  Number of derivative levels in states_lhs: 9
  Number of derivative levels in obs_rhs: 9
  Dict keys (first 20): Symbolics.Num[H, D_damp, Pmax, omega_s, Pm, delta(t), Delta_omega(t), Differential(t, 1)(delta(t)), Differential(t, 1)(Delta_omega(t)), Differential(t, 2)(delta(t)), Differential(t, 2)(Delta_omega(t)), Differential(t, 3)(delta(t)), Differential(t, 3)(Delta_omega(t)), Differential(t, 4)(delta(t)), Differential(t, 4)(Delta_omega(t)), Differential(t, 5)(delta(t)), Differential(t, 5)(Delta_omega(t)), Differential(t, 6)(delta(t)), Differential(t, 6)(Delta_omega(t)), Differential(t, 7)(delta(t))]`
- `tank_level` (`limitations`): status=`error`, reason=`exception_before_result`
  exception: `Incomplete symbolic substitution in multipoint_numerical_jacobian:
  Expression: Differential(t, 1)(h(t))
  After substitution: (Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.41429023749506,0.0,0.0,1.0,0.0) - Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.22601393087805732,0.0,1.0,0.0,0.0)sqrt(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.025858932556401704,0.0,0.0,0.0,1.0))) / Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.20879599145462824,1.0,0.0,0.0,0.0)
  Result type: SymbolicUtils.BasicSymbolicImpl.var"typeof(BasicSymbolicImpl)"{SymbolicUtils.SymReal}
  obs_rhs index: i=2, j=1
  Number of derivative levels in states_lhs: 6
  Number of derivative levels in obs_rhs: 6
  Dict keys (first 20): Symbolics.Num[A, k, Qin, h(t), Differential(t, 1)(h(t)), Differential(t, 2)(h(t)), Differential(t, 3)(h(t)), Differential(t, 4)(h(t)), Differential(t, 5)(h(t)), Differential(t, 6)(h(t))]`
- `two_tank` (`limitations`): status=`error`, reason=`exception_before_result`
  exception: `Incomplete symbolic substitution in multipoint_numerical_jacobian:
  Expression: Differential(t, 1)(h1(t))
  After substitution: (Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.32924039449566556,0.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0) - Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.7219891217802363,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0)sqrt(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(-0.6902022551983718,0.0,0.0,0.0,0.0,0.0,0.0,1.0,-1.0)) - Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.6811419484322602,0.0,0.0,1.0,0.0,0.0,0.0,0.0,0.0)sqrt(Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.1466134265197987,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0))) / Dual{ForwardDiff.Tag{ODEParameterEstimation.var"#f#multipoint_numerical_jacobian##0"{Vector{Any}, OrderedCollections.OrderedDict{Symbolics.Num, Float64}, Int64, Int64}, Float64}}(0.6727531497923751,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)
  Result type: SymbolicUtils.BasicSymbolicImpl.var"typeof(BasicSymbolicImpl)"{SymbolicUtils.SymReal}
  obs_rhs index: i=2, j=1
  Number of derivative levels in states_lhs: 9
  Number of derivative levels in obs_rhs: 9
  Dict keys (first 20): Symbolics.Num[A1, A2, k1, k2, k12, Qin, h1(t), h2(t), Differential(t, 1)(h1(t)), Differential(t, 1)(h2(t)), Differential(t, 2)(h1(t)), Differential(t, 2)(h2(t)), Differential(t, 3)(h1(t)), Differential(t, 3)(h2(t)), Differential(t, 4)(h1(t)), Differential(t, 4)(h2(t)), Differential(t, 5)(h1(t)), Differential(t, 5)(h2(t)), Differential(t, 6)(h1(t)), Differential(t, 6)(h2(t))]`
