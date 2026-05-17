#!/usr/bin/env python3
"""Probe 4: Re-rank by (saturation_count, err) on 300-cell sample.

Goal: quantify rank-1 oracle improvement when we add saturation_count
as a primary sort key.

Reference: scheme A (current err-only) gives 71.6%/82.2% at ≤1%/≤10%.
Scheme C (is_neg1, err) gives 77.5%/87.6%.

Bounds for all cells in the 2026-05-14 benchmark are uniform:
  lb = 1e-5, ub = 10 for every ic and param.

Saturation: a parameter is "saturated" if it's within ε_sat of either bound,
measured in the log-coordinate (since the bounds span ~6 decades).
"""
import json, csv, random, math
from pathlib import Path

ROOT14 = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/huge_json.json'))['instances']}

LB, UB = 1e-5, 10.0
LOG_LB = math.log(LB)
LOG_UB = math.log(UB)
LOG_RANGE = LOG_UB - LOG_LB
EPS_SAT = 0.02  # within 2% of bound range (in log coords)

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)

def fl(s):
    try: return float(s)
    except: return float('inf')

def is_neg1(r): return r['polish_source_hc_idx'] in ('-1.0', '-1')

def saturation_count(row, params_and_ics):
    """Count how many params/ICs are within EPS_SAT of either bound (in log coords)."""
    n = 0
    for c in params_and_ics:
        v = fl(row[c])
        if not (v > 0 and math.isfinite(v)):  # log undefined or negative — treat as out-of-bounds (= saturated)
            n += 1
            continue
        log_v = math.log(v)
        if log_v < LOG_LB + EPS_SAT * LOG_RANGE:
            n += 1
        elif log_v > LOG_UB - EPS_SAT * LOG_RANGE:
            n += 1
    return n

def all_data(cell, t):
    meta = json.load(open(ROOT14 / cell / 'odepe_metadata.json'))
    unident = meta.get('best', {}).get('all_unidentifiable', [])
    truth_map = {**{k: v for k, v in t['parameter_values'].items()},
                 **{f'{k}(t)': v for k, v in t['state_values'].items()}}
    rows = list(csv.DictReader(open(ROOT14 / cell / 'result.csv')))
    if not rows:
        return None
    cmp_cols = [c for c in rows[0]
                if c not in ('err', 'post_polish_error', 'branch_size', 'polish_source_hc_idx')
                and not c.startswith('_trfn_')
                and c in truth_map
                and c not in unident]
    if not cmp_cols:
        return None
    # All numeric cols (params + ICs) for saturation counting
    sat_cols = [c for c in rows[0]
                if c not in ('err', 'post_polish_error', 'branch_size', 'polish_source_hc_idx')
                and not c.startswith('_trfn_')]
    def oracle(r):
        return max(rel_err(fl(r[c]), truth_map[c]) for c in cmp_cols)
    return rows, [oracle(r) for r in rows], sat_cols

def eval_scheme(name, key_fn, cells_data):
    rank1_oracles = []
    for cell, rows, oracles, sat_cols in cells_data:
        order = sorted(range(len(rows)), key=key_fn(rows, sat_cols))
        rank1_oracles.append(oracles[order[0]])
    s = sorted(rank1_oracles)
    return {
        'name': name,
        'median': s[len(s) // 2],
        'mean': sum(rank1_oracles) / len(rank1_oracles),
        'p90': s[int(len(s) * 0.9)],
        'p99': s[int(len(s) * 0.99)],
        'pct_le_1pct': 100 * sum(1 for v in rank1_oracles if v <= 0.01) / len(rank1_oracles),
        'pct_le_10pct': 100 * sum(1 for v in rank1_oracles if v <= 0.10) / len(rank1_oracles),
    }

def main():
    random.seed(0)
    cells = sorted([d.name for d in ROOT14.iterdir() if d.is_dir() and (d / 'result.csv').exists()])
    sample = random.sample(cells, 300)

    cells_data = []
    for cell in sample:
        t = HUGE.get(cell)
        if not t:
            continue
        d = all_data(cell, t)
        if d is None:
            continue
        rows, oracles, sat_cols = d
        if min(oracles) > 0.5:
            continue
        cells_data.append((cell, rows, oracles, sat_cols))

    print(f"# Probe 4: re-rank by (saturation_count, err)")
    print(f"# Sample: 300 cells; {len(cells_data)} have an oracle-close row.")
    print(f"# Bounds (uniform): lb={LB}, ub={UB}")
    print(f"# Saturation threshold: within {EPS_SAT*100:.0f}% of bound (in log coords) ⇒ saturated")
    print()

    # Schemes
    def A_key(rows, sat_cols):
        return lambda i: fl(rows[i]['err'])

    def C_key(rows, sat_cols):
        return lambda i: (is_neg1(rows[i]), fl(rows[i]['err']))

    def S1_key(rows, sat_cols):
        return lambda i: (saturation_count(rows[i], sat_cols), fl(rows[i]['err']))

    def S2_key(rows, sat_cols):
        return lambda i: (saturation_count(rows[i], sat_cols), is_neg1(rows[i]), fl(rows[i]['err']))

    def S3_key(rows, sat_cols):
        return lambda i: (is_neg1(rows[i]), saturation_count(rows[i], sat_cols), fl(rows[i]['err']))

    def S4_key(rows, sat_cols):
        """Combined: minimize (saturation_count + 0.5*is_neg1) then err."""
        return lambda i: (saturation_count(rows[i], sat_cols) + (0.5 if is_neg1(rows[i]) else 0), fl(rows[i]['err']))

    schemes = [
        ('A: err only (current)', A_key),
        ('C: (is_neg1, err)', C_key),
        ('S1: (saturation, err)', S1_key),
        ('S2: (saturation, is_neg1, err)', S2_key),
        ('S3: (is_neg1, saturation, err)', S3_key),
        ('S4: (sat + 0.5·is_neg1, err)', S4_key),
    ]

    # Oracle-best lower bound
    oracle_best_per_cell = [min(oracles) for _, _, oracles, _ in cells_data]

    print(f"{'scheme':<36s}  {'median':>10s}  {'mean':>10s}  {'p90':>10s}  {'≤1%':>7s}  {'≤10%':>7s}")
    print('-' * 100)
    for name, key in schemes:
        r = eval_scheme(name, key, cells_data)
        print(f"{name:<36s}  {r['median']:>10.3g}  {r['mean']:>10.3g}  {r['p90']:>10.3g}  {r['pct_le_1pct']:>6.1f}%  {r['pct_le_10pct']:>6.1f}%")

    s = sorted(oracle_best_per_cell)
    lower = {
        'median': s[len(s) // 2],
        'mean': sum(oracle_best_per_cell) / len(oracle_best_per_cell),
        'p90': s[int(len(s) * 0.9)],
        'pct_le_1pct': 100 * sum(1 for v in oracle_best_per_cell if v <= 0.01) / len(oracle_best_per_cell),
        'pct_le_10pct': 100 * sum(1 for v in oracle_best_per_cell if v <= 0.10) / len(oracle_best_per_cell),
    }
    print(f"{'Z: oracle-best (lower bound)':<36s}  {lower['median']:>10.3g}  {lower['mean']:>10.3g}  {lower['p90']:>10.3g}  {lower['pct_le_1pct']:>6.1f}%  {lower['pct_le_10pct']:>6.1f}%")

    # Distribution of saturation_count per cell across all rows
    print()
    print(f"# Saturation_count distribution across all rows (sample of 30 cells):")
    print(f"  {'cell':<35s} {'n_rows':>7s} {'sat_median':>10s} {'sat_max':>8s} {'sat=0_rows':>12s}")
    random.seed(7)
    for cell, rows, oracles, sat_cols in random.sample(cells_data, min(30, len(cells_data))):
        sats = [saturation_count(r, sat_cols) for r in rows]
        n_sat0 = sum(1 for s in sats if s == 0)
        sorted_s = sorted(sats)
        print(f"  {cell:<35s} {len(rows):>7d} {sorted_s[len(sorted_s)//2]:>10d} {max(sats):>8d} {n_sat0:>12d}")

if __name__ == '__main__':
    main()
