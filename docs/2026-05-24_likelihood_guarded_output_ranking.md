# Likelihood-Guarded Output Ranking

Date: 2026-05-24

## Motivation

The current default output ranking uses `rank_strategy = :sat_neg1_err`
("S2"):

```julia
(saturation_count(candidate), is_untagged(candidate), err(candidate))
```

This means provenance can dominate the fit residual by an arbitrary amount.
Empirically this helped coarse benchmark metrics, especially on noisy cells,
because lower residual can mean overfitting or selecting the wrong algebraic
branch. But the same rule can fail badly when an untagged or aggregate row has
a vastly better fit and is truth-near.

The offline wallaby replay tested crude guardrails of the form:

```text
use S2 unless S2's selected residual is worse than the best sat_err residual
by more than a fixed ratio
```

This worked best around `1e6`, while `1e3` was too aggressive and hurt high-noise
cells. That suggests the guardrail should depend on the amount of data and
estimated noise, not a raw residual ratio.

## Proposed Statistical Framing

Treat S2's provenance preference as a prior and trajectory residual as a
likelihood.

Let:

- `c` be the candidate selected by S2.
- `b` be the best candidate under a less provenance-heavy rule such as
  `:sat_err`.
- `S_c` and `S_b` be comparable trajectory sum-of-squared errors.

Under Gaussian measurement noise with known or estimated variance:

```text
log likelihood gain for b over c = (S_c - S_b) / (2 sigma_hat^2)
```

Fallback from S2 to `b` when:

```text
(S_c - S_b) / (2 sigma_hat^2) > log_prior_odds + log_decision_odds
```

Equivalently:

```text
S_c - S_b > 2 sigma_hat^2 * K
```

where:

```text
K = log_prior_odds + log_decision_odds
```

Example:

```text
prior_odds = 100      # HC-tagged provenance is trusted 100x a priori
alpha = 0.01          # require 99:1 posterior odds before fallback
decision_odds = (1 - alpha) / alpha = 99

K = log(100) + log(99) ≈ 9.2
fallback if S_c - S_b > 18.4 sigma_hat^2
```

This is more interpretable than `S_c / S_b > 1e6`: it says exactly how much
statistical evidence is required to overrule the provenance prior.

## Normalized Residual Version

The cleanest implementation is to compute a normalized selection loss:

```text
S_norm(candidate) = sum_i ((y_model_i - y_data_i) / sigma_i)^2
```

Then:

```text
log likelihood gain = (S_norm_c - S_norm_b) / 2
fallback if S_norm_c - S_norm_b > 2K
```

This automatically accounts for:

- number of data points,
- number of observables,
- observable-specific noise scales,
- higher uncertainty at high noise.

It also explains why a fixed ratio was fragile: high-noise cells can have
fit-best but truth-wrong candidates, while low-noise cells make large residual
gaps much stronger evidence of a ranking failure.

## Unknown-Variance Approximation

If a reliable `sigma_i` is unavailable, use an unknown-variance likelihood
proxy:

```text
n_eff * log(S_c / S_b) > K_ratio
```

where:

```text
n_eff = number of scalar observed data points
      = datasize * number_of_observables
```

This form makes the residual ratio threshold shrink as data volume grows. It is
still less desirable than normalized residuals because raw `S` can include
observable-scale effects.

## Candidate Policy

A production policy could be:

1. Rank candidates with current S2.
2. Rank candidates with `:sat_err` plus branch diversity.
3. Let `c` be the S2-selected output row or row set.
4. Let `b` be the best `:sat_err` alternative.
5. Only consider fallback if `b` is not more bound-saturated than `c`.
6. Compute likelihood gain using normalized selection loss.
7. Fall back when likelihood gain exceeds the configured prior/decision
   threshold.

This keeps the useful part of S2:

```text
provenance and saturation act as regularizers
```

but bounds the damage:

```text
provenance cannot dominate overwhelming statistical evidence forever
```

## Implementation Requirements

To make this robust, ODEPE needs a selection-time residual API distinct from
the current `candidate.err`:

- `selection_loss(candidate, problem, opts)`: trajectory loss used only for
  final ranking.
- `selection_loss_kind`: `:raw_sse`, `:normalized_sse`, or `:unknown_variance`.
- `noise_scale` source:
  - explicit user-provided noise level when available,
  - per-observable estimated noise from interpolation/GP diagnostics when
    available,
  - fallback robust residual scale otherwise.
- metadata in `result.csv` / sidecar:
  - S2 selected row,
  - fallback row,
  - normalized loss gap,
  - prior odds / decision threshold,
  - whether fallback fired.

The existing `err` should not be silently reinterpreted because it is used in
several places and is not consistently normalized.

## Suggested Defaults For Experiments

Initial experiment grid:

```text
prior_odds:      10, 100, 1000
alpha:           0.10, 0.05, 0.01
loss kind:       normalized_sse, unknown_variance
candidate alt:   sat_err, sat_err + branch diversity
```

Report:

- full wallaby @50/@10/@1,
- regression subset @50/@10/@1,
- high-noise losses,
- low-noise rescues,
- number of fallbacks fired,
- per-system gains/losses.

Acceptance criteria should be stricter than the raw `1e6` replay:

- non-negative full @50,
- no material @10 loss,
- fewer high-noise false fallbacks than the `1e3` raw-ratio policy,
- explicit improvement on known catastrophic S2 failures such as `cstr_0_0`.

## Current Recommendation

Do not replace S2 with raw `err` ranking. The `1e3` replay shows that can
overfit high-noise cells and hurt truth recovery.

Also do not promote a fixed raw ratio as a principled default. `1e6` is a useful
empirical guardrail, but a likelihood-guarded policy is the cleaner direction:
S2 supplies the prior; normalized trajectory loss supplies the likelihood; the
fallback threshold is expressed as odds rather than a magic residual ratio.
