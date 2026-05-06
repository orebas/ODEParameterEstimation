# Sensitivity-matrix dive — fitzhugh polish=OFF (single-point at diagnose-chosen t≈0.499)

Three questions, with the actual numbers:

## 1. What does S look like?

**System**: 14 polynomial equations × 14 unknowns. Unknowns are: 3 params (g, a, b),
2 ICs (Vm_0, R_0), 5 Vm-derivative auxiliaries (Vm_1..Vm_5), 4 R-derivative auxiliaries
(R_1..R_4). Data side: 5 derivative coefficients of `y1` (orders 0..4).

**Singular values of `∂F/∂x`** (the "Jacobian-of-the-system" matrix):

```
σ_1  = 1087.6     ≈ well-determined direction
σ_2  = 158.1
σ_3  = 12.7
σ_4  = 8.58
σ_5..σ_10 in [0.7, 3.0]
σ_11 = 0.217
σ_12 = 0.0513
σ_13 = 0.0150
σ_14 = 9.6e-4    ← extremely sloppy direction
cond = σ_1/σ_14 = 1.13×10⁶
```

**Most-sloppy direction** (right singular vector for σ_14):

```
Vm_5    : 0.9936    ← 99.4% of the sloppy direction is Vm_5
b       : 0.106     ← b is the second-most-loaded coordinate
a       : -0.0351
R_4     : -0.0135
(everything else < 0.01)
```

So the "sloppy direction" the system can't pin down is overwhelmingly **the 5th derivative
of Vm**, with ~10% leakage into b. In effect, the system has trouble distinguishing "what's
Vm_5 vs what's b" — they share the sloppy direction.

**Per-row norms of S (per-unknown total amplification)**:

```
Vm_5    : 1034     ← auxiliary 5th-derivative
b       : 127      ← parameter b — second-largest, 45× more amplified than g
a       : 40.6
R_4     : 16.9
R_2     : 9.7
R_1     : 5.3
R_0     : 4.2
g       : 2.76     ← parameter g is well-determined (small row norm)
R_3     : 2.7
Vm_0..4 : 0.5      ← Vm and its derivatives are locked to data (scale = -2)
```

**Per-column norms of S (which data input is most amplified)**:

```
y1                     : 758.7    ← order 0 — surprisingly large
dy1/dt                 : 694.5    ← order 1
d²y1/dt²               : 170.8
d³y1/dt³               : 16.1
d⁴y1/dt⁴               : 2.5      ← order 4 — smallest column!
```

The **column-norm hierarchy is INVERTED from what I expected**: order 0 has the largest
column norm, order 4 the smallest. So the SI template's amplification factor is HIGHEST
for low-order data and LOWEST for high-order data.

**Top 10 individual `S[unknown, data]` entries by magnitude**:

```
S[Vm_5, y1]                = -754.2
S[Vm_5, dy1/dt]            = 690.7
S[Vm_5, d²y1/dt²]          = -152.8
S[b,    y1]                = -78.9
S[b,    d²y1/dt²]          = -75.8
S[b,    dy1/dt]            = 61.8
S[a,    dy1/dt]            = -37.1
S[a,    y1]                = 16.4
S[b,    d³y1/dt³]          = -15.8
S[R_4,  y1]                = 15.1
```

The biggest individual S-entries for `b` are with **low-order derivatives**, not order 4.
`b`'s row is dominated by `(-78.9, 61.8, -75.8, -15.8, ...)` for orders 0, 1, 2, 3
respectively. The order-4 entry is small (we infer ~1.3 from the prediction).

## 2. How does 2.2% derivative error become 700% parameter error?

The "2.2% error in d_4" is a relative figure. Let's trace the actual amplification:

**Step 1 — convert each order's relative error into absolute error** (using d_truth at t=0.499):

| order | rel error | true value | |δd| (absolute) |
|---:|---:|---:|---:|
| 0 | 1.4e-6 | -1.65 | 2.3e-6 |
| 1 | 1.1e-4 | -0.577 | 6.5e-5 |
| 2 | 8.2e-4 | 2.67 | 2.2e-3 |
| 3 | 7.0e-3 | -17.1 | 0.12 |
| 4 | 2.2e-2 | 70.7 | **1.56** |

**Step 2 — propagate each `|δd|` through `S[b, d_k]`** to get the per-order contribution
to `|Δb|`:

| order | S[b, d_k] | |δd_k| | contribution = |S| · |δd| |
|---:|---:|---:|---:|
| 0 | -78.9 | 2.3e-6 | 1.8e-4 |
| 1 | 61.8 | 6.5e-5 | 4.0e-3 |
| 2 | -75.8 | 2.2e-3 | 0.17 |
| 3 | -15.8 | 0.12 | **1.9** |
| 4 | -1.29 | 1.56 | **2.0** |

Sum: **|Δb_predicted| ≈ 4.07** (rough — assumes worst-case sign alignment).

The IFT linear prediction (signed sum from the script): `Δb_predicted = -4.06`.

**Step 3 — nonlinear correction**:

```
Δb_predicted (linear, IFT)   ≈ -4.06
Δb_actual (pool best − truth) =  +6.26
ratio                         = -1.54×  (sign flip + magnitude growth)
```

The nonlinearity in the polynomial system roughly doubles the displacement and
flips its sign, so `|Δb|` grows from ~4 to ~6.3.

**Step 4 — relative error**:

```
Δb_actual = 6.26
b_truth   = 0.887
rel_err(b) = 6.26 / 0.887 = 7.06 = 706%
```

The "706%" is high partly because |truth(b)| = 0.887 is small relative to the displacement.
If truth(b) were 10 instead, the same `|Δb|=6.3` would give 63% rel-err.

**The 2.2% → 706% amplification factor decomposes as**:

| Step | Factor |
|---|---:|
| Order-4 absolute amplification (rel × |true|) | 1.56 / 0.022 = **70.7×** (just |true_d_4|) |
| Order-4 contribution through `S[b, d_4]` (~1.3) | × **1.3 / 0.022 = 59×** |
| Plus contributions from orders 0..3 | × **~2.0** combined |
| Plus nonlinearity | × **~1.5** |
| Divide by truth(b) for rel-err | × **1 / 0.887 = 1.13** |

The dominant amplification is from `|true_d_4| = 70.7` (the absolute size of the
high-order derivative is large because of the cubic Vm³ term). So even a small relative
error on a large absolute value of d_4 = a lot of absolute parameter shift.

## 3. Why is multipoint even worse?

I ran diagnose in multipoint mode (`t_eval_points = [0.0, 0.18, 1.0]`); it emitted a
12-entry `derivative_grid`, presumably (4 interpolators × 3 points) reports.

But the more relevant signal is empirical: the v6 pool dive showed all multipoint
candidates (idx 7–12) had max-rel-err 12 to 90, i.e., WORSE than every reasonable
single-point candidate (idx 3 at rel=7.06). Specifically:

- MP combo [1, 275]: best gives rel=12.14 (b=−9.88)
- MP combo [1, 1501]: gives rel=24.9 (b=−21)
- MP combo [275, 1501]: gives rel=86.7 (b=−76)

**Why does combining shooting points make things worse?** Two suspects:

1. **Boundary derivative explosion.** SP=1 is at t=0 and SP=1501 is at t=1.0 — both at
   the boundaries of the data grid. AAA-GPR's high-order derivative estimates at boundaries
   can be 10–100× worse than interior points (per the 2026-02-19 boundary-derivative analysis
   memo). When the MP-combined system uses these bad boundary derivatives, the combined
   noise blows up the sensitivity.

2. **Multipoint adds equations but doesn't necessarily reduce the sloppy direction.** If
   the sloppy direction (mostly Vm_5) is shared across shooting points (which it is, since
   the ODE is the same), then adding more equations from a worse-conditioned point
   actively worsens the conditioning.

To answer the question precisely I'd need to extract `S` from the MP-combined system —
which the diagnose `derivative_grid` doesn't expose directly. That's a small follow-up
script: build the MP polynomial system explicitly and SVD it. **Deferred** unless the
findings here warrant it.

## TL;DR per question

**Q. What does S look like?**
A. `S` is 14×5. Row for `b` has norm 127 (vs `g`'s 2.76 — 45× difference). The
sloppy direction is overwhelmingly Vm_5 with ~10% projection onto `b`. Largest individual
entries: `S[b, y1] = -78.9`, `S[b, d²y1/dt²] = -75.8` — `b`'s coupling is to LOW-order
derivatives, not high-order.

**Q. How does 2.2% become 700%?**
A. Linear IFT predicts |Δb| ≈ 4 from per-order errors propagating through S. Nonlinearity
grows that to 6.26. Relative error is 6.26 / 0.887 = 706%. The large |true_d_4| = 70.7
is the dominant absolute-error source even though the order-4 column of S is the smallest.

**Q. Why is MP even worse?**
A. Empirically it is (rel=12+ vs SP's rel=7). Likely cause: boundary points (SP=1, SP=1501)
have catastrophic high-order derivative errors via AAA's boundary failure mode. MP combines
them with the good interior point and the noise dominates. A definitive answer needs an
explicit MP-system SVD; deferred.
