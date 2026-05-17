#!/usr/bin/env python3
"""Probe 1: cond(J_local) on slow_fast's two basins.

For each row in slow_fast_6_1em4/result.csv:
  - Forward-model with that row's params.
  - Compute J = ∂Y/∂θ at that row via finite differences.
  - SVD; record σ_max, σ_min, cond(J), dominant null-space direction.
Group by basin (xA > 0 = truth basin, xA < 0 = mirror basin).
Compare cond(J) distributions.
"""
import json, csv, math
from pathlib import Path
import numpy as np
from scipy.integrate import solve_ivp

ROOT = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run/slow_fast_6_1em4')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/huge_json.json'))['instances']}
TRUTH = HUGE['slow_fast_6_1em4']

THETA_NAMES = ['k1', 'k2', 'xA(t)', 'xB(t)', 'xC(t)', 'eA(t)', 'eC(t)', 'eB(t)']
T_EVAL = np.linspace(0, 10, 750)

def slow_fast_rhs(t, y, k1, k2):
    xA, xB, xC, eA, eC, eB = y
    return [
        -0.5 * k1 * xA,
        (0.166 * k1 * xA - 0.666 * k2 * xB) / 0.666,
        0.666 * k2 * xB,
        0.0, 0.0, 0.0,
    ]

def observe(y_t):
    xA, xB, xC, eA, eC, eB = y_t
    y1 = xC
    y2 = 0.4422 * xA * eA + 0.999 * eB * xB + 1.666 * xC * eC
    y3 = 1.332 * eA
    y4 = 1.666 * eC
    return np.array([y1, y2, y3, y4])

def forward(theta_vec):
    """theta = [k1, k2, xA0, xB0, xC0, eA0, eC0, eB0]"""
    k1, k2 = theta_vec[0], theta_vec[1]
    y0 = list(theta_vec[2:])
    try:
        sol = solve_ivp(slow_fast_rhs, [0, 10], y0, args=(k1, k2), t_eval=T_EVAL,
                        rtol=1e-10, atol=1e-12, method='LSODA')
        if not sol.success:
            return None
        return np.array([observe(sol.y[:, i]) for i in range(len(T_EVAL))]).reshape(-1)
    except Exception:
        return None

def compute_J(theta_vec, rel_h=1e-6):
    """Finite-difference Jacobian of forward at theta_vec."""
    Y0 = forward(theta_vec)
    if Y0 is None:
        return None
    n = len(theta_vec)
    m = len(Y0)
    J = np.zeros((m, n))
    for j in range(n):
        h = max(abs(theta_vec[j]) * rel_h, 1e-10)
        tp = theta_vec.copy(); tp[j] += h
        tm = theta_vec.copy(); tm[j] -= h
        Yp = forward(tp)
        Ym = forward(tm)
        if Yp is None or Ym is None:
            return None
        J[:, j] = (Yp - Ym) / (2 * h)
    return J

def fl(s):
    try: return float(s)
    except: return float('inf')

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)

def main():
    rows = list(csv.DictReader(open(ROOT / 'result.csv')))
    truth_map = {**TRUTH['parameter_values'],
                 **{f'{k}(t)': v for k, v in TRUTH['state_values'].items()}}

    print(f"# Probe 1: cond(J) on slow_fast_6_1em4 basins")
    print(f"# {len(rows)} candidates; computing local Jacobian for each.")
    print()

    results = []
    failed = 0
    for i, r in enumerate(rows):
        try:
            theta = np.array([fl(r[name]) for name in THETA_NAMES])
        except Exception:
            failed += 1
            continue
        if not all(np.isfinite(theta)):
            failed += 1
            continue
        J = compute_J(theta)
        if J is None:
            failed += 1
            results.append(dict(idx=i, basin=None, theta=theta,
                                sigma=None, cond=None, vmin=None,
                                oracle=None, err=fl(r['err'])))
            continue
        try:
            U, S, Vt = np.linalg.svd(J, full_matrices=False)
        except Exception:
            failed += 1
            continue
        basin = 'truth' if theta[2] > 0 else 'mirror'
        oracle = max(
            rel_err(theta[i], truth_map[THETA_NAMES[i]])
            for i in range(len(THETA_NAMES))
            if THETA_NAMES[i] in truth_map and THETA_NAMES[i] not in {'xA(t)'}  # xA flips sign
        ) if all(n in truth_map for n in THETA_NAMES if n != 'xA(t)') else None
        results.append(dict(idx=i, basin=basin, theta=theta,
                            sigma=S.copy(), cond=float(S[0] / S[-1]) if S[-1] > 0 else float('inf'),
                            vmin=Vt[-1].copy(), oracle=oracle, err=fl(r['err'])))

    print(f"# Processed {len(results)} rows; {failed} failed (singular or non-finite).")
    print()

    truth_rows = [r for r in results if r.get('basin') == 'truth' and r.get('cond') is not None]
    mirror_rows = [r for r in results if r.get('basin') == 'mirror' and r.get('cond') is not None]

    def stats(label, rs):
        conds = [r['cond'] for r in rs]
        smins = [r['sigma'][-1] for r in rs]
        smaxs = [r['sigma'][0] for r in rs]
        if not conds:
            print(f"  {label}: empty")
            return
        print(f"  {label} ({len(rs)} rows):")
        print(f"    cond(J): median={np.median(conds):.4g}, mean={np.mean(conds):.4g}, min={min(conds):.4g}, max={max(conds):.4g}")
        print(f"    σ_max:   median={np.median(smaxs):.4g}, mean={np.mean(smaxs):.4g}")
        print(f"    σ_min:   median={np.median(smins):.4g}, mean={np.mean(smins):.4g}")

    print(f"# Basin statistics:")
    stats("truth basin (xA > 0)", truth_rows)
    stats("mirror basin (xA < 0)", mirror_rows)
    print()

    # Per-axis composition of v_min (the null direction) by basin
    print(f"# Dominant null-direction composition (|v_min|), per basin:")
    print(f"  {'param':<8s} {'truth median':>14s} {'mirror median':>14s}")
    for j, name in enumerate(THETA_NAMES):
        tv = np.median([abs(r['vmin'][j]) for r in truth_rows])
        mv = np.median([abs(r['vmin'][j]) for r in mirror_rows])
        print(f"  {name:<8s} {tv:>14.4f} {mv:>14.4f}")
    print()

    # Write detailed CSV
    out_csv = Path(__file__).parent / 'probe1_results.csv'
    with open(out_csv, 'w') as f:
        f.write('idx,basin,cond_J,sigma_max,sigma_min,oracle,err,' +
                ','.join(f'theta_{n}' for n in THETA_NAMES) +
                ',' +
                ','.join(f'vmin_{n}' for n in THETA_NAMES) + '\n')
        for r in results:
            if r['cond'] is None:
                continue
            f.write(f"{r['idx']},{r['basin']},{r['cond']},{r['sigma'][0]},{r['sigma'][-1]},"
                    f"{r['oracle'] if r['oracle'] is not None else ''},{r['err']},")
            f.write(','.join(f"{r['theta'][j]}" for j in range(len(THETA_NAMES))))
            f.write(',')
            f.write(','.join(f"{r['vmin'][j]}" for j in range(len(THETA_NAMES))))
            f.write('\n')
    print(f"# Wrote {out_csv}")

    # Quick separation check: can we use cond(J) alone to assign basin?
    if truth_rows and mirror_rows:
        t_conds = [r['cond'] for r in truth_rows]
        m_conds = [r['cond'] for r in mirror_rows]
        print(f"\n# Separation test: is there a cond(J) threshold that classifies basin correctly?")
        all_rows = [(r['cond'], r['basin']) for r in results if r['cond'] is not None]
        all_rows.sort()
        # Find best threshold by accuracy
        best = (0, None)
        for i in range(len(all_rows)):
            thr = all_rows[i][0]
            below = sum(1 for c, b in all_rows if c < thr and b == 'truth') + \
                    sum(1 for c, b in all_rows if c >= thr and b == 'mirror')
            above = sum(1 for c, b in all_rows if c < thr and b == 'mirror') + \
                    sum(1 for c, b in all_rows if c >= thr and b == 'truth')
            acc = max(below, above) / len(all_rows)
            if acc > best[0]:
                best = (acc, thr)
        print(f"  best threshold: {best[1]:.4g}; accuracy = {best[0]*100:.1f}%")
        print(f"  truth-basin cond range: [{min(t_conds):.4g}, {max(t_conds):.4g}]")
        print(f"  mirror-basin cond range: [{min(m_conds):.4g}, {max(m_conds):.4g}]")
        if min(t_conds) > max(m_conds) or min(m_conds) > max(t_conds):
            print(f"  PERFECTLY SEPARABLE by cond(J)")
        else:
            overlap_low = max(min(t_conds), min(m_conds))
            overlap_high = min(max(t_conds), max(m_conds))
            print(f"  overlap range: [{overlap_low:.4g}, {overlap_high:.4g}]")

if __name__ == '__main__':
    main()
