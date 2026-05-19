#!/usr/bin/env python3
"""Compare rank_strategy schemes across all wallaby polish cells.

Metric: rank-1 post_polish_error. Lower = tighter polish.

Re-sorts each cell's result.csv under {err_only, sat_neg1_err (S2), sat_err}
and reports the % of cells whose rank-1 post_polish ≤ threshold.

Run: python3 sort_scheme_compare.py
"""
import csv, math, statistics
from pathlib import Path

W = Path('/home/orebas/rsync-readonly-PEB/benchmark_wallaby_2026-05-17/filetree/odepe_v2_polish_run')

# Benchmark cells all use uniform [1e-5, 10] bounds. See script.jl in any cell.
LB, UB = 1e-5, 10.0
LOG_LB, LOG_UB = math.log(LB), math.log(UB)
EPS_SAT = 0.02
THRESH = EPS_SAT * (LOG_UB - LOG_LB)

def sat_count(row, params):
    n = 0
    for p in params:
        v = float(row[p]) if row[p] else float('inf')
        if not (v > 0 and math.isfinite(v)):
            n += 1
            continue
        lv = math.log(v)
        if lv < LOG_LB + THRESH or lv > LOG_UB - THRESH:
            n += 1
    return n

def key_s2(r, p):
    sat = sat_count(r, p)
    neg1 = 1 if r['polish_source_hc_idx'] in ('-1.0', '-1') else 0
    e = float(r['err']) if r['err'] else float('inf')
    return (sat, neg1, e)

def key_err(r, p):
    return float(r['err']) if r['err'] else float('inf')

def key_sat_err(r, p):
    sat = sat_count(r, p)
    e = float(r['err']) if r['err'] else float('inf')
    return (sat, e)

def main():
    cells = sorted(d.name for d in W.iterdir() if d.is_dir())
    results = {'err_only': [], 'sat_err': [], 'sat_neg1_err': []}
    skipped = 0
    for cell in cells:
        res = W / cell / 'result.csv'
        if not res.exists():
            skipped += 1
            continue
        rows = list(csv.DictReader(open(res)))
        if not rows:
            skipped += 1
            continue
        params = [c for c in rows[0]
                  if c not in ('err', 'post_polish_error', 'branch_size', 'polish_source_hc_idx')
                  and not c.startswith('_trfn_')]
        for key, fn in [('sat_neg1_err', key_s2), ('err_only', key_err), ('sat_err', key_sat_err)]:
            rank1 = sorted(rows, key=lambda r: fn(r, params))[0]
            results[key].append(float(rank1['err']))

    n = len(results['err_only'])
    print(f"Cells: {n} (skipped {skipped})")
    def pct_le(vals, t): return 100 * sum(1 for v in vals if v <= t) / n

    print(f"\n{'scheme':<18s}  {'≤1e-9':>8s}  {'≤1e-4':>8s}  {'≤1e-3':>8s}  {'≤0.1':>8s}  {'median':>10s}")
    print('-' * 75)
    for key in ('err_only', 'sat_err', 'sat_neg1_err'):
        v = results[key]
        print(f"{key:<18s}  {pct_le(v, 1e-9):>7.1f}%  {pct_le(v, 1e-4):>7.1f}%  {pct_le(v, 1e-3):>7.1f}%  {pct_le(v, 0.1):>7.1f}%  {statistics.median(v):>10.3g}")

    # Pairwise: how often does S2 give a strictly worse rank-1 than err_only?
    print(f"\nPairwise vs err_only (S2 rank-1 post_polish > err_only rank-1):")
    for key in ('sat_err', 'sat_neg1_err'):
        worse = sum(1 for a, b in zip(results['err_only'], results[key]) if b > a)
        much_worse = sum(1 for a, b in zip(results['err_only'], results[key]) if b > 2 * a)
        print(f"  {key:<18s}: worse in {worse}/{n}, ≥2× worse in {much_worse}/{n}")

if __name__ == '__main__':
    main()
