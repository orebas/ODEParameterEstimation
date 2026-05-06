# E2 — Where does the best candidate come from? (proper bilby config)

`fitzhugh_nagumo_2_1em4` polish=OFF at the bilby config:
- 12 shooting points, `shooting_warp = true, beta = 3.0` → SP indices `[1, 26, 58, 101, 156, 230, 326, 453, 619, 837, 1124, 1501]` ≈ `t ∈ {0, 0.017, 0.038, 0.067, 0.103, 0.153, 0.217, 0.301, 0.412, 0.557, 0.749, 1.0}`
- 12 interpolators
- `polish_solver_solutions = true, polish_solutions = false`

Pool: 708 raw candidates, 315 cluster reps, **best max-rel-err = 0.0567**.

## The best candidate

```
idx 435 — multipoint, agp_robust_se_times_rq (SExRQ kernel)
   MP combo [101, 837] (t≈0.067 + t≈0.557)
   params:  g=0.7784, a=0.8459, b=0.8367
   states:  Vm=0.42, R=0.4035
   truth:   g=0.779, a=0.849, b=0.887, Vm=0.42, R=0.404
   rel:     0.0567 (worst on b: |0.837-0.887|/0.887 = 5.7%)
   err:     2.92e-6  (very low trajectory loss)
```

**It is multipoint, NOT single-point.** And it comes from a **specific GP kernel** (SE×RQ),
combining two **interior** shooting points (no boundary).

## Per-interpolator breakdown

All 12 interpolators ran. 11 of 12 emitted 64 candidates; FHD only emitted 4.

| Rank | Interpolator | Count | Best rel | Median rel |
|---:|---|---:|---:|---:|
| 1 | **agp_robust_se_times_rq (SExRQ)** | 64 | **0.0567** | 19.79 |
| 2 | agp_robust_rq (RQ) | 64 | 0.0567 | 19.79 |
| 3 | agp_robust (SE) | 64 | 0.0731 | 20.89 |
| 4 | aaad_gpr (AAA+GP pivot) | 64 | 0.0731 | 20.89 |
| 5 | agp_robust_se_plus_rq | 64 | 0.0764 | 18.17 |
| 6 | s3_se_plus_rq | 64 | 0.1436 | 13.14 |
| 7 | s3_rq | 64 | 0.1436 | 13.14 |
| 8 | s3_se_times_rq | 64 | 0.1436 | 13.14 |
| 9 | s3_se | 64 | 0.1436 | 13.14 |
| 10 | s2_aaa_mle | 64 | 0.1436 | 13.14 |
| 11 | aaad (pure rational) | 64 | 2.181 | 28.44 |
| 12 | fhd | 4 | 2.04e4 | 2.76e4 |

Observations:
- **SE×RQ and RQ tie for best** (both 0.0567) — RQ kernel beats plain SE.
- **AAADGPR matches plain AGPRobust SE bit-for-bit** (0.0731 / 20.89). The "AAA pivot" doesn't
  engage on this case, confirming earlier finding that AAADGPR falls through to SE-GP here.
- **All 5 of {S2AAAMLE, S3SE, S3RQ, S3SEpRQ, S3SExRQ} give exactly rel=0.1436, median=13.14**.
  They must converge to the same algebraic root via similar adaptive-tolerance behavior.
- **AAAD pure rational** still works (rel=2.18) but much worse than GP family. AAA is bad
  here because of noise.
- **FHD is broken** for this case (only 4 candidates, all catastrophic).

## Per-source-type breakdown

| | Count | Best rel | Median rel |
|---|---:|---:|---:|
| **multipoint** | 430 | **0.0567** | 16.5 |
| single_point | 278 | 0.0996 | 26.93 |

**Multipoint wins overall AND has lower median.** The earlier "MP makes things worse"
finding (from my deprived-config harness) was wrong.

## Per-shooting-point breakdown (single_point only)

| SP idx | t ≈ | Count | Best rel | Median rel |
|---:|---:|---:|---:|---:|
| 1 | 0.000 | 22 | 23.6 | 78.0 |
| 26 | 0.017 | 22 | 26.5 | 66.1 |
| 58 | 0.038 | 22 | 21.2 | 45.4 |
| 101 | 0.067 | 22 | 7.71 | 22.5 |
| 156 | 0.103 | 23 | 4.06 | 11.9 |
| 230 | 0.153 | 24 | 1.64 | 30.5 |
| **326** | **0.217** | 23 | **0.0996** | 213 |
| 453 | 0.301 | 27 | 0.727 | 158 |
| **619** | **0.412** | 27 | **0.168** | 1.71 |
| **837** | **0.557** | 22 | **0.243** | 32.1 |
| 1124 | 0.749 | 22 | 0.953 | 111 |
| 1501 | 1.000 | 22 | 1.36 | 17.0 |

**Best single shooting points are SP=326 (t=0.22, rel=0.10), SP=619 (t=0.41, rel=0.17),
SP=837 (t=0.56, rel=0.24).** All in the second half of the time interval, where the
trajectory is in the recovery phase. Early-time and end-boundary SPs alone all give rel>1.

## Per-MP-combo breakdown (top 10)

| MP combo `[t_i, t_j]` | t-equivalents | Count | Best rel |
|---|---|---:|---:|
| **[101, 837]** | t≈{0.067, 0.557} | 23 | **0.0567** ← winner |
| [58, 837] | t≈{0.038, 0.557} | 23 | 0.0731 |
| [26, 837] | t≈{0.017, 0.557} | 22 | 0.272 |
| [156, 1124] | t≈{0.103, 0.749} | 22 | 0.321 |
| [1, 1124] | t≈{0, 0.749} | 22 | 0.365 |
| [1, 837] | t≈{0, 0.557} | 22 | 0.432 |
| [26, 1124] | t≈{0.017, 0.749} | 22 | 0.514 |
| [58, 1124] | t≈{0.038, 0.749} | 22 | 0.550 |
| [101, 1124] | t≈{0.067, 0.749} | 22 | 0.551 |
| [230, 1124] | t≈{0.153, 0.749} | 21 | 0.640 |

**The pattern**: best MP combos pair an **early-time** point (t<0.1, in the upstroke
phase) with a **mid/late** point (t≈0.5-0.75, in the recovery phase). Both alone are bad
(SP=101 alone: rel=7.7; SP=837 alone: rel=0.24), but together they yield rel=0.057.

Why does this work? An early point captures the upstroke phase information; a mid/late
point captures the recovery phase information. Together they constrain the slow-variable
dynamics (R) that neither alone resolves. The user's earlier "we don't see the recovery
phase" framing is partly addressed by the MP combo even though the time window is the
same — MP just exploits the data better.

## Why is `b` still 5.7% off in the best candidate?

The best `b` estimate is 0.837 vs truth 0.887. The other 4 unknowns are within ~0.5% of
truth. So the best candidate has `b` as the dominant error, consistent with the
sensitivity-matrix dive's finding that `b`'s row of S has norm 127 (much larger than
g, a, IC). Even with a great MP combo, the noise structure of the data + the slow-mode
identifiability deficit in `[0,1]` keeps `b` from being pinned tighter.

So the practical floor on this case under this config is **rel ≈ 0.05 on b**, set
by R/b coupling and 4-derivative noise propagation.

## Summary

- The best (rel=0.057) candidate is an MP combo of two well-chosen interior shooting points
  using SE×RQ kernel GP.
- Multipoint dominates single-point here once the shooting points are placed sensibly.
- `shooting_warp = true, beta = 3.0` puts more SPs in `[0, 0.2]`, which alone are bad SPs
  but in MP combos extract spike-phase information that pairs well with mid-time recovery
  points.
- 5/12 interpolators reach rel<0.1 (SExRQ, RQ, SE, AAADGPR, SE+RQ); 5 more reach rel<0.15
  (S3 family + S2AAAMLE); pure AAAD reaches rel=2.18; FHD is broken.
- The multi-interpolator default is doing real work — multiple kernels confirm the same
  algebraic root from different angles.
