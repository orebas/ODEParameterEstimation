# Local Polish Investigation Summary

_Generated: 2026-05-01_

## Summary

This note records the current state of the local-polish investigation on the hard positive-box bilby `1e-4` slice. The main question was whether the package should keep the older scalar/BFGS-style polish path as the default, or move to one of the bounded residual least-squares paths.

The tentative conclusion is:

- make **bounded `LeastSquaresOptim.LevenbergMarquardt()` in log-space** the default local polisher,
- keep it **unregularized (`λ = 0`)** for the default,
- keep **bounded `FastLevenbergMarquardt` in log-space** as the main secondary / comparison path,
- do **not** make small log-space `L2` regularization a global default yet.

That recommendation is strong enough now even though the dedicated max-relative-error LSO tuning run is still only through Phase A on `19 / 20` cases.

## Decisive Artifacts

- Standardization sweep:
  - [`artifacts/diagnostics/local_polish_standardization_1em4_hard/summary_clarified.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/local_polish_standardization_1em4_hard/summary_clarified.md)
  - [`artifacts/diagnostics/local_polish_standardization_1em4_hard/summary.tsv`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/local_polish_standardization_1em4_hard/summary.tsv)
- Cross-polish basin diagnostic:
  - [`artifacts/diagnostics/cross_polish_basin_diagnostic/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cross_polish_basin_diagnostic/summary.md)
  - [`artifacts/diagnostics/cross_polish_basin_diagnostic/case_notes.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cross_polish_basin_diagnostic/case_notes.md)
- Full-pool cross-polish check:
  - [`artifacts/diagnostics/cross_polish_basin_diagnostic_fullpool_triplet/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cross_polish_basin_diagnostic_fullpool_triplet/summary.md)
- Clean regularization sweep:
  - [`artifacts/diagnostics/local_polish_regularization_1em4_hard_bfgsfix/summary_clarified.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/local_polish_regularization_1em4_hard_bfgsfix/summary_clarified.md)
  - [`artifacts/diagnostics/local_polish_regularization_1em4_hard_bfgsfix/summary.tsv`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/local_polish_regularization_1em4_hard_bfgsfix/summary.tsv)
- Current LSO max-rel tuning sweep:
  - [`artifacts/diagnostics/lso_tuning_maxrel_1em4_hard/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/lso_tuning_maxrel_1em4_hard/summary.md)
  - [`artifacts/diagnostics/lso_tuning_maxrel_1em4_hard/progress.txt`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/lso_tuning_maxrel_1em4_hard/progress.txt)

## What The Standardization Sweep Showed

The hard-suite standardization sweep used:

- imported bilby `odepe_nopolish` pools,
- ungated analysis,
- oracle best-in-set RMSE as the comparison view,
- shortlist:
  - scalar original-space,
  - scalar log-space,
  - bounded LSO LM log-space,
  - bounded FastLM log-space.

Headline result versus scalar log-space:

- bounded LSO log-space: `13 better / 2 tie / 4 worse / 1 unsupported`
- bounded FastLM log-space: `11 better / 2 tie / 6 worse / 1 unsupported`

Median runtime ratios versus scalar log-space:

- bounded LSO log-space: `0.732x`
- bounded FastLM log-space: `0.546x`

So both residual LM paths beat the scalar log baseline on the hard slice, and both were also faster than scalar.

Representative oracle best-in-set datapoints:

- `daisy_mamil4_1_1em4`
  - scalar log-space: `18.28%`
  - bounded LSO log-space: `0.63%`
  - bounded FastLM log-space: `6.77%`
- `hiv_2_1em4`
  - scalar log-space: `7.95%`
  - bounded LSO log-space: `0.33%`
  - bounded FastLM log-space: `2.79%`
- `hiv_4_1em4`
  - scalar log-space: `39.70%`
  - bounded LSO log-space: `15.31%`
  - bounded FastLM log-space: `90.35%`
- `seir_3_1em4`
  - scalar log-space: `1.04%`
  - bounded LSO log-space: `27.90%`
  - bounded FastLM log-space: `3.89%`
- `hiv_7_1em4`
  - scalar log-space: `4.96%`
  - bounded LSO log-space: `13.83%`
  - bounded FastLM log-space: `15.36%`

This is the main reason the decision narrowed to LSO vs FastLM. The older scalar original-space baseline is clearly dominated.

## What The Cross-Polish Diagnostics Showed

The cross-polish work asked a different question: if method `A` polishes a seed and then method `B` starts from that same seed, do the methods collapse to the same attractor?

The answer was mostly no.

Small representative transfer experiment:

- no case came out `same_basin_likely`
- `different_basin_likely`:
  - `seir_3_1em4`
  - `seir_7_1em4`
  - `crauste_7_1em4`
  - `daisy_mamil4_1_1em4`
  - `seir_6_1em4`
- `mixed`:
  - `hiv_7_1em4`
  - `hiv_4_1em4`
  - `hiv_2_1em4`

Representative pairwise same-attractor counts:

- FastLM -> LSO: `4 / 22`
- LSO -> FastLM: `5 / 22`
- Scalar -> LSO: `5 / 24`
- Scalar -> FastLM: `5 / 24`

Full-pool transfer check on three decisive cases strengthened that result:

- `seir_3_1em4`: `1 / 108` same-attractor transfers
- `daisy_mamil4_1_1em4`: `11 / 554`
- `crauste_7_1em4`: `2 / 120`

Interpretation:

- this is mostly a **different-basin / different-attractor** story,
- not a “same solution, slightly different stopping tolerance” story,
- which is why the residual LM methods can win big on some hard cases without simply being a tighter version of scalar BFGS.

## What The Regularization Sweep Showed

The clean regularization sweep added a log-space `L2` penalty:

- scalar: `RSS(x) + λ ||log(x)||^2`
- residual LM: augmented residual `[r(log(x)); sqrt(λ) * log(x)]`

This effect was real, but not universal.

Representative wins from the clean regularization sweep:

- `seir_6_1em4`
  - scalar: `5.01% -> 0.10%` at `λ = 1e-3`
  - LSO: `11.51% -> 0.07%` at `λ = 1e-3`
  - FastLM: `0.95% -> 0.07%` at `λ = 1e-3`
- `crauste_4_1em4`
  - LSO: `15.28% -> 3.09%` at `λ = 1e-1`
  - FastLM: `15.48% -> 13.53%` at `λ = 1e-1`
- `hiv_4_1em4`
  - LSO: `15.31% -> 11.63%` at `λ = 1e-3`
  - FastLM: `90.35% -> 11.63%` at `λ = 1e-3`

Representative cases where `λ = 0` still stayed best for the residual methods:

- `daisy_mamil4_1_1em4`
- `hiv_5_1em4`
- `biohydrogenation_4_1em4`

Pathological cases remained pathological:

- `brusselator_0_1em4`
- `brusselator_7_1em4`

The main lesson from the regularization sweep was:

- small log-space `L2` is **not** a no-op,
- it can help materially on some `crauste`, `seir`, and `hiv` cases,
- but there is no single nonzero `λ` that is clearly robust enough to declare as the global default from the available evidence.

## What The Current LSO Max-Rel Sweep Shows So Far

The dedicated LSO tuning sweep is using:

- primary metric: oracle best-in-set `max_rel_err`,
- thresholds:
  - `<= 1%`
  - `<= 10%`
  - `<= 50%`,
- Phase A:
  - `λ ∈ {0, 1e-4, 1e-3, 1e-2, 1e-1}`
  - fixed `Δ = 10`
  - baseline tolerances,
- Phase B:
  - planned but not started yet.

Current status from [`progress.txt`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/lso_tuning_maxrel_1em4_hard/progress.txt):

- `19 / 20` Phase A cases flushed
- remaining Phase A case: `hiv_4_1em4`
- `selected_phase_b_lambdas` is still blank
- Phase B has **not** started

Phase A counts on the `19` completed cases:

- LSO `λ = 0`:
  - `0 / 3 / 8` at `1% / 10% / 50%`
  - median max-rel `0.9995`
- LSO `λ = 1e-4`:
  - `1 / 2 / 5`
  - median max-rel `1.1987`
- LSO `λ = 1e-3`:
  - `1 / 2 / 5`
  - median max-rel `1.3010`
- LSO `λ = 1e-2`:
  - `0 / 2 / 5`
  - median max-rel `1.5449`
- LSO `λ = 1e-1`:
  - `0 / 2 / 6`
  - median max-rel `1.5449`

Frozen controls on the same partial Phase A:

- scalar log-space `λ = 0`:
  - `0 / 1 / 1`
  - median max-rel `1.0563`
- bounded FastLM log-space `λ = 0`:
  - `0 / 1 / 4`
  - median max-rel `0.9859`

Interpretation of the partial Phase A:

- LSO is still the right solver family,
- but no nonzero `λ` is an obvious broad default,
- `λ = 0` remains the safest general-purpose choice so far,
- nonzero `λ` looks case-family-specific rather than universal.

Per-case best `λ` counts on the `19` completed Phase A cases:

- `λ = 0`: `11`
- `λ = 1e-1`: `5`
- `λ = 1e-3`: `2`
- `λ = 1e-4`: `1`

So regularization is real, but situational.

## Provisional Recommendation

If a package default must be chosen now:

1. default local polisher:
   - **bounded `LeastSquaresOptim.LevenbergMarquardt()` in log-space**
2. default regularization:
   - **none** for the default, i.e. `λ = 0`
3. secondary / comparison solver:
   - **bounded `FastLevenbergMarquardt` in log-space**

Reasoning:

- the old scalar original-space BFGS-style baseline is clearly beaten,
- the residual LM methods are the right solver family on the hard benchmark slice,
- LSO has the better quality edge overall,
- FastLM is close and usually faster,
- current evidence does not justify hardwiring a nonzero global `λ`.

## Open Items

- `hiv_4_1em4` still has not flushed in the dedicated Phase A max-rel LSO tuning run.
- Phase B of that run is likely overbuilt relative to the remaining decision.
- The sweep artifacts did **not** save full per-coordinate candidate vectors, so coordinate-level “which parameter was worst?” questions require targeted replays.

Current practical stance:

- the default solver-family decision can be made now,
- the global regularization decision should stay conservative for now,
- targeted follow-up on per-case regularization behavior is still useful, but it does not block the default choice.
