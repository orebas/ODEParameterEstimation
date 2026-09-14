# Biohydrogenation compilation and reusable polishing

The [implementation and comparison record](../../docs/2026-09-13_reusable_polynomial_polishing.md)
explains the change from generating a function after each data substitution to
reusing F(z, d), with the observation jets d supplied at runtime. The final
polisher keeps ForwardDiff, with chunk 1, as its default. Symbolic and
finite-difference Jacobians are selectable. No dependency versions changed.

## Retained inputs and experiments

| Artifact | Meaning |
|---|---|
| `prior_run_timing_excerpt.json` | Earlier completed `--optimize=0` run: 585 polishing calls totaling 1,016.9 s, plus source hashes. The normal-compiler timeout stack was in single-point polishing. |
| `probe.jl`, `kernel_probe.toml` | Initial synthetic-value experiment on the saved SI template (25 × 25, nine data symbols, 383 terms). Demonstrates recompilation when constants are baked into equations. |
| `capture_actual.jl`, `actual_system.toml` | Actual first AGPRobust noise-frontier selection: 25 × 25, 12 data symbols, 375 terms, degree ≤ 4, 75 HC candidates at 20 points. Checks each instantiated equation and the unknown order before retaining it. |
| `polynomial_size.json` | Per-equation term counts and degrees, treating the data symbols as coefficients; includes the capture hash and SymPy version. |
| `compare_actual.jl`, `jacobians_inplace.toml` | Seven Jacobian methods evaluated at the actual roots, compared with a 256-bit symbolic reference. Includes construction, first-call, warm-call, and root-sweep measurements. |
| `jacobians_initial_out_of_place.toml` | Earlier exploratory measurement using out-of-place ForwardDiff. Superseded by the in-place comparison. |
| `replay_actual.jl`, `replay_legacy_forwarddiff.toml` | Exact `cc0c973` polisher replay for the first two points (seven roots), showing first-root compilation recurring at the next point. |
| `replay_forwarddiff.toml`, `replay_symbolic.toml` | Initial prepared-kernel comparison across all 75 roots. ForwardDiff accepts 75; symbolic accepts 74. Successful shared root vectors differ by at most 5.3 × 10⁻¹⁹ relatively. These runs precede the rectangular-buffer fix. |
| `replay_forwarddiff_final.toml` | Final-source replay: all 75 accepted, 4.20 s total including 4.19 s for the first call; zero measured compilation across the remaining 74 calls. |
| `full_biohydrogenation.json` | Full normal-compiler run: options, versions, input/log hashes, phase timings, estimates, recovery errors, and supervisor status. Individual repeated timings and oversized provenance identities are omitted. |
| `full_polish_summary.json` | Full-run kernel hit/miss counts, root-polishing aggregate times, dimensions, and source-version qualification. |
| `type_audit.jl`, `type_audit.txt` | `@code_warntype` on actual-system residual and Jacobian kernels for ForwardDiff and symbolic modes; concrete vector/matrix return types with no `Any` in the reported bodies. |
| `validation.json` | Final source hashes, unchanged active-manifest hash, successful package gates, log hashes, and benchmark recovery errors. |

## Full-run result

The frozen 750-sample fixture (nominal noise 10⁻⁶), nine interpolators, 20 anchors,
and two-point multipoint workflow completed with Julia 1.13.0 and normal
optimization in **1,502.6 s (25.0 min)**. The 585 raw polishing calls used one
prepared kernel and totaled **24.66 s**. There were 179 cache hits after the
first construction.

Parameter recovery remains poor for k₁₀: 5.01170 estimated versus 0.741 generating,
with selected fit error 9.38 × 10⁻¹⁰. The unidentifiable x₇ initial state is fixed
at 4 in original coordinates. Completion here validates compilation reuse; it
is not a claim of successful parameter recovery for this fixture. The earlier
`--optimize=0` run had essentially the same recovery problem. Its different
compiler settings and concurrent workloads preclude treating the runtime ratio
as a controlled speedup measurement.

The full worker loaded the source before the final qualification of
`LinearAlgebra.mul!` in the BFGS gradient branch. It uses TrustRegion for raw
polishing, which does not execute that branch. The final-source replay and
package gates check the final files separately. Input captures and initial
replays retain their own provenance; they are not relabeled as final-source runs.

## Reproduction

Use the global Julia environment with this checkout developed, preserving the
current GaussianProcesses and SIAN development overrides. Always pass
`--startup-file=no`. Probe measurements use normal compiler optimization;
`--compiled-modules=existing` avoids unrelated package precompilation.

```sh
# Jacobian accuracy and timing on the retained actual system.
julia --startup-file=no --compiled-modules=existing repro/biohydrogenation_compilation_2026_09_13/compare_actual.jl repro/biohydrogenation_compilation_2026_09_13/actual_system.toml /tmp/bioh-jacobians.toml

# Prepared-kernel polishing; also accepts symbolic, forwarddiff_auto, finitediff,
# legacy_forwarddiff, and legacy_symbolic. Legacy modes stop after two points.
julia --startup-file=no --compiled-modules=existing repro/biohydrogenation_compilation_2026_09_13/replay_actual.jl repro/biohydrogenation_compilation_2026_09_13/actual_system.toml forwarddiff /tmp/bioh-replay.toml

# Full normal-compiler validation; use a fresh output directory.
python3 repro/deferred_denominators_2026_09_11/supervise.py biohydrogenation /tmp/bioh-reusable-full --seconds 1800

# Isolated tests preserving dependency versions and development paths.
julia --startup-file=no test/current.jl
julia --startup-file=no test/current.jl benchmark
```

`capture_actual.jl OUTPUT_DIRECTORY` is an optional instrumentation script to
recapture the selected system. It inserts a capture call in the loaded estimator
function for that process, runs the frozen rational harness, and interrupts after
the first single-point HC batch. It does not edit package source. The retained
capture is sufficient for the bounded comparisons above.

## Validation

The final focused kernel/solver check passed 30 + 49 assertions. The estimator
integration block passed its 12 assertions in the preceding isolated test run;
that run exposed a BFGS `mul!` name ambiguity, now fixed by qualification. A
separate rectangular test exposed missing residual dimensions, also fixed.

Final Julia 1.13.0 gates passed on September 14, with dependency re-resolution
disabled:

| Gate | Result | Testset time |
|---|---:|---:|
| Full suite, including all 91 new polishing assertions and four new option assertions | 1,934/1,934 | 15m03.8s |
| Recovery benchmark | 10/10 | 10m42.2s |

The benchmark's best-of-branch maximum relative parameter errors were
5.63 × 10⁻⁵ (noisy LV), 6.35 × 10⁻⁹ (noisy simple), 1.02 × 10⁻¹⁰ (clean LV),
and 2.50 × 10⁻⁹ (clean HIV with rescaling). The gates overlapped in separate
processes; times exclude package loading/precompilation. The active dependency
manifest hash still matches the full biohydrogenation run.
