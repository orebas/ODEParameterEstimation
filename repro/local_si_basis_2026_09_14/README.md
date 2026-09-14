# Local SI basis validation

Implementation, mathematical scope, and findings:
[`docs/2026-09-14_local_si_basis.md`](../../docs/2026-09-14_local_si_basis.md).

Run from the global Julia environment with the current GaussianProcesses and
SIAN development checkouts. All package gates preserve dependency versions
with `allow_reresolve=false`. The optional PEtab environment is separate and
unchanged. Use fresh output directories for each supervised attempt.

```sh
julia --startup-file=no test/current.jl test_si_local_basis.jl
julia --startup-file=no test/current.jl identifiability_regressions.jl
julia --startup-file=no test/current.jl
julia --startup-file=no test/current.jl benchmark

python3 repro/deferred_denominators_2026_09_11/supervise.py fitzhugh_nagumo /tmp/local-si-fhn --si-fix-strategy local_basis --seconds 1200
python3 repro/deferred_denominators_2026_09_11/supervise.py biohydrogenation /tmp/local-si-bioh --si-fix-strategy local_basis --seconds 2400
python3 repro/deferred_denominators_2026_09_11/supervise.py repressilator /tmp/local-si-repressilator --si-fix-strategy local_basis --seconds 4200
python3 repro/petab/dense_single/supervise.py sneyd /tmp/local-si-sneyd --si-fix-strategy local_basis --seconds 1800
```

For an algorithm comparison, use `--si-fix-strategy identifiable_functions`.
It retains the former classification and fix-selection algorithms but shares
the new reuse of structural analysis between template passes.

`evidence/initial_source.patch` and `initial_source.json` identify the first
implementation relative to `e803f8f`. `default_source.json` identifies the
source used by the full gates and extended repressilator run; the sole
production-code difference at that point is the default changing to
`:local_basis`. The rational runs explicitly select that method in both
versions. Their reports retain options, versions, input hashes, estimates,
timing summaries, and supervisor outcomes.

The first focused attempt passed 196 assertions and had one assertion syntax
error from Symbolics' overloaded tuple-membership operator. The corrected run
passed all 197 assertions. The original error and log hash are recorded in
`initial_source.json`.

`biohydrogenation_comparison.json` checks the new result against
`repro/biohydrogenation_compilation_2026_09_13/full_biohydrogenation.json`.
Its recovery values and fit error match exactly, including the pre-existing
poor k₁₀ estimate. `repressilator_timeout.json` retains the first, insufficient
1,800s attempt; the prior completed baseline already took 2,431.4s.
`repressilator.json` retains the completed 4,200s-cap rerun;
`repressilator_comparison.json` compares its estimates and settings with that
baseline. All nine fitted coordinates agree to within 2.88 × 10⁻¹⁰ in absolute
value. That baseline predates the reusable-polisher change, so the comparison
does not isolate the effect of local SI.

The `sneyd` subdirectory retains the complete run/data/supervisor records,
worker log, and first and last available profile reports, with a hash manifest. It times out
in multiplicity's Gröbner step after local SI completes, not in the former
global identifiable-function calculation. Wall-clock and monotonic timing
disagree in this environment; both recorded values are preserved.

`validation.json` records the completed gates: 197/197 focused assertions,
50/50 existing identifiability regressions across both strategies, 2,159/2,159
full-suite assertions, and 10/10 benchmark assertions. It includes log hashes,
the verified production source hashes, unchanged dependency manifest and
development commits, and the source API audit for the existing SI 0.5.25 lower
compatibility bound. Runtime tests use SI 0.5.31.

Long runs overlap with other validation processes. Their wall times are not
controlled speed comparisons. All validation workers have finished. Sneyd
remains an incomplete estimation run because of the multiplicity bottleneck.
