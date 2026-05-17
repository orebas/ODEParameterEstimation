#!/usr/bin/env python3
"""Probe 4c — full-benchmark S2 evaluation + required-K analysis.

Walks ALL 1150 cells of the 2026-05-14 numbat benchmark (probe4 only used
a 300-sample).

For each cell, computes:
  - rank-1 oracle under err_only and S2 (sat_neg1_err) schemes
  - required_K@1%  = smallest rank where oracle ≤ 1% under given scheme
  - required_K@10% = smallest rank where oracle ≤ 10%

Then aggregates:
  - Overall stats: %≤1%, %≤10%, p90 (same metrics as probe4)
  - Per-system breakdown
  - Per-noise breakdown
  - System × noise grid (heatmap-style table)
  - Required_K distribution

Output:
  - stdout: aggregate tables
  - probe4c_per_cell.csv: one row per cell with all metrics
  - probe4c_results.md: synthesis
"""
import json, csv, math, re
from collections import defaultdict
from pathlib import Path

ROOT = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/huge_json.json'))['instances']}

LB, UB = 1e-5, 10.0
LOG_LB = math.log(LB)
LOG_UB = math.log(UB)
LOG_RANGE = LOG_UB - LOG_LB
EPS_SAT = 0.02

OUT_DIR = Path(__file__).parent
PER_CELL_CSV = OUT_DIR / 'probe4c_per_cell.csv'
RESULTS_MD = OUT_DIR / 'probe4c_results.md'

NOISE_TOKENS = {'0', '1em2', '1em4', '1em6', '1em8'}

def parse_cell_name(name):
    """Split <system>_<instance>_<noise>; system may contain underscores."""
    parts = name.split('_')
    if len(parts) < 3:
        return None, None, None
    noise = parts[-1]
    if noise not in NOISE_TOKENS:
        return None, None, None
    instance = parts[-2]
    system = '_'.join(parts[:-2])
    return system, instance, noise

def fl(s):
    try: return float(s)
    except: return float('inf')

def is_neg1(r): return r['polish_source_hc_idx'] in ('-1.0', '-1')

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)

def saturation_count(row, sat_cols):
    n = 0
    for c in sat_cols:
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

def cell_data(cell):
    cell_dir = ROOT / cell
    meta_path = cell_dir / 'odepe_metadata.json'
    res_path = cell_dir / 'result.csv'
    if not (meta_path.exists() and res_path.exists()):
        return None
    t = HUGE.get(cell)
    if not t:
        return None
    try:
        meta = json.load(open(meta_path))
    except Exception:
        return None
    unident = set(meta.get('best', {}).get('all_unidentifiable', []))
    truth_map = {**{k: v for k, v in t['parameter_values'].items()},
                 **{f'{k}(t)': v for k, v in t['state_values'].items()}}
    try:
        rows = list(csv.DictReader(open(res_path)))
    except Exception:
        return None
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
        try:
            return max(rel_err(fl(r[c]), truth_map[c]) for c in cmp_cols)
        except Exception:
            return float('inf')
    oracles = [oracle(r) for r in rows]
    return rows, oracles, sat_cols

def rank_under(rows, sat_cols, scheme):
    """Return permutation of row indices under the given scheme."""
    if scheme == 'err_only':
        key = lambda i: fl(rows[i]['err'])
    elif scheme == 's2':
        key = lambda i: (saturation_count(rows[i], sat_cols), is_neg1(rows[i]), fl(rows[i]['err']))
    else:
        raise ValueError(scheme)
    return sorted(range(len(rows)), key=key)

def required_K(rows, oracles, sat_cols, scheme, threshold):
    """Return smallest 1-indexed rank under `scheme` where oracle ≤ threshold; or None."""
    order = rank_under(rows, sat_cols, scheme)
    for rank, idx in enumerate(order, start=1):
        if oracles[idx] <= threshold:
            return rank
    return None

def quantiles(values, qs=(0.5, 0.9, 0.99)):
    """Return list of quantile values (treating None as inf)."""
    finite = sorted(v for v in values if v is not None)
    inf_count = sum(1 for v in values if v is None)
    n = len(values)
    out = []
    for q in qs:
        idx = int(q * n)
        if idx >= len(finite):
            out.append(None)
        else:
            out.append(finite[idx])
    return out, inf_count

def main():
    cells_all = sorted(d.name for d in ROOT.iterdir() if d.is_dir())
    print(f"# Probe 4c: full benchmark walk")
    print(f"# Cells in directory: {len(cells_all)}")

    per_cell = []
    skipped = 0
    deep_failures = 0  # cells where best oracle > 50%

    for name in cells_all:
        system, instance, noise = parse_cell_name(name)
        if system is None:
            skipped += 1
            continue
        d = cell_data(name)
        if d is None:
            skipped += 1
            continue
        rows, oracles, sat_cols = d
        best_oracle = min(oracles)
        if best_oracle > 0.5:
            deep_failures += 1
        # Schemes
        rank1_err = oracles[rank_under(rows, sat_cols, 'err_only')[0]]
        rank1_s2 = oracles[rank_under(rows, sat_cols, 's2')[0]]
        # required_K under each scheme + threshold
        rk_err_1 = required_K(rows, oracles, sat_cols, 'err_only', 0.01)
        rk_err_10 = required_K(rows, oracles, sat_cols, 'err_only', 0.10)
        rk_s2_1 = required_K(rows, oracles, sat_cols, 's2', 0.01)
        rk_s2_10 = required_K(rows, oracles, sat_cols, 's2', 0.10)
        per_cell.append({
            'cell': name,
            'system': system,
            'instance': instance,
            'noise': noise,
            'n_rows': len(rows),
            'best_oracle': best_oracle,
            'rank1_err': rank1_err,
            'rank1_s2': rank1_s2,
            'rk_err_1': rk_err_1,
            'rk_err_10': rk_err_10,
            'rk_s2_1': rk_s2_1,
            'rk_s2_10': rk_s2_10,
        })

    print(f"# Parsed: {len(per_cell)} cells (skipped {skipped} cells without result/truth)")
    print(f"# Deep-failure cells (no row with oracle ≤ 50%): {deep_failures} / {len(per_cell)}")
    print()

    # Per-cell CSV
    with open(PER_CELL_CSV, 'w', newline='') as fp:
        wr = csv.DictWriter(fp, fieldnames=list(per_cell[0].keys()))
        wr.writeheader()
        for r in per_cell:
            wr.writerow(r)
    print(f"Per-cell CSV: {PER_CELL_CSV}")
    print()

    # Overall stats
    def stats(rows, key):
        vals = [r[key] for r in rows if r[key] is not None]
        n = len(rows)
        s = sorted(vals)
        if not s:
            return None
        return {
            'median': s[len(s)//2],
            'mean': sum(vals)/len(vals),
            'p90': s[int(len(s)*0.9)] if int(len(s)*0.9) < len(s) else s[-1],
            'pct_le_1pct': 100 * sum(1 for v in vals if v <= 0.01) / n,
            'pct_le_10pct': 100 * sum(1 for v in vals if v <= 0.10) / n,
        }

    print(f"{'scheme':<25s}  {'median':>10s}  {'mean':>10s}  {'p90':>10s}  {'≤1%':>7s}  {'≤10%':>7s}")
    print('-' * 80)
    for key, name in [('rank1_err', 'err_only (rank-1 oracle)'),
                      ('rank1_s2', 'S2 (rank-1 oracle)')]:
        st = stats(per_cell, key)
        print(f"{name:<25s}  {st['median']:>10.3g}  {st['mean']:>10.3g}  {st['p90']:>10.3g}  {st['pct_le_1pct']:>6.1f}%  {st['pct_le_10pct']:>6.1f}%")

    # Pairwise S2 vs err_only
    wins = sum(1 for r in per_cell if r['rank1_s2'] < r['rank1_err'])
    losses = sum(1 for r in per_cell if r['rank1_s2'] > r['rank1_err'])
    ties = len(per_cell) - wins - losses
    print(f"\nPairwise S2 vs err_only: wins={wins}  losses={losses}  ties={ties}  (out of {len(per_cell)})")

    # Required_K distribution under S2 @ 10%
    print()
    print("Required_K distribution under S2 @ 10% (smallest rank with oracle ≤ 10%):")
    bins = [(1, 1), (2, 5), (6, 10), (11, 20), (21, 50), (51, 100), (101, 99999), (None, None)]
    rk_counts = defaultdict(int)
    for r in per_cell:
        v = r['rk_s2_10']
        if v is None:
            rk_counts['never'] += 1
        else:
            for lo, hi in bins[:-1]:
                if lo <= v <= hi:
                    rk_counts[f'{lo}-{hi}' if lo != hi else f'{lo}'] += 1
                    break
    for lo, hi in bins:
        if lo is None:
            key = 'never'
        elif lo == hi:
            key = f'{lo}'
        else:
            key = f'{lo}-{hi}'
        print(f"  K {key:<10s}: {rk_counts[key]:>5d}  ({100*rk_counts[key]/len(per_cell):>5.1f}%)")

    # Per-noise breakdown (rank-1 S2)
    print()
    print(f"Per-noise breakdown (rank-1 S2 oracle):")
    print(f"{'noise':<8s}  {'n':>5s}  {'median':>10s}  {'mean':>10s}  {'p90':>10s}  {'≤1%':>7s}  {'≤10%':>7s}")
    print('-' * 80)
    by_noise = defaultdict(list)
    for r in per_cell:
        by_noise[r['noise']].append(r)
    for noise in sorted(by_noise.keys()):
        rows = by_noise[noise]
        st = stats(rows, 'rank1_s2')
        print(f"{noise:<8s}  {len(rows):>5d}  {st['median']:>10.3g}  {st['mean']:>10.3g}  {st['p90']:>10.3g}  {st['pct_le_1pct']:>6.1f}%  {st['pct_le_10pct']:>6.1f}%")

    # Per-system breakdown (rank-1 S2)
    print()
    print(f"Per-system breakdown (rank-1 S2 oracle, sorted by %≤10% ascending):")
    print(f"{'system':<35s}  {'n':>5s}  {'median':>10s}  {'p90':>10s}  {'≤1%':>7s}  {'≤10%':>7s}")
    print('-' * 100)
    by_sys = defaultdict(list)
    for r in per_cell:
        by_sys[r['system']].append(r)
    sys_stats = [(sys, len(rows), stats(rows, 'rank1_s2')) for sys, rows in by_sys.items()]
    sys_stats.sort(key=lambda x: x[2]['pct_le_10pct'])
    for sys, n, st in sys_stats:
        print(f"{sys:<35s}  {n:>5d}  {st['median']:>10.3g}  {st['p90']:>10.3g}  {st['pct_le_1pct']:>6.1f}%  {st['pct_le_10pct']:>6.1f}%")

    # System × noise grid (% ≤ 10% under S2)
    print()
    print(f"System × noise grid (%≤10% under S2, '-' = no cells):")
    noise_order = ['0', '1em8', '1em6', '1em4', '1em2']
    print(f"  {'system':<32s}  " + '  '.join(f'{n:>7s}' for n in noise_order))
    grid_data = defaultdict(dict)
    for r in per_cell:
        grid_data[r['system']].setdefault(r['noise'], []).append(r)
    sys_order = sorted(grid_data.keys(), key=lambda s: -sum(len(v) for v in grid_data[s].values()))
    for sys in sys_order:
        row = f"  {sys:<32s}  "
        for n in noise_order:
            cell_rows = grid_data[sys].get(n, [])
            if not cell_rows:
                row += f'{"-":>7s}  '
            else:
                st = stats(cell_rows, 'rank1_s2')
                row += f'{st["pct_le_10pct"]:>6.0f}%  '
        print(row)

    # Markdown report
    write_md(per_cell, deep_failures)
    print(f"\nMarkdown: {RESULTS_MD}")

def write_md(per_cell, deep_failures):
    n = len(per_cell)
    def stats(rows, key):
        vals = [r[key] for r in rows if r[key] is not None]
        if not vals:
            return None
        s = sorted(vals)
        return {
            'median': s[len(s)//2],
            'mean': sum(vals)/len(vals),
            'p90': s[int(len(s)*0.9)] if int(len(s)*0.9) < len(s) else s[-1],
            'pct_le_1pct': 100 * sum(1 for v in vals if v <= 0.01) / len(rows),
            'pct_le_10pct': 100 * sum(1 for v in vals if v <= 0.10) / len(rows),
        }
    with open(RESULTS_MD, 'w') as fp:
        fp.write(f"# Probe 4c — full 2026-05-14 numbat benchmark walk\n\n")
        fp.write(f"Cells: **{n}** (all cells with valid result.csv + huge_json truth).\n")
        fp.write(f"Deep-failure cells (best oracle > 50%): **{deep_failures}** / {n} ({100*deep_failures/n:.1f}%).\n\n")

        fp.write(f"## Overall rank-1 oracle (full benchmark)\n\n")
        fp.write("| scheme | median | mean | p90 | %≤1% | %≤10% |\n|---|---|---|---|---|---|\n")
        for key, name in [('rank1_err', 'err_only'), ('rank1_s2', 'S2 (current default)')]:
            st = stats(per_cell, key)
            fp.write(f"| {name} | {st['median']:.3g} | {st['mean']:.3g} | {st['p90']:.3g} | {st['pct_le_1pct']:.1f}% | {st['pct_le_10pct']:.1f}% |\n")

        wins = sum(1 for r in per_cell if r['rank1_s2'] < r['rank1_err'])
        losses = sum(1 for r in per_cell if r['rank1_s2'] > r['rank1_err'])
        ties = n - wins - losses
        fp.write(f"\nPairwise: S2 wins {wins}, loses {losses}, ties {ties} (out of {n}).\n\n")

        fp.write(f"## Required_K distribution (smallest rank with oracle ≤ 10%, under S2 sort)\n\n")
        fp.write("| K range | count | % |\n|---|---|---|\n")
        bins = [(1, 1), (2, 5), (6, 10), (11, 20), (21, 50), (51, 100), (101, None), (None, None)]
        for lo, hi in bins:
            if lo is None:
                key, count = 'never', sum(1 for r in per_cell if r['rk_s2_10'] is None)
                label = 'never (no oracle-close row)'
            else:
                if hi is None:
                    count = sum(1 for r in per_cell if r['rk_s2_10'] is not None and r['rk_s2_10'] > 100)
                    label = '101+'
                else:
                    count = sum(1 for r in per_cell if r['rk_s2_10'] is not None and lo <= r['rk_s2_10'] <= hi)
                    label = f'{lo}-{hi}' if lo != hi else f'{lo}'
            fp.write(f"| {label} | {count} | {100*count/n:.1f}% |\n")

        fp.write(f"\n## Per-noise breakdown (rank-1 S2 oracle)\n\n")
        fp.write("| noise | n | median | mean | p90 | %≤1% | %≤10% |\n|---|---|---|---|---|---|---|\n")
        by_noise = defaultdict(list)
        for r in per_cell:
            by_noise[r['noise']].append(r)
        for noise in sorted(by_noise.keys()):
            rows = by_noise[noise]
            st = stats(rows, 'rank1_s2')
            fp.write(f"| {noise} | {len(rows)} | {st['median']:.3g} | {st['mean']:.3g} | {st['p90']:.3g} | {st['pct_le_1pct']:.1f}% | {st['pct_le_10pct']:.1f}% |\n")

        fp.write(f"\n## Per-system breakdown (rank-1 S2 oracle, sorted by %≤10%)\n\n")
        fp.write("| system | n | median | p90 | %≤1% | %≤10% |\n|---|---|---|---|---|---|\n")
        by_sys = defaultdict(list)
        for r in per_cell:
            by_sys[r['system']].append(r)
        sys_stats = [(sys, len(rows), stats(rows, 'rank1_s2')) for sys, rows in by_sys.items()]
        sys_stats.sort(key=lambda x: x[2]['pct_le_10pct'])
        for sys, nn, st in sys_stats:
            fp.write(f"| {sys} | {nn} | {st['median']:.3g} | {st['p90']:.3g} | {st['pct_le_1pct']:.1f}% | {st['pct_le_10pct']:.1f}% |\n")

        fp.write(f"\n## System × noise grid (%≤10% under S2)\n\n")
        noise_order = ['0', '1em8', '1em6', '1em4', '1em2']
        fp.write("| system | " + ' | '.join(noise_order) + ' |\n')
        fp.write("|" + "---|"*(len(noise_order)+1) + "\n")
        grid_data = defaultdict(dict)
        for r in per_cell:
            grid_data[r['system']].setdefault(r['noise'], []).append(r)
        for sys in sorted(grid_data.keys()):
            line = f"| {sys} | "
            for n_ in noise_order:
                cell_rows = grid_data[sys].get(n_, [])
                if not cell_rows:
                    line += '— | '
                else:
                    st = stats(cell_rows, 'rank1_s2')
                    line += f'{st["pct_le_10pct"]:.0f}% | '
            fp.write(line + '\n')

if __name__ == '__main__':
    main()
