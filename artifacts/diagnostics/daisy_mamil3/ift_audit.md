# IFT Audit: daisy_mamil3 instance 7 (noise 1e-4)

## Question

Can we explain the HC solution error (Δx = x_HC - x_true) as S·Δd,
where S is the IFT sensitivity matrix and Δd = d_prod - d_true?

## Model

- **3 states** (x1, x2, x3), **5 parameters** (a12, a13, a21, a31, a01), **2 observables** (y1=0.5·x1, y2=x2)
- **x3 is latent** (not directly observed)
- Data: 1501 points, t ∈ [0, 20], noise 1e-4
- True: a12=0.52, a13=0.7, a21=0.367, a31=0.839, a01=0.79, x1=0.139, x2=0.303, x3=0.457

## Single-Point (t=0.76, max order 4)

- Nonlinearity mismatch: **0.0490** (linear regime — IFT reliable)
- Concentration: 66.6%
- Jacobian κ: 1.18e+04

### SP Data Variables

| # | Variable | d_true | d_prod | Δd |
|---|----------|--------|--------|----|
| 1 | y1(t) | 1.1119e-01 | 1.1119e-01 | -1.1322e-06 |
| 2 | y2(t) | 2.9198e-01 | 2.9198e-01 | +3.7383e-07 |
| 3 | Differential(t, 1)(y1(t)) | -2.6193e-03 | -2.6038e-03 | +1.5482e-05 |
| 4 | Differential(t, 1)(y2(t)) | -9.9055e-03 | -9.8579e-03 | +4.7658e-05 |
| 5 | Differential(t, 2)(y1(t)) | -5.6765e-02 | -5.6778e-02 | -1.3632e-05 |
| 6 | Differential(t, 2)(y2(t)) | 7.5911e-04 | 6.7435e-04 | -8.4758e-05 |
| 7 | Differential(t, 3)(y1(t)) | 1.8692e-01 | 1.8586e-01 | -1.0630e-03 |
| 8 | Differential(t, 4)(y1(t)) | -5.7001e-01 | -5.6421e-01 | +5.8025e-03 |

### SP IFT Validation

| Variable | Role | Δx_actual | Δx_predicted | |pred/actual| |
|----------|------|-----------|--------------|--------------|
| a12_0 | parameter | -8.0335e-02 | -8.0140e-02 | 0.998 |
| a21_0 | parameter | -7.0029e-02 | -6.9857e-02 | 0.998 |
| a01_0 | parameter | +5.8022e-02 | +5.3889e-02 | 0.929 |
| a13_0 | parameter | -4.9441e-02 | -4.9422e-02 | 1.000 |
| x1_5 | state_derivative | -4.9189e-02 | -4.9157e-02 | 0.999 |
| x3_0 | state_ic | +4.2390e-02 | +3.9354e-02 | 0.928 |
| x2_4 | state_derivative | -1.4556e-02 | -1.4703e-02 | 1.010 |
| x1_4 | state_derivative | +1.1605e-02 | +1.1605e-02 | 1.000 |
| x3_1 | state_derivative | -7.2064e-03 | -6.6960e-03 | 0.929 |
| a31_0 | parameter | -1.0113e-02 | -5.0991e-03 | 0.504 |
| x3_4 | state_derivative | -5.2089e-03 | -4.3212e-03 | 0.830 |
| x2_3 | state_derivative | +4.0039e-03 | +3.9955e-03 | 0.998 |
| x1_3 | state_derivative | -2.1261e-03 | -2.1261e-03 | 1.000 |
| x3_3 | state_derivative | +1.7103e-03 | +1.4545e-03 | 0.850 |
| x3_2 | state_derivative | +2.1981e-04 | +2.0878e-04 | 0.950 |
| x2_2 | state_derivative | -8.4758e-05 | -8.4758e-05 | 1.000 |
| x2_1 | state_derivative | +4.7658e-05 | +4.7658e-05 | 1.000 |
| x1_1 | state_derivative | +3.0964e-05 | +3.0964e-05 | 1.000 |
| x1_2 | state_derivative | -2.7263e-05 | -2.7263e-05 | 1.000 |
| x1_0 | state_ic | -2.2645e-06 | -2.2645e-06 | 1.000 |
| x2_0 | state_ic | +3.7383e-07 | +3.7383e-07 | 1.000 |

### SP Sensitivity Matrix S (21×8)

| | y1(t) | y2(t) | Differential(t, 1)(y1(t)) | Differential(t, 1)(y2(t)) | Differential(t, 2)(y1(t)) | Differential(t, 2)(y2(t)) | Differential(t, 3)(y1(t)) | Differential(t, 4)(y1(t)) |
|---|---|---|---|---|---|---|---|---|
| **x1_0** | 2.00e+00 | 5.55e-77 | -8.68e-75 | 2.56e-75 | -1.42e-74 | 6.31e-75 | -6.31e-75 | -1.38e-75 |
| **a31_0** | 4.06e+01 | -6.29e+00 | 5.96e+02 | -1.85e+02 | 6.62e+02 | -8.82e+02 | 3.43e+02 | 5.06e+01 |
| **x3_0** | -1.32e+01 | 1.23e+00 | -1.92e+02 | 2.15e+01 | -4.59e+02 | 7.91e+01 | -2.53e+02 | -3.91e+01 |
| **a13_0** | 2.91e+01 | -3.23e+00 | 3.89e+02 | -7.72e+01 | 7.40e+02 | -3.43e+02 | 4.04e+02 | 6.18e+01 |
| **x1_1** | 7.05e-77 | 3.68e-78 | 2.00e+00 | -1.62e-76 | -3.31e-76 | -5.44e-76 | -2.88e-77 | -8.01e-77 |
| **x2_0** | 0.00e+00 | 1.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 |
| **a21_0** | -1.08e+01 | 5.11e+00 | -3.18e+02 | 1.80e+02 | -4.74e-74 | 8.67e+02 | -2.04e-74 | -1.64e-75 |
| **a01_0** | -3.74e+01 | 3.25e+00 | -4.32e+02 | 7.03e+01 | -7.89e+02 | 3.23e+02 | -4.24e+02 | -6.50e+01 |
| **a12_0** | -8.55e+00 | 4.05e+00 | -3.63e+02 | 1.95e+02 | -7.97e-74 | 9.89e+02 | -3.13e-74 | -3.70e-75 |
| **x2_1** | 0.00e+00 | 0.00e+00 | 0.00e+00 | 1.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 |
| **x1_2** | -7.98e-78 | -0.00e+00 | 6.39e-77 | 4.79e-77 | 2.00e+00 | 1.92e-76 | 6.39e-77 | 4.79e-77 |
| **x3_1** | 3.74e+00 | -4.01e-01 | 5.27e+01 | -9.35e+00 | 9.74e+01 | -3.98e+01 | 5.24e+01 | 8.03e+00 |
| **x2_2** | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 1.00e+00 | 0.00e+00 | 0.00e+00 |
| **x1_3** | -5.13e-78 | -1.13e-78 | -1.90e-76 | -4.36e-78 | -9.67e-77 | 4.19e-76 | 2.00e+00 | 1.52e-78 |
| **x3_2** | -1.09e-01 | 9.44e-03 | -2.14e+00 | 2.05e-01 | -2.96e+00 | 2.72e-01 | -1.23e+00 | -1.89e-01 |
| **x2_3** | 6.15e-01 | -2.91e-01 | 1.82e+01 | -1.03e+01 | 3.67e-01 | -4.97e+01 | 1.16e-75 | 9.79e-77 |
| **x1_4** | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 0.00e+00 | 2.00e+00 |
| **x3_3** | -2.77e+00 | 3.99e-01 | -3.94e+01 | 1.13e+01 | -5.08e+01 | 5.34e+01 | -2.74e+01 | -4.10e+00 |
| **x1_5** | -9.11e-02 | -1.88e-02 | -7.09e-01 | -9.13e-01 | -1.36e+01 | -4.70e+00 | -2.65e+01 | -1.34e+01 |
| **x3_4** | 9.22e+00 | -1.36e+00 | 1.33e+02 | -3.91e+01 | 1.64e+02 | -1.85e+02 | 8.69e+01 | 1.28e+01 |
| **x2_4** | -2.19e+00 | 1.03e+00 | -6.52e+01 | 3.68e+01 | -6.37e-02 | 1.78e+02 | 3.67e-01 | -3.49e-76 |

## Multipoint 2-pt (t=[0.760, 1.333], max order 3)

- Nonlinearity mismatch: **0.1** (linear regime)
- Concentration: 69.3%

### Multipoint Selection Metadata

- Selection policy: `best_solved_combo`
- Comparison policy: `gate_invalid`
- Selection reason: selected the best solved multipoint combination by derivative error, residual, and distance to truth
- Candidate combos examined: 66
- Solved combos: 66
- Selected combo solved: true
- Selected combo HC solutions: 1
- Selected combo worst derivative error: 8.1273e-03
- Selected combo true residual: 8.0710e-05
- Selected combo closest distance: 5.7532e-02
- Template strip: 42 total eqs → 22 kept; 22 solve vars, 12 data vars
- Comparison valid: true

### MP Data Variables

| # | Variable | d_true | d_prod | Δd |
|---|----------|--------|--------|----|
| 1 | y1_0 | 1.1119e-01 | 1.1119e-01 | -1.1322e-06 |
| 2 | y2_0 | 2.9198e-01 | 2.9198e-01 | +3.7383e-07 |
| 3 | y1_1 | -2.6193e-03 | -2.6038e-03 | +1.5482e-05 |
| 4 | y2_1 | -9.9055e-03 | -9.8579e-03 | +4.7658e-05 |
| 5 | y1_2 | -5.6765e-02 | -5.6778e-02 | -1.3632e-05 |
| 6 | y1_0_pt2 | 1.0435e-01 | 1.0435e-01 | -1.2525e-06 |
| 7 | y2_0_pt2 | 2.8601e-01 | 2.8601e-01 | +2.5948e-06 |
| 8 | y1_1_pt2 | -1.6648e-02 | -1.6649e-02 | -1.4454e-06 |
| 9 | y2_1_pt2 | -1.1378e-02 | -1.1402e-02 | -2.3549e-05 |
| 10 | y1_2_pt2 | -6.2839e-03 | -6.2329e-03 | +5.1071e-05 |
| 11 | y2_2_pt2 | -4.1336e-03 | -4.1162e-03 | +1.7385e-05 |
| 12 | y1_3_pt2 | 3.1963e-02 | 3.1945e-02 | -1.8451e-05 |

### MP IFT Validation

| Variable | Role | Δx_actual | Δx_predicted | |pred/actual| | Note |
|----------|------|-----------|--------------|--------------|------|
| a01_0 | parameter | -3.1318e-02 | -3.3783e-02 | 1.1 |  |
| a13_0 | parameter | +2.9776e-02 | +3.0858e-02 | 1.0 |  |
| x3_0 | state_ic | -2.0759e-02 | -2.2335e-02 | 1.1 |  |
| x3_0_pt2 | state_derivative | -1.8649e-02 | -2.0056e-02 | 1.1 |  |
| a12_0 | parameter | +1.6935e-02 | +1.6939e-02 | 1.0 |  |
| a21_0 | parameter | +1.5286e-02 | +1.5290e-02 | 1.0 |  |
| a31_0 | parameter | +1.0734e-02 | +1.3239e-02 | 1.2 |  |
| x3_1 | state_derivative | +3.8264e-03 | +4.1309e-03 | 1.1 |  |
| x3_1_pt2 | state_derivative | +3.6473e-03 | +3.9331e-03 | 1.1 |  |
| x3_2_pt2 | state_derivative | -4.8760e-04 | -5.3303e-04 | 1.1 |  |
| x1_2_pt2 | state_derivative | +1.0214e-04 | +1.0214e-04 | 1.0 |  |
| x2_1 | state_derivative | +4.7658e-05 | +4.7658e-05 | 1.0 |  |
| x1_3_pt2 | state_derivative | -3.6901e-05 | -3.6901e-05 | 1.0 |  |
| x1_1 | state_derivative | +3.0964e-05 | +3.0964e-05 | 1.0 |  |
| x1_2 | state_derivative | -2.7263e-05 | -2.7263e-05 | 1.0 |  |
| x2_1_pt2 | state_derivative | -2.3549e-05 | -2.3549e-05 | 1.0 |  |
| x2_2_pt2 | state_derivative | +1.7385e-05 | +1.7385e-05 | 1.0 |  |
| x1_1_pt2 | state_derivative | -2.8909e-06 | -2.8909e-06 | 1.0 |  |
| x2_0_pt2 | state_derivative | +2.5948e-06 | +2.5948e-06 | 1.0 |  |
| x1_0_pt2 | state_derivative | -2.5051e-06 | -2.5051e-06 | 1.0 |  |
| x1_0 | state_ic | -2.2645e-06 | -2.2645e-06 | 1.0 |  |
| x2_0 | state_ic | +3.7383e-07 | +3.7383e-07 | 1.0 |  |

## Diagnosis

- **SP nonlinearity mismatch = 0.0490**
- **MP nonlinearity mismatch = 0**
- MP variables within 0.5x-2x prediction ratio: 22 / 22
- MP variables with >100x mismatch: 0 / 22
- Multipoint comparison validity: true
- Comparable unknowns: a12_0, a21_0, a01_0, a13_0, x3_0, x3_1, a31_0, x1_3, x3_2, x2_2, x2_1, x1_1, x1_2, x1_0, x2_0

### Interpretation

This audit records the measured SP/MP first-order mismatch and template-strip facts.
Any model-specific causal explanation should be drawn from the stored derivative tables,
selection metadata, and strip summary above, not from hardcoded narrative claims.
