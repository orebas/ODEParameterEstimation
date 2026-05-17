#!/usr/bin/env python3
"""Probe 4b — compare lognorm reranking against probe4's saturation schemes.

Same data, same cells, same metric as `probe4_rerank_saturation.py`.

Adds two new schemes to the comparison:
  lognorm_err       = (Σ_i (log10 p_i)², err)
  lognorm_neg1_err  = (Σ_i (log10 p_i)², is_neg1, err)

Motivation: `saturation_count` requires user-provided opt_lb/opt_ub. The
benchmark cells all set bounds, but library callers without bounds get
silent degradation. `lognorm_score = Σ (log p)²` is bound-free, symmetric
to upper- and lower-bound saturation, and the post-hoc analog of the
existing `polish_regularization_lambda` (L2 toward x=1 in log-coords).
"""
import json, csv, random, math
from pathlib import Path

ROOT14 = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/huge_json.json'))['instances']}

LB, UB = 1e-5, 10.0
LOG_LB = math.log(LB)
LOG_UB = math.log(UB)
LOG_RANGE = LOG_UB - LOG_LB
EPS_SAT = 0.02

OUT_DIR = Path(__file__).parent
RESULTS_MD = OUT_DIR / 'probe4b_results.md'
PER_CELL_CSV = OUT_DIR / 'probe4b_per_cell.csv'

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)

def fl(s):
    try: return float(s)
    except: return float('inf')

def is_neg1(r): return r['polish_source_hc_idx'] in ('-1.0', '-1')

def saturation_count(row, params_and_ics):
    n = 0
    for c in params_and_ics:
        v = fl(row[c])
        if not (v > 0 and math.isfinite(v)):
            n += 1
            continue
        log_v = math.log(v)
        if log_v < LOG_LB + EPS_SAT * LOG_RANGE:
            n += 1
        elif log_v > LOG_UB - EPS_SAT * LOG_RANGE:
            n += 1
    return n

def lognorm_score(row, params_and_ics):
    """Σ_i (log10 p_i)² over positive params/ICs. Lower = closer to p=1 in log-space.

    Treats non-positive or non-finite values as max-penalty (= LOG_RANGE² in log10
    units, ~36 for our 1e-5..10 box). Without this, a 0 or negative value would
    silently skip and the row would score artificially low. The benchmark cells
    all have positive truths and bounds; this guards against numerical drift.
    """
    total = 0.0
    log10_lb = math.log10(LB)
    max_log10_dist = max(abs(log10_lb), abs(math.log10(UB)))
    for c in params_and_ics:
        v = fl(row[c])
        if v > 0 and math.isfinite(v):
            total += math.log10(v) ** 2
        else:
            total += max_log10_dist ** 2
    return total

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
    sat_cols = [c for c in rows[0]
                if c not in ('err', 'post_polish_error', 'branch_size', 'polish_source_hc_idx')
                and not c.startswith('_trfn_')]
    def oracle(r):
        return max(rel_err(fl(r[c]), truth_map[c]) for c in cmp_cols)
    return rows, [oracle(r) for r in rows], sat_cols

def eval_scheme(name, key_fn, cells_data):
    rank1_oracles = []
    rank1_indices = []
    for cell, rows, oracles, sat_cols in cells_data:
        order = sorted(range(len(rows)), key=key_fn(rows, sat_cols))
        rank1_oracles.append(oracles[order[0]])
        rank1_indices.append(order[0])
    s = sorted(rank1_oracles)
    n = len(s)
    return {
        'name': name,
        'median': s[n // 2],
        'mean': sum(rank1_oracles) / n,
        'p90': s[int(n * 0.9)],
        'p99': s[int(n * 0.99)],
        'pct_le_1pct': 100 * sum(1 for v in rank1_oracles if v <= 0.01) / n,
        'pct_le_10pct': 100 * sum(1 for v in rank1_oracles if v <= 0.10) / n,
        'rank1_oracles': rank1_oracles,
        'rank1_indices': rank1_indices,
    }

def main():
    random.seed(0)
    cells = sorted([d.name for d in ROOT14.iterdir() if d.is_dir() and (d / 'result.csv').exists()])
    sample = random.sample(cells, min(300, len(cells)))

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

    print(f"# Probe 4b: lognorm reranking vs S2 saturation schemes")
    print(f"# Sample: {len(sample)} cells; {len(cells_data)} have an oracle-close row.")
    print(f"# Bounds (uniform): lb={LB}, ub={UB}")
    print()

    def err_only_key(rows, sat_cols):
        return lambda i: fl(rows[i]['err'])

    def C_key(rows, sat_cols):
        return lambda i: (is_neg1(rows[i]), fl(rows[i]['err']))

    def S2_key(rows, sat_cols):
        return lambda i: (saturation_count(rows[i], sat_cols), is_neg1(rows[i]), fl(rows[i]['err']))

    def LN_key(rows, sat_cols):
        return lambda i: (lognorm_score(rows[i], sat_cols), fl(rows[i]['err']))

    def LN_neg1_key(rows, sat_cols):
        return lambda i: (lognorm_score(rows[i], sat_cols), is_neg1(rows[i]), fl(rows[i]['err']))

    schemes = [
        ('err_only', err_only_key),
        ('C: (is_neg1, err)', C_key),
        ('S2: (sat, is_neg1, err)', S2_key),
        ('lognorm_err: (Σlog², err)', LN_key),
        ('lognorm_neg1_err: (Σlog², is_neg1, err)', LN_neg1_key),
    ]

    oracle_best_per_cell = [min(oracles) for _, _, oracles, _ in cells_data]
    s = sorted(oracle_best_per_cell)
    n = len(s)
    lower = {
        'name': 'Z: oracle-best (lower bound)',
        'median': s[n // 2],
        'mean': sum(oracle_best_per_cell) / n,
        'p90': s[int(n * 0.9)],
        'p99': s[int(n * 0.99)],
        'pct_le_1pct': 100 * sum(1 for v in oracle_best_per_cell if v <= 0.01) / n,
        'pct_le_10pct': 100 * sum(1 for v in oracle_best_per_cell if v <= 0.10) / n,
    }

    results = []
    for name, key in schemes:
        r = eval_scheme(name, key, cells_data)
        results.append(r)

    # Print to stdout
    print(f"{'scheme':<42s}  {'median':>10s}  {'mean':>10s}  {'p90':>10s}  {'≤1%':>7s}  {'≤10%':>7s}")
    print('-' * 100)
    for r in results:
        print(f"{r['name']:<42s}  {r['median']:>10.3g}  {r['mean']:>10.3g}  {r['p90']:>10.3g}  {r['pct_le_1pct']:>6.1f}%  {r['pct_le_10pct']:>6.1f}%")
    print(f"{lower['name']:<42s}  {lower['median']:>10.3g}  {lower['mean']:>10.3g}  {lower['p90']:>10.3g}  {lower['pct_le_1pct']:>6.1f}%  {lower['pct_le_10pct']:>6.1f}%")

    # Per-cell CSV: rank-1 oracle per cell per scheme
    with open(PER_CELL_CSV, 'w', newline='') as fp:
        wr = csv.writer(fp)
        wr.writerow(['cell'] + [r['name'] for r in results] + ['oracle_best'])
        for i, (cell, rows, oracles, sat_cols) in enumerate(cells_data):
            wr.writerow([cell] + [f'{r["rank1_oracles"][i]:.6g}' for r in results] + [f'{min(oracles):.6g}'])
    print(f"\nPer-cell CSV: {PER_CELL_CSV}")

    # Pairwise win/lose vs S2 baseline
    print()
    print("Pairwise vs S2 baseline (positive = scheme is closer to truth):")
    s2 = next(r for r in results if r['name'] == 'S2: (sat, is_neg1, err)')
    for r in results:
        if r['name'] == s2['name']:
            continue
        wins = sum(1 for s2v, rv in zip(s2['rank1_oracles'], r['rank1_oracles']) if rv < s2v)
        losses = sum(1 for s2v, rv in zip(s2['rank1_oracles'], r['rank1_oracles']) if rv > s2v)
        ties = len(s2['rank1_oracles']) - wins - losses
        print(f"  vs S2: {r['name']:<42s}  wins={wins:>4d}  losses={losses:>4d}  ties={ties:>4d}")

    # Markdown report
    with open(RESULTS_MD, 'w') as fp:
        fp.write("# Probe 4b — lognorm reranking vs S2 saturation schemes\n\n")
        fp.write(f"Data: 2026-05-14 numbat benchmark, {len(cells_data)} cells with an oracle-close row.\n")
        fp.write(f"Cell pool: 300 randomly sampled (seed=0) from `{ROOT14}`.\n")
        fp.write(f"Bounds (uniform across the benchmark): `lb={LB}`, `ub={UB}`.\n\n")
        fp.write("## Rank-1 oracle stats per scheme\n\n")
        fp.write("| Scheme | median | mean | p90 | %≤1% | %≤10% |\n")
        fp.write("|---|---|---|---|---|---|\n")
        for r in results:
            fp.write(f"| {r['name']} | {r['median']:.3g} | {r['mean']:.3g} | {r['p90']:.3g} | {r['pct_le_1pct']:.1f}% | {r['pct_le_10pct']:.1f}% |\n")
        fp.write(f"| **{lower['name']}** | {lower['median']:.3g} | {lower['mean']:.3g} | {lower['p90']:.3g} | {lower['pct_le_1pct']:.1f}% | {lower['pct_le_10pct']:.1f}% |\n")
        fp.write("\n## Pairwise vs S2 baseline (wins = lower rank-1 oracle than S2)\n\n")
        fp.write("| Scheme | wins | losses | ties |\n")
        fp.write("|---|---|---|---|\n")
        for r in results:
            if r['name'] == s2['name']:
                continue
            wins = sum(1 for s2v, rv in zip(s2['rank1_oracles'], r['rank1_oracles']) if rv < s2v)
            losses = sum(1 for s2v, rv in zip(s2['rank1_oracles'], r['rank1_oracles']) if rv > s2v)
            ties = len(s2['rank1_oracles']) - wins - losses
            fp.write(f"| {r['name']} | {wins} | {losses} | {ties} |\n")
        fp.write(f"\nPer-cell CSV: `probe4b_per_cell.csv`\n")

    print(f"\nMarkdown report: {RESULTS_MD}")

if __name__ == '__main__':
    main()
