#!/usr/bin/env python3
"""300-cell sample: for each cell, find oracle-best row in 14's result.csv
and report rank within err-sorted output. Reads from rsync mirror.

Hypothesis: the truth-near row exists in the set but is buried at high rank.
"""
import json, csv, random
from pathlib import Path

ROOT14 = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/huge_json.json'))['instances']}

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)

def analyze(cell, t):
    csvp = ROOT14 / cell / 'result.csv'
    if not csvp.exists(): return None
    rows = list(csv.DictReader(open(csvp)))
    if not rows: return None
    meta = json.load(open(ROOT14 / cell / 'odepe_metadata.json'))
    unident = meta.get('best',{}).get('all_unidentifiable', [])
    truth = {}
    for k,v in t['parameter_values'].items(): truth[k] = v
    for k,v in t['state_values'].items(): truth[f'{k}(t)'] = v
    fields = list(rows[0].keys())
    cmp_cols = [c for c in fields if c not in ('err','post_polish_error','branch_size','polish_source_hc_idx')
                and not c.startswith('_trfn_') and c in truth and c not in unident]
    if not cmp_cols: return None
    def oracle(r):
        try: return max(rel_err(float(r[c]), truth[c]) for c in cmp_cols)
        except: return float('inf')
    oracles = [oracle(r) for r in rows]
    best_idx = min(range(len(rows)), key=lambda i: oracles[i])
    return {
        'cell': cell,
        'n_rows': len(rows),
        'oracle_at_rank1': oracles[0],
        'oracle_best_rank': best_idx + 1,
        'oracle_best': oracles[best_idx],
        'cmp_cols': cmp_cols,
    }

if __name__ == '__main__':
    random.seed(0)
    cells = sorted([d.name for d in ROOT14.iterdir() if d.is_dir() and (d/'result.csv').exists()])
    sample = random.sample(cells, 300)
    buckets = {k: 0 for k in ['1','2-5','6-10','11-50','51-100','>100','no_oracle_close']}
    gap = []
    for cell in sample:
        t = HUGE.get(cell)
        if not t: continue
        r = analyze(cell, t)
        if r is None: continue
        if r['oracle_best'] > 0.5:
            buckets['no_oracle_close'] += 1; continue
        rk = r['oracle_best_rank']
        if rk == 1: buckets['1'] += 1
        elif rk <= 5: buckets['2-5'] += 1
        elif rk <= 10: buckets['6-10'] += 1
        elif rk <= 50: buckets['11-50'] += 1
        elif rk <= 100: buckets['51-100'] += 1
        else: buckets['>100'] += 1
        if r['oracle_at_rank1'] > 10 * r['oracle_best'] and r['oracle_best'] < 0.1:
            gap.append(r)
    total = sum(buckets.values())
    print(f"# 300-cell sample (n={total})")
    for k in ['1','2-5','6-10','11-50','51-100','>100','no_oracle_close']:
        print(f"  rank {k:>12s}: {buckets[k]:4d} ({100*buckets[k]/total:5.1f}%)")
    print(f"\n# Cells with rank-1 oracle >10× worse than oracle-best (oracle-best <0.1): {len(gap)}")
