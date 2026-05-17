#!/usr/bin/env python3
"""Compare alternative rank-1 schemes against current err-only sort.

Result: 'non-(-1) source first, then err' raises ≤1% recovery 71.6% → 77.5%.
"""
import json, csv, random
from pathlib import Path

ROOT14 = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/huge_json.json'))['instances']}

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)
def fl(s):
    try: return float(s)
    except: return float('inf')
def is_neg1(r): return r['polish_source_hc_idx'] in ('-1.0','-1')

def all_data(cell, t):
    meta = json.load(open(ROOT14/cell/'odepe_metadata.json'))
    unident = meta.get('best',{}).get('all_unidentifiable',[])
    truth = {}
    for k,v in t['parameter_values'].items(): truth[k]=v
    for k,v in t['state_values'].items(): truth[f'{k}(t)']=v
    rows = list(csv.DictReader(open(ROOT14/cell/'result.csv')))
    if not rows: return None
    cmp_cols = [c for c in rows[0] if c not in ('err','post_polish_error','branch_size','polish_source_hc_idx')
                and not c.startswith('_trfn_') and c in truth and c not in unident]
    if not cmp_cols: return None
    def oracle(r): return max(rel_err(float(r[c]), truth[c]) for c in cmp_cols)
    return rows, [oracle(r) for r in rows]

def scheme_G(rows, tau):
    """Prefer non-(-1) only if some HC row has err <= tau × min_err."""
    errs = [fl(r['err']) for r in rows]
    non1 = [i for i,r in enumerate(rows) if not is_neg1(r)]
    if not non1: return sorted(range(len(rows)), key=lambda i: errs[i])
    e_hc, e_min = min(errs[i] for i in non1), min(errs)
    if e_hc <= tau * e_min:
        return sorted(range(len(rows)), key=lambda i: (is_neg1(rows[i]), errs[i]))
    return sorted(range(len(rows)), key=lambda i: errs[i])

if __name__ == '__main__':
    random.seed(0)
    cells = sorted([d.name for d in ROOT14.iterdir() if d.is_dir() and (d/'result.csv').exists()])
    sample = random.sample(cells, 300)
    cd = []
    for cell in sample:
        t = HUGE.get(cell)
        if not t: continue
        d = all_data(cell, t)
        if d and min(d[1]) <= 0.5:
            cd.append((cell,) + d)

    def evalit(name, rank_fn):
        ors = []
        for cell, rows, oracles in cd:
            order = rank_fn(rows)
            ors.append(oracles[order[0]])
        s = sorted(ors)
        pct1 = 100*sum(1 for v in ors if v <= 0.01)/len(ors)
        pct10 = 100*sum(1 for v in ors if v <= 0.10)/len(ors)
        med = s[len(s)//2]
        p90 = s[int(len(s)*0.9)]
        print(f'{name:<35s}  median={med:8.3g}  p90={p90:8.3g}  ≤1%={pct1:5.1f}%  ≤10%={pct10:5.1f}%')

    print(f"# Comparison on {len(cd)} cells (oracle-close row exists)")
    evalit('A: current (err only)',
           lambda rows: sorted(range(len(rows)), key=lambda i: fl(rows[i]['err'])))
    evalit('C: non-(-1) first, then err',
           lambda rows: sorted(range(len(rows)), key=lambda i: (is_neg1(rows[i]), fl(rows[i]['err']))))
    evalit('G/τ=100: smart conditional',
           lambda rows: scheme_G(rows, 100))
    ors = [min(o) for c,_,o in cd]
    s = sorted(ors)
    print(f'{"Z: oracle-best (lower bound)":<35s}  median={s[len(s)//2]:8.3g}  p90={s[int(len(s)*0.9)]:8.3g}  ≤1%={100*sum(1 for v in ors if v<=0.01)/len(ors):5.1f}%  ≤10%={100*sum(1 for v in ors if v<=0.10)/len(ors):5.1f}%')
