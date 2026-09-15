# Exact zero detection after SI representative substitution

The supplied-M Sneyd run in the [separate-M experiment](2026-09-15_external_multiplicity.md)
timed out in a cleanup step: after substituting nine fixed parameters, ODEPE
called `Symbolics.simplify` on each template equation solely to decide whether
it was zero. It then retained the unsimplified expression. The full and
selected equation collections repeated this work on overlapping rows.

## Change

`get_si_equation_system` now specializes the full SIAN polynomial collection
in Nemo before converting it to Symbolics. Partial polynomial evaluation
collects coefficients exactly; `iszero` identifies vanished equations. The
selected equations are taken from that specialized collection in their
existing order. Full and selected equations still undergo the existing
Nemo-to-Symbolics conversion.

Fixed values use the same rational conversion as the multiplicity input:
an AbstractFloat becomes its exact binary rational value. This preserves
the supplied assignment and avoids intermediate Float64 rounding during
polynomial specialization. In particular, 0.1 is not approximated as 1//10.
Fixing an initial-state coordinate affects only its order-0 variable, leaving
higher state derivatives as unknowns.

Only identically zero equations are removed. Nonzero constants are retained.
Selected/dropped metadata continues to refer to the original SIAN row indices;
`zero_equation_indices` separately identifies rows removed by specialization.
The existing identifiability request, derivative depth, equation-rank selection,
multiplicity algorithm and numerical solvers are unchanged.

## Simplifier evidence

A standalone 55-monomial, degree-6 polynomial in ten variables reproduces
the high cost without ODEPE, PEtab, or SIAN loaded. Two calls to `simplify`
took 7.2707 and 7.3295 seconds. The second allocated 4,672,372,320 bytes.
The corresponding second `expand` call took 0.000982 seconds and allocated
981,640 bytes. The two-summand fragment printed at interruption takes only
about 0.002 seconds in isolation.

This is a performance report, not evidence of an incorrect symbolic answer.
The application's recorded stacks point to SymbolicUtils' common-factor
pattern matching, but they do not time a particular equation. The draft
report includes the complete polynomial and distinguishes cumulative allocation
from peak memory. It has not been submitted upstream.

## Validation

The full Julia 1.13 `Pkg.test` gate passed **2,281/2,281** in 18m28.2s.
The focused representative/multiplicity contracts passed **122/122**. They cover
exact cancellation, preservation of nonzero constants, underscore-digit
parameter names, state versus higher-state-jet fixing, exact Float64 values,
input ownership, equation metadata and the existing end-to-end recovery cases.

The dense Sneyd rerun passes the new substitution stage. All 72 saved template
equations are exactly equal to the previous template in the same order,
including their 2,362 monomials. The largest equation has 272 monomials and
the maximum degree is 6.

The run used the same model, byte-identical data, identical options and supplied
M=544 as the earlier 600-second run. This time the watchdog interrupted
`_noise_mixed_volume` during candidate-basis scoring after template construction.
The worker measured 575.71 seconds of estimation; the supervisor's wall-clock
stage timer measured 600.92 seconds. Preparation took 147.35 seconds. The last
mixed-volume progress display was 385,736 at 4m10s; this is an unfinished
progress value, not a completed volume or a count of recovered roots. No
parameter estimates were returned. This trial verifies removal of the cleanup
bottleneck, not successful Sneyd estimation.

The global and optional PEtab manifest hashes match the prior run. No dependency
versions, compatibility bounds, or development overrides were changed.
The separate recovery benchmark and registry-only gate were not rerun for this
change; rational-model coverage here includes the representative/multiplicity
fixtures and the full suite's existing rational derivative and feature tests.

Full-suite outcomes and raw evidence are retained in
[`repro/polynomial_zero_2026_09_15`](../repro/polynomial_zero_2026_09_15/README.md).
