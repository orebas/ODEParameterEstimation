# Sloppy-Seed Mechanism Dive

Walks the post-polish candidate pool of cases where the v6 sweep showed surprising results.
Each candidate carries a `provenance.source_type` (`:single_point` / `:multipoint` /
`:sensitivity_seed`) and `provenance.polish_applied`. Tagging the oracle-best and fit-best
tells us mechanically what kind of candidate is winning, and whether it's polished.

## Cases

- **fitzhugh_nagumo_2_1em4 polish=OFF**: v6 said 7.06 → 2.54 (oracle-best). What seed produced it?
- **daisy_mamil3_7_1em4 polish=OFF**: v6 said 0.13 → 0.13 (no movement). Why didn't seeds help?
- **seir_2_1em4 polish=ON**: v6 said oracle-best fit went 18.19 → 8290 — "catastrophic". Is the oracle-best a polished result or an unpolished seed?

## fitzhugh_nagumo_2_1em4: polish=OFF, seeds=ON

Pool size: 38 candidates  (elapsed 111.4s)

### Provenance breakdown

| source_type | total | polished |
|---|---:|---:|
| `multipoint` | 6 | 0 |
| `sensitivity_seed` | 26 | 0 |
| `single_point` | 6 | 0 |

### Oracle-best (closest to truth)

- pool index: 18
- source_type: `sensitivity_seed`
- polish_applied: false
- err: 0.1891
- max-rel-err: 6.934
- parameters: `g=0.7925, a=2.04, b=7.038`
- states:     `Vm(t)=0.4199, R(t)=0.419`

### Fit-best (lowest trajectory residual)

- pool index: 3
- source_type: `single_point`
- polish_applied: false
- err: 0.0001498
- max-rel-err: 7.061
- parameters: `g=0.7925, a=2.066, b=7.15`
- states:     `Vm(t)=0.42, R(t)=0.4191`

**Oracle-best == Fit-best?** NO

If we had picked fit-best instead of oracle-best, max-rel-err would be **7.061** (vs oracle-best's 6.934).

### Top candidates by max-rel-err (best 8)

| idx | source | polished | err | max-rel-err |
|---:|---|---|---:|---:|
| 18 | `sensitivity_seed` | false | 0.1891 | 6.934 |
| 3 | `single_point` | false | 0.0001498 | 7.061 |
| 17 | `sensitivity_seed` | false | 0.2021 | 7.061 |
| 34 | `sensitivity_seed` | false | 2.111 | 12.01 |
| 36 | `sensitivity_seed` | false | 2.111 | 12.01 |
| 11 | `multipoint` | false | 0.0004873 | 12.14 |
| 33 | `sensitivity_seed` | false | 2.14 | 12.14 |
| 38 | `sensitivity_seed` | false | 2.14 | 12.14 |

### Top candidates by err (lowest 8)

| idx | source | polished | err | max-rel-err |
|---:|---|---|---:|---:|
| 3 | `single_point` | false | 0.0001498 | 7.061 |
| 4 | `single_point` | false | 0.000456 | 131.2 |
| 12 | `multipoint` | false | 0.0004873 | 12.14 |
| 11 | `multipoint` | false | 0.0004873 | 12.14 |
| 9 | `multipoint` | false | 0.0005757 | 86.69 |
| 7 | `multipoint` | false | 0.0006444 | 84.72 |
| 2 | `single_point` | false | 0.003372 | 88.97 |
| 1 | `single_point` | false | 0.003372 | 88.97 |

## daisy_mamil3_7_1em4: polish=OFF, seeds=ON

Pool size: 18 candidates  (elapsed 56.2s)

### Provenance breakdown

| source_type | total | polished |
|---|---:|---:|
| `multipoint` | 1 | 0 |
| `sensitivity_seed` | 12 | 0 |
| `single_point` | 5 | 0 |

### Oracle-best (closest to truth)

- pool index: 3
- source_type: `multipoint`
- polish_applied: false
- err: 1.859e-5
- max-rel-err: 0.1324
- parameters: `a12=0.4798, a13=0.6931, a21=0.3184, a31=0.8468, a01=0.7917`
- states:     `x1(t)=0.139, x2(t)=0.303, x3(t)=0.4633`

### Fit-best (lowest trajectory residual)

- pool index: 3
- source_type: `multipoint`
- polish_applied: false
- err: 1.859e-5
- max-rel-err: 0.1324
- parameters: `a12=0.4798, a13=0.6931, a21=0.3184, a31=0.8468, a01=0.7917`
- states:     `x1(t)=0.139, x2(t)=0.303, x3(t)=0.4633`

**Oracle-best == Fit-best?** YES

### Top candidates by max-rel-err (best 8)

| idx | source | polished | err | max-rel-err |
|---:|---|---|---:|---:|
| 3 | `multipoint` | false | 1.859e-5 | 0.1324 |
| 11 | `sensitivity_seed` | false | 0.005679 | 0.1324 |
| 12 | `sensitivity_seed` | false | 0.003096 | 0.1362 |
| 10 | `sensitivity_seed` | false | 0.3105 | 2.16 |
| 2 | `single_point` | false | 0.0001396 | 2.16 |
| 9 | `sensitivity_seed` | false | 0.3117 | 2.16 |
| 18 | `sensitivity_seed` | false | NaN | 10.67 |
| 6 | `single_point` | false | 6.895e82 | 11.15 |

### Top candidates by err (lowest 8)

| idx | source | polished | err | max-rel-err |
|---:|---|---|---:|---:|
| 3 | `multipoint` | false | 1.859e-5 | 0.1324 |
| 2 | `single_point` | false | 0.0001396 | 2.16 |
| 1 | `single_point` | false | 0.0009274 | 34.64 |
| 12 | `sensitivity_seed` | false | 0.003096 | 0.1362 |
| 11 | `sensitivity_seed` | false | 0.005679 | 0.1324 |
| 10 | `sensitivity_seed` | false | 0.3105 | 2.16 |
| 9 | `sensitivity_seed` | false | 0.3117 | 2.16 |
| 7 | `sensitivity_seed` | false | 9.04 | 34.64 |

## seir_2_1em4: polish=ON, seeds=ON

Pool size: 449 candidates  (elapsed 70.3s)

### Provenance breakdown

| source_type | total | polished |
|---|---:|---:|
| `multipoint` | 18 | 8 |
| `sensitivity_seed` | 411 | 136 |
| `single_point` | 20 | 8 |

### Oracle-best (closest to truth)

- pool index: 171
- source_type: `sensitivity_seed`
- polish_applied: false
- err: 2.856e7
- max-rel-err: 1.868
- parameters: `a=-0.11, b=0.94, nu=0.3872`
- states:     `S(t)=0.0701, E(t)=-0.1427, In(t)=1.199, Npop(t)=0.321`

### Fit-best (lowest trajectory residual)

- pool index: 11
- source_type: `single_point`
- polish_applied: false
- err: 1.461
- max-rel-err: 27.6
- parameters: `a=-0.3652, b=-0.02211, nu=-0.4869`
- states:     `S(t)=2.52, E(t)=5.206, In(t)=10.68, Npop(t)=0.321`

**Oracle-best == Fit-best?** NO

If we had picked fit-best instead of oracle-best, max-rel-err would be **27.6** (vs oracle-best's 1.868).

### Top candidates by max-rel-err (best 8)

| idx | source | polished | err | max-rel-err |
|---:|---|---|---:|---:|
| 171 | `sensitivity_seed` | false | 2.856e7 | 1.868 |
| 172 | `sensitivity_seed` | false | 2.856e7 | 1.868 |
| 443 | `sensitivity_seed` | true | 8290.0 | 1.992 |
| 301 | `single_point` | true | 3.78e9 | 2.649 |
| 379 | `sensitivity_seed` | true | 20920.0 | 2.719 |
| 201 | `sensitivity_seed` | false | 8.783e7 | 2.878 |
| 200 | `sensitivity_seed` | false | 8.783e7 | 2.878 |
| 396 | `sensitivity_seed` | true | 8.804e7 | 2.917 |

### Top candidates by err (lowest 8)

| idx | source | polished | err | max-rel-err |
|---:|---|---|---:|---:|
| 11 | `single_point` | false | 1.461 | 27.6 |
| 12 | `single_point` | false | 1.461 | 27.6 |
| 16 | `multipoint` | false | 2.181 | 3.695 |
| 17 | `multipoint` | false | 2.181 | 3.695 |
| 18 | `multipoint` | false | 2.218 | 25.05 |
| 15 | `multipoint` | false | 2.218 | 25.05 |
| 6 | `single_point` | false | 18.19 | 3.363 |
| 8 | `single_point` | false | 18.19 | 3.76 |

---

## Quick takeaways

- **fitzhugh_nagumo_2_1em4 / polish=OFF, seeds=ON**: oracle-best is a seed (unpolished, err=0.189, rel=6.93). Fit-best is an algebraic candidate (unpolished, err=0.00015, rel=7.06).
- **daisy_mamil3_7_1em4 / polish=OFF, seeds=ON**: oracle-best is an algebraic candidate (unpolished, err=1.86e-5, rel=0.132). Fit-best is an algebraic candidate (unpolished, err=1.86e-5, rel=0.132).
- **seir_2_1em4 / polish=ON, seeds=ON**: oracle-best is a seed (unpolished, err=2.86e7, rel=1.87). Fit-best is an algebraic candidate (unpolished, err=1.46, rel=27.6).

## Critical addendum (2026-05-04): the v6-sweep wins were from a parser bug

A debugging cycle uncovered that throughout the v6 sweep (and subsequent dives v1–v8), **probes
never fired** because `parse_sensitivity_label` (in `src/core/sigma_d.jl`) only handled
SIAN-style labels (`"y1_0"`), but `_compute_data_sensitivity` returns Symbolics-style labels
(`"Differential(t, 1)(y1(t))"`). Result:
- σ_d alignment failed for every label → `sigma_d_vec = [0, 0, 0, ...]`
- Σ_x = S · diag(0) · S' = 0 → no significant eigenvectors → **0 probes emitted**
- Σ_x⁻¹ via `pinv` returned 0 → Mahalanobis distance d² = 0 for ALL pairs → **all C(n,2) pairs passed the threshold and got blended (mean)**

So the v6 wins came from "blend every pair of algebraic candidates with mean," not from σ_d-aware probes. On fitzhugh the algebraic pool happened to contain candidates with widely different `b` values (`b=7.15` and `b=−9.88`), and their mean (`b=−1.37`) accidentally landed closer to truth (`b=0.887`) than either parent.

After fixing the parser to handle Symbolics labels:
- fitzhugh polish=OFF: 78 → 26 sensitivity seeds (12 probes + 2 blends + 12 self). Oracle-best **regressed** from rel=2.54 (accidental blend) to rel=6.93 (L2-projection probe of fit-best, only moved `b` from 7.15 to 7.04).
- daisy polish=OFF: 21 → 12 sensitivity seeds. Oracle-best unchanged (still the multipoint at 0.132).
- seir polish=ON: 373 → 411 sensitivity seeds (more probes; blends decreased proportionally). Oracle-best **unchanged** (rel=1.87).

The properly-σ_d-scaled probes are TINY (b shifted by ~0.1), and the Mahalanobis-gated blends are FEW (only Σ_x-close pairs survive). The original "buggy" behavior of all-pairs blending was accidentally exploring a much larger neighborhood than the principled mechanism does.

## Implications

1. **The σ_d magnitude is calibrated for derivative-estimation noise (1e-4) but the relevant scale for "how far truth could be from x_c" is much larger** — the algebraic system amplifies noise through its sensitivity. Probes at 1σ_d are well within polish-converged distance of x_c; they don't reach the truth-near regions that exist in the blend-stitched landscape.

2. **The user's intuition (splicing along sloppy directions) was right and the principled probes don't replicate it.** The bug accidentally implemented "average everything," which is a coarser version of "splice along sloppy directions." The principled mechanism — small ±σ_d probes around each candidate — is too local.

3. **Three concrete options to recover the wins:**
   - **(a) Bigger probe magnitude**: bump `sensitivity_seed_probe_scale` to e.g. 10× or 100× the σ_d-derived √λ. Cheap to test.
   - **(b) Generous Mahalanobis threshold**: replace χ²(95%) with something looser, or skip the test entirely for "explore all blends." This recovers the buggy behavior with intent.
   - **(c) Decouple blending metric from Σ_x**: use a different distance (Euclidean in tight-direction space, or rank-based) so blends remain generous regardless of Σ_x scale.

The cheapest experiment: (a) — sweep `probe_scale ∈ {1, 5, 10, 50, 100}` on fitzhugh and watch the oracle-best rel-err.
