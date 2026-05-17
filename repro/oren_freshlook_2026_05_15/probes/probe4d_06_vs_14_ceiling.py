#!/usr/bin/env python3
"""Probe 4d — 06 vs 14 candidate-set ceiling comparison.

The 06 benchmark returned many more rows per cell (~2000 vs 14's 100-cap
after clustering). Question: did clustering+capping in 13/14 lose any
truth-finding ceiling vs 06?

For each cell that exists in both benchmarks (using the same huge_json
truth):
  - 06 set ceiling: closest oracle across ALL ~2000 rows of result.csv
  - 14 set ceiling: closest oracle across the (≤100) clustered top-K rows

Report:
  - Aggregate %≤1%, %≤10% for each
  - Pairwise: cells where 06 had a closer row than 14 (lost ceiling)
  - Pairwise: cells where 14 has a closer row than 06 (improved)
  - Per-system breakdown

Note: 06's result.csv has no `err` / `polish_source_hc_idx` columns. So we
can only compute set ceiling, not ranked K-recall. Apples-to-apples K-recall
would require re-running 06 cells through the current pipeline, which is
out of scope.
"""
import json, csv, math
from collections import defaultdict
from pathlib import Path

ROOT06 = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-06/filetree/odepe_v2_polish_run')
ROOT14 = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-06/huge_json.json'))['instances']}

OUT_DIR = Path(__file__).parent
RESULTS_MD = OUT_DIR / 'probe4d_results.md'
PER_CELL_CSV = OUT_DIR / 'probe4d_per_cell.csv'

NOISE_TOKENS = {'0', '1em2', '1em4', '1em6', '1em8'}

def parse_cell_name(name):
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

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)

def set_ceiling(cell_dir, truth_map, unident):
    """Best (smallest) oracle max-rel-err across all rows in result.csv.
    Returns (best_oracle, n_rows) or (None, 0) on failure."""
    res = cell_dir / 'result.csv'
    if not res.exists():
        return None, 0
    try:
        rows = list(csv.DictReader(open(res)))
    except Exception:
        return None, 0
    if not rows:
        return None, 0
    cmp_cols = [c for c in rows[0]
                if c not in ('err', 'post_polish_error', 'branch_size', 'polish_source_hc_idx')
                and not c.startswith('_trfn_')
                and c in truth_map
                and c not in unident]
    if not cmp_cols:
        return None, 0
    best = float('inf')
    for r in rows:
        try:
            o = max(rel_err(fl(r[c]), truth_map[c]) for c in cmp_cols)
            if o < best:
                best = o
        except Exception:
            continue
    return best, len(rows)

def main():
    cells = sorted(d.name for d in ROOT14.iterdir() if d.is_dir())
    print(f"# Probe 4d: 06 vs 14 set-ceiling comparison")
    print(f"# Cells (from 14 directory): {len(cells)}")

    per_cell = []
    skipped = 0
    for name in cells:
        system, instance, noise = parse_cell_name(name)
        if system is None:
            skipped += 1
            continue
        t = HUGE.get(name)
        if not t:
            skipped += 1
            continue
        # Get unident from 14's metadata (assumed same for both — uses same SI)
        meta_path = ROOT14 / name / 'odepe_metadata.json'
        if not meta_path.exists():
            skipped += 1
            continue
        try:
            meta = json.load(open(meta_path))
        except Exception:
            skipped += 1
            continue
        unident = set(meta.get('best', {}).get('all_unidentifiable', []))
        truth_map = {**{k: v for k, v in t['parameter_values'].items()},
                     **{f'{k}(t)': v for k, v in t['state_values'].items()}}

        c06, n06 = set_ceiling(ROOT06 / name, truth_map, unident)
        c14, n14 = set_ceiling(ROOT14 / name, truth_map, unident)
        if c06 is None or c14 is None:
            skipped += 1
            continue
        per_cell.append({
            'cell': name, 'system': system, 'instance': instance, 'noise': noise,
            'n_rows_06': n06, 'n_rows_14': n14,
            'ceiling_06': c06, 'ceiling_14': c14,
            'delta': c14 - c06,
        })

    print(f"# Parsed: {len(per_cell)} cells (skipped {skipped})")
    print()

    n = len(per_cell)
    def stats_at(rows, key, threshold):
        return 100 * sum(1 for r in rows if r[key] <= threshold) / len(rows)

    print(f"{'metric':<32s}  {'06 ceiling':>12s}  {'14 ceiling':>12s}  {'Δ (pp)':>9s}")
    print('-' * 75)
    for label, thr in [('%≤1%', 0.01), ('%≤10%', 0.10), ('%≤50%', 0.50)]:
        p06 = stats_at(per_cell, 'ceiling_06', thr)
        p14 = stats_at(per_cell, 'ceiling_14', thr)
        print(f"  {label:<28s}  {p06:>11.1f}%  {p14:>11.1f}%  {p14 - p06:>+8.2f}")

    # Median rows per cell
    n06_med = sorted(r['n_rows_06'] for r in per_cell)[len(per_cell)//2]
    n14_med = sorted(r['n_rows_14'] for r in per_cell)[len(per_cell)//2]
    n06_max = max(r['n_rows_06'] for r in per_cell)
    n14_max = max(r['n_rows_14'] for r in per_cell)
    print()
    print(f"Rows per cell  median: 06={n06_med}  14={n14_med}")
    print(f"Rows per cell  max:    06={n06_max}  14={n14_max}")

    # Pairwise: cells where 06 had a closer row than 14 (= clustering lost ceiling)
    lost = sum(1 for r in per_cell if r['ceiling_06'] < r['ceiling_14'])
    improved = sum(1 for r in per_cell if r['ceiling_14'] < r['ceiling_06'])
    same = n - lost - improved
    print()
    print(f"Pairwise comparison (smaller oracle = closer to truth):")
    print(f"  06 closer than 14 (clustering lost): {lost:>5d}  ({100*lost/n:.1f}%)")
    print(f"  14 closer than 06 (better pipeline): {improved:>5d}  ({100*improved/n:.1f}%)")
    print(f"  same:                                 {same:>5d}  ({100*same/n:.1f}%)")

    # Cells where 06 succeeded ≤10% but 14 didn't (or vice versa)
    print()
    for thr, label in [(0.01, '@1%'), (0.10, '@10%')]:
        o06 = set(r['cell'] for r in per_cell if r['ceiling_06'] <= thr)
        o14 = set(r['cell'] for r in per_cell if r['ceiling_14'] <= thr)
        lost_at = o06 - o14
        gained_at = o14 - o06
        print(f"{label}: 06 succeeded but 14 lost: {len(lost_at)}  |  14 succeeded but 06 lost: {len(gained_at)}")

    # Per-system breakdown
    print()
    print("Per-system 06 vs 14 ceiling (%≤10%):")
    print(f"{'system':<28s}  {'n':>4s}  {'06%≤10%':>9s}  {'14%≤10%':>9s}  {'Δ':>6s}")
    print('-' * 65)
    by_sys = defaultdict(list)
    for r in per_cell:
        by_sys[r['system']].append(r)
    sys_rows = []
    for sys, rows in by_sys.items():
        p06 = stats_at(rows, 'ceiling_06', 0.10)
        p14 = stats_at(rows, 'ceiling_14', 0.10)
        sys_rows.append((sys, len(rows), p06, p14, p14 - p06))
    sys_rows.sort(key=lambda x: x[4])  # sort by delta ascending (biggest 14-losses first)
    for sys, nn, p06, p14, d in sys_rows:
        print(f"{sys:<28s}  {nn:>4d}  {p06:>8.1f}%  {p14:>8.1f}%  {d:>+5.1f}")

    # CSV
    with open(PER_CELL_CSV, 'w', newline='') as fp:
        wr = csv.DictWriter(fp, fieldnames=list(per_cell[0].keys()))
        wr.writeheader()
        for r in per_cell:
            wr.writerow(r)
    print(f"\nPer-cell CSV: {PER_CELL_CSV}")

    # Markdown
    write_md(per_cell, sys_rows, n06_med, n14_med, n06_max, n14_max)
    print(f"Markdown: {RESULTS_MD}")

def write_md(per_cell, sys_rows, n06_med, n14_med, n06_max, n14_max):
    n = len(per_cell)
    def stats_at(rows, key, threshold):
        return 100 * sum(1 for r in rows if r[key] <= threshold) / len(rows)
    with open(RESULTS_MD, 'w') as fp:
        fp.write(f"# Probe 4d — 06 vs 14 candidate-set ceiling\n\n")
        fp.write(f"Apples-to-apples: for each of {n} cells, what's the closest-to-truth\n")
        fp.write(f"row across *all* rows of result.csv? (06 returns ~2000 rows per cell;\n")
        fp.write(f"14 returns ≤100 after clustering and `branch_top_k` cap.)\n\n")
        fp.write(f"Rows per cell: median 06={n06_med}, 14={n14_med}; max 06={n06_max}, 14={n14_max}.\n\n")
        fp.write("## Set-ceiling stats\n\n")
        fp.write("| Threshold | 06 ceiling | 14 ceiling | Δ (pp) |\n|---|---|---|---|\n")
        for label, thr in [('≤1%', 0.01), ('≤10%', 0.10), ('≤50%', 0.50)]:
            p06 = stats_at(per_cell, 'ceiling_06', thr)
            p14 = stats_at(per_cell, 'ceiling_14', thr)
            fp.write(f"| {label} | {p06:.1f}% | {p14:.1f}% | {p14 - p06:+.2f} |\n")
        lost = sum(1 for r in per_cell if r['ceiling_06'] < r['ceiling_14'])
        improved = sum(1 for r in per_cell if r['ceiling_14'] < r['ceiling_06'])
        same = n - lost - improved
        fp.write(f"\n## Pairwise\n\n")
        fp.write(f"- 06 had a closer row than 14 (clustering lost ceiling): **{lost}** ({100*lost/n:.1f}%)\n")
        fp.write(f"- 14 had a closer row than 06 (pipeline improved): **{improved}** ({100*improved/n:.1f}%)\n")
        fp.write(f"- Same: {same} ({100*same/n:.1f}%)\n\n")
        fp.write("## Crossing rate\n\n")
        for thr, label in [(0.01, '≤1%'), (0.10, '≤10%')]:
            o06 = set(r['cell'] for r in per_cell if r['ceiling_06'] <= thr)
            o14 = set(r['cell'] for r in per_cell if r['ceiling_14'] <= thr)
            lost_at = o06 - o14
            gained_at = o14 - o06
            fp.write(f"- At {label}: 06 succeeded but 14 lost: **{len(lost_at)}** cells; 14 succeeded but 06 lost: **{len(gained_at)}**\n")
        fp.write(f"\n## Per-system breakdown (sorted by Δ ascending — biggest 14-losses first)\n\n")
        fp.write("| system | n | 06 %≤10% | 14 %≤10% | Δ (pp) |\n|---|---|---|---|---|\n")
        for sys, nn, p06, p14, d in sys_rows:
            fp.write(f"| {sys} | {nn} | {p06:.1f}% | {p14:.1f}% | {d:+.1f} |\n")
        fp.write(f"\n## Caveats\n\n")
        fp.write(f"- This compares **set ceilings only**. K-recall under ranking schemes (S2, err_only) requires `err` column which the 06 result.csv doesn't have. To get ranked-K-recall on 06, we'd need to re-run the 06 cells through the current pipeline.\n")
        fp.write(f"- The 14 candidate set already had `branch_top_k = 100` applied. So '14 ceiling' = best of top-100 reps, not best of all generated raw HC candidates. If clustering threw out a truth-near rep that wasn't in the top-100, this would show as a 14-loss.\n")

if __name__ == '__main__':
    main()
