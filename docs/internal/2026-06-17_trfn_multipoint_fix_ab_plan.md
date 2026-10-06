# 2026-06-17 `_trfn_` Multipoint Fix and A/B Plan

## Background

The final paper benchmark data should remain unchanged. It is reproducible as
the June 2026 final-v2 benchmark, but those runs inherited a workaround that
disabled the multipoint branch whenever automatic time-transcendental
variables (`_trfn_*`) were present.

That workaround was conservative: it avoided a real construction bug where
multipoint templates could silently pair instantiated equations with the wrong
symbolic template equations after `_trfn_` equations became trivial and were
pruned. It also meant the reported final-v2 numbers do not measure the intended
multipoint behavior on models with natural `sin(c*t)` inputs.

## Code Change

The fix is to preserve equation provenance during SI-template instantiation:

- `instantiate_si_template_equations` now returns `source_indices`, the original
  SI-template row for each retained instantiated equation.
- Noise-frontier multipoint construction uses those source indices to pair
  instantiated equations with symbolic equations. It no longer uses the old
  prefix/count fallback.
- Legacy multipoint now fails visibly on an equation-count mismatch instead of
  using already-instantiated equations as symbolic stand-ins.
- The top-level `_trfn_` gate has been removed, so multipoint is again allowed
  for transformed transcendental-input systems.

## Verified Canaries

Run from `/home/orebas/.julia/dev/ODEParameterEstimation`:

```bash
julia --project=. -e 'using ODEParameterEstimation; include("test/fast_core.jl")'
```

This passed on 2026-06-17 with 381/381 tests, including the source-index
regression below.

```bash
julia --project=. -e 'using ODEParameterEstimation, Test, ModelingToolkit, OrderedCollections, Symbolics; @independent_variables t; @variables x(t) y(t) y0 y1 x0; trfn_sin = Symbolics.variable(Symbol("_trfn_sin_0_5")); trfn_cos = Symbolics.variable(Symbol("_trfn_cos_0_5")); template_equations = Num[x0 + y0, trfn_sin^2 + trfn_cos^2 - 1, x0^2 + y1]; measured_quantities = [y ~ x]; data_sample = OrderedDict{Any, Any}("t" => [0.0, 1.0, 2.0]); interpolants = Dict{Any, Any}(ModelingToolkit.diff2term(x) => (τ -> 2.0 * τ + 1.0)); template_DD = (obs_lhs = [[y0], [y1]],); derivative_dict = Dict{Any, Int}(y0 => 0, y1 => 1); inst = ODEParameterEstimation.instantiate_si_template_equations(template_equations, measured_quantities, data_sample, derivative_dict, template_DD; interpolants = interpolants, time_index = 2, diagnostics = false, prune_overdetermined = false, substitute_trfn = true); @test length(inst.equations) == 2; @test inst.source_indices == [1, 3]; @test length(inst.trivial_residuals) == 1; @test abs(only(inst.trivial_residuals)) < 1e-12; combined_inst = Any[]; combined_symb = Any[]; source_indices = Int[]; points = Int[]; ODEParameterEstimation._noise_append_source_mapped_equations!(combined_inst, combined_symb, source_indices, points, inst.equations, template_equations, inst.source_indices, 2; diagnostics = false, context = "test"); @test string.(combined_symb) == string.([template_equations[1], template_equations[3]]); @test source_indices == [1, 3]; @test points == [2, 2]; println("trfn source-index canary passed")'
```

Also verified manually: a real `dc_motor_sinusoidal` two-point
noise-frontier multipoint template builds as a square 20-equation template and
evaluates finite per-point data, including `_trfn_` data variables.

## GaussianProcesses/PDMats Compatibility Note

During this work, `test/example_canaries.jl` initially failed before the
transcendental canary because the active registry package combination exposed
an old dependency ambiguity:

```text
MethodError: ldiv!(::PDMats.PDMat{Float64, Matrix{Float64}}, ::Matrix{Float64}) is ambiguous.
Candidates: GaussianProcesses.ldiv!(::PDMats.PDMat, x) and PDMats.ldiv!(::PDMats.AbstractPDMat, ::AbstractVecOrMat)
```

This appears in `aaad_gpr_pivot` during GaussianProcesses hyperparameter
optimization and is not caused by the multipoint provenance fix.  The local
conditional disambiguation in `src/ODEParameterEstimation.jl` now installs
`ldiv!(::PDMats.PDMat, ::AbstractVecOrMat)` only when that exact method is not
already provided by a patched GaussianProcesses fork.  This preserves
compatibility with both the registry package combination and patched benchmark
environments.

## Affected Final-v2 System Families

In the final-v2 generated scripts, the systems using natural `sin(...)` inputs
are:

- `aircraft_pitch`
- `bicycle_model`
- `boost_converter`
- `cstr`
- `dc_motor`
- `forced_lotka_volterra`
- `quadrotor`

These are the first systems to rerun for an impact check. Other systems can be
left out of the initial A/B unless a script-level scan finds `_trfn_` variables
or natural time-transcendental inputs.

## Suggested A/B Run

Use the final-v2 data and options, but run only the proposed polished arm on the
fixed local package. Keep the final-v2 outputs as baseline A and write the fixed
rerun to a new result root, for example:

```text
results/trfn_multipoint_fix_ab_2026_06_17/
```

Minimum useful grid:

- affected systems only: the seven system families listed above;
- all final-v2 noise levels and replicates for those systems;
- polished proposed method first, because that is the headline method;
- optional second pass for `odepe_v2_nopolish_run` if the polished changes are
  scientifically interesting.

Comparison outputs to compute:

- per-cell success flag changes at the paper thresholds;
- aggregate success-rate deltas by system and noise level;
- median and max relative-error deltas;
- provenance distribution, especially how often the selected candidate comes
  from `:multipoint` versus `:single_point`;
- timing deltas for multipoint template construction/evaluation/solve.

Interpretation rule: do not change the paper benchmark numbers unless the A/B
run is reviewed and deliberately adopted. The existing paper data remain a
reproducible snapshot of the final-v2 benchmark.

## Initial Local Pilot

After committing the package fix, a small local pilot was run with the copied
final-v2 generated cells and the local package project activated.  The runner is
`repro/trfn_multipoint_fix_ab_2026_06_17/run_pilot.py`; raw pilot outputs are in
`artifacts/trfn_multipoint_fix_ab_2026_06_17/`.

The pilot deliberately avoided the expensive cells.  The archived final-v2
wall time for `cstr_0_0` is about 12,771 seconds, so CSTR was not run locally.

| Cell | Baseline max error | Fixed max error | Baseline best source | Fixed best source | Raw candidates | Wall time |
| --- | ---: | ---: | --- | --- | ---: | ---: |
| `quadrotor_0_0` | 2.59e-13 | 2.32e-13 | single point | single point | 238 -> 396 | 127.5s -> 279.9s |
| `aircraft_pitch_0_0` | 2.57e-11 | 2.61e-11 | single point | single point | 221 -> 376 | 308.5s -> 325.2s |
| `bicycle_model_0_0` | 8.84e-14 | 1.14e-13 | single point | multipoint | 213 -> 368 | 223.1s -> 392.5s |
| `quadrotor_0_1em2` | 4.999e-2 | 4.999e-2 | not recorded in JSON | single point | 251 -> 391 | 262.8s -> 347.1s |

Observed pattern:

- The fix does activate the intended branch: the fixed pools contain roughly
  109--135 multipoint candidates in these cells, while the final-v2 baseline
  pools contain none.
- Accuracy did not materially change in these four cells.  The only selected
  multipoint best solution was `bicycle_model_0_0`, where the error remained at
  roundoff scale.
- Runtime increased in all four cells, from about 1.05x to 2.20x in this small
  sample.  The direct multipoint template/evaluation/solve timers account for
  only part of the overhead; the larger pool also increases downstream result
  processing, aggregation, and polishing costs.
- These pilot data support treating this as a package correctness fix first and
  an optional benchmark variant second.  They do not justify changing the paper
  benchmark numbers without a deliberate larger rerun.
