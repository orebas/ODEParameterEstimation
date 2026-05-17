#!/usr/bin/env python3
"""Probe 3 (analysis): read synthesis_log.csv produced by probe3_slow_fast_aggregates.jl
and characterize how aggregate candidates split across the two algebraic basins of
slow_fast_6_1em4.

Approach:
- For each aggregate row, classify which basin its (xA, xB, eB, k1, k2) sits in.
  Truth basin: xA > 0 (xA truth = 0.418).
  Mirror basin: xA < 0 (mirror xA ≈ -10.4).
- Group by aggregation_strategy and category (A/B/C/D notes from synthesize_aggregates.jl).
- Report: per-(strategy, category) counts of truth-basin vs mirror-basin assignments.
"""
import csv
from pathlib import Path
from collections import Counter, defaultdict
import sys

# probe3_slow_fast_aggregates.jl writes to ./artifacts/diagnostics/slow_fast/synthesis_log.csv
# relative to probe3_outputs/
SYNTH_PATH = Path(__file__).parent / 'probe3_outputs' / 'artifacts' / 'diagnostics' / 'slow_fast' / 'synthesis_log.csv'

def fl(s):
    try: return float(s)
    except: return float('nan')

def main():
    if not SYNTH_PATH.exists():
        print(f"# ERROR: synthesis_log.csv not found at {SYNTH_PATH}")
        print(f"# Run probe3_slow_fast_aggregates.jl first.")
        sys.exit(1)

    rows = list(csv.DictReader(open(SYNTH_PATH)))
    print(f"# Probe 3 analysis: {len(rows)} synthesized aggregate candidates loaded.")
    print(f"# Columns: {list(rows[0].keys()) if rows else '(empty)'}")
    print()

    # Identify the xA column (likely 'state_xA(t)' or similar)
    xa_col = None
    for c in rows[0]:
        if c in ('state_xA(t)', 'state_xA', 'xA(t)', 'xA') or c.endswith('xA(t)') or c.endswith('_xA'):
            xa_col = c
            break
    if xa_col is None:
        # fallback — try any column with 'xA' in it
        xa_cands = [c for c in rows[0] if 'xA' in c]
        if xa_cands:
            xa_col = xa_cands[0]
            print(f"# Using xA column: {xa_col}")
        else:
            print(f"# ERROR: cannot find xA column in {list(rows[0].keys())}")
            sys.exit(1)
    print(f"# Basin assignment by sign/magnitude of column: {xa_col}")

    def basin_of(r):
        v = fl(r[xa_col])
        if v != v:  # NaN
            return 'unknown'
        if v > 0:
            return 'truth'
        else:
            return 'mirror'

    # 1. Overall basin split
    basin_counts = Counter(basin_of(r) for r in rows)
    print(f"\n## Overall basin split among synthesized aggregates:")
    for b, n in basin_counts.most_common():
        print(f"  {b}: {n}")

    # 2. By aggregation_strategy
    print(f"\n## By aggregation_strategy:")
    by_strategy = defaultdict(lambda: Counter())
    for r in rows:
        by_strategy[r.get('strategy', '?')][basin_of(r)] += 1
    for strat, c in sorted(by_strategy.items()):
        n_total = sum(c.values())
        truth = c.get('truth', 0)
        mirror = c.get('mirror', 0)
        unknown = c.get('unknown', 0)
        print(f"  {strat:<30s}: n={n_total:>4d}  truth={truth:>4d}  mirror={mirror:>4d}  unknown={unknown:>4d}")

    # 3. By category (A/B/C/D from notes)
    print(f"\n## By category:")
    by_cat = defaultdict(lambda: Counter())
    for r in rows:
        by_cat[r.get('category', '?')][basin_of(r)] += 1
    for cat, c in sorted(by_cat.items()):
        n_total = sum(c.values())
        truth = c.get('truth', 0)
        mirror = c.get('mirror', 0)
        print(f"  {cat:<30s}: n={n_total:>4d}  truth={truth:>4d}  mirror={mirror:>4d}")

    # 4. By (category, strategy) combo
    print(f"\n## By (category, strategy):")
    by_combo = defaultdict(lambda: Counter())
    for r in rows:
        by_combo[(r.get('category', '?'), r.get('strategy', '?'))][basin_of(r)] += 1
    for combo, c in sorted(by_combo.items()):
        n_total = sum(c.values())
        truth = c.get('truth', 0)
        mirror = c.get('mirror', 0)
        if n_total >= 1:
            print(f"  {str(combo):<50s}: n={n_total:>4d}  truth={truth:>4d}  mirror={mirror:>4d}")

    # 5. Source-index analysis: for each aggregate, do its source candidates come from same basin or mixed?
    # source_indices column has format "[i;j;k]" — we don't have per-source-index basin info here
    # (we'd need to cross-reference with the upstream candidate pool, which isn't logged separately).
    # Note this as a limitation.
    print()
    print(f"## Note: per-source-candidate basin assignment requires cross-referencing")
    print(f"   with the upstream candidate pool (raw HC + multipoint), which the")
    print(f"   sidecar doesn't log. This analysis only sees aggregates' resulting basin.")

    # 6. Summary table
    print()
    print(f"## Summary: does aggregate synthesis populate both basins?")
    n_truth = basin_counts.get('truth', 0)
    n_mirror = basin_counts.get('mirror', 0)
    if n_truth > 0 and n_mirror > 0:
        print(f"   YES. {n_truth} aggregates in truth basin, {n_mirror} in mirror basin.")
        print(f"   Ratio: {n_truth/(n_truth+n_mirror)*100:.1f}% truth / {n_mirror/(n_truth+n_mirror)*100:.1f}% mirror")
    elif n_truth > 0:
        print(f"   ONLY truth basin populated. {n_truth} aggregates.")
    elif n_mirror > 0:
        print(f"   ONLY mirror basin populated. {n_mirror} aggregates.")
    else:
        print(f"   Neither basin clearly populated.")

if __name__ == '__main__':
    main()
