#!/usr/bin/env python3
"""For biohydrogenation: walk every row of result.csv per cell, project out x7,
and find cells where rows DEEPER than rank 1 contain the algebraic second
branch. Print the actual branch transformation.

Run: python3 biohydrogenation_actual_branches.py
"""
import csv, json, math
from pathlib import Path

REPO = Path("/home/orebas/rsync-readonly-PEB")
WAL = REPO / "benchmark_wallaby_2026-05-17"
ESTIMATORS = ['odepe_v2_polish', 'odepe_v2_nopolish']

def norm(c): return c[:-3] if c.endswith("(t)") else c

def parse_rows(p):
    if not p.exists(): return []
    with open(p) as f: rows = list(csv.DictReader(f))
    return [{norm(k): v for k, v in r.items()} for r in rows], rows

def get_unid(d):
    p = d / "odepe_metadata.json"
    if not p.exists(): return set()
    try:
        m = json.load(open(p))
        return set(norm(x) for x in m.get('best', {}).get('all_unidentifiable', []))
    except: return set()

def to_floats(r, axes):
    out = {}
    for k in axes:
        try:
            v = float(r[k]);
            if not math.isnan(v) and not math.isinf(v):
                out[k] = v
        except: pass
    return out

def max_rel_dist(d1, d2, axes):
    mx = 0.0; n = 0
    for k in axes:
        if k not in d1 or k not in d2: continue
        denom = max(abs(d1[k]), abs(d2[k]), 1e-10)
        mx = max(mx, abs(d1[k]-d2[k])/denom); n += 1
    return mx if n > 0 else None

with open(WAL / "huge_json.json") as f: j = json.load(f)
truths = {inst['id']: {**inst['state_values'], **inst['parameter_values']} for inst in j['instances']}

# Find cells where some row != row 0 by > 30% on identifiable axes (a true second branch)
found_branches = []
for est in ESTIMATORS:
    for cid in sorted(c for c in truths if c.startswith('biohydrogenation_')):
        d = WAL / "filetree" / f"{est}_run" / cid
        rows = parse_rows(d / "result.csv")
        if not rows: continue
        nrm, raw = rows
        if len(nrm) < 2: continue
        truth = truths[cid]
        unid = get_unid(d)
        id_axes = set(nrm[0].keys()) & set(truth.keys()) - unid

        truth_f = to_floats(truth, id_axes)
        rows_f = [to_floats(r, id_axes) for r in nrm]

        # Row 0 must be near truth
        d0 = max_rel_dist(rows_f[0], truth_f, id_axes)
        if d0 is None or d0 > 0.1: continue

        # Find first row > 1 that's > 30% from row 0
        for i in range(1, len(rows_f)):
            di = max_rel_dist(rows_f[i], rows_f[0], id_axes)
            if di is not None and di > 0.30:
                found_branches.append((cid, est, i, di, rows_f[0], rows_f[i], truth_f, unid))
                break

print(f"Found {len(found_branches)} cells with second-branch row at rank > 0")
print()

# Show first 3
for (cid, est, rank, dist, r0, ri, truth, unid) in found_branches[:5]:
    print("=" * 80)
    print(f"Cell: {cid}  est: {est}  second-branch at rank {rank}  r0~r{rank}: {dist:.2f}  unid: {sorted(unid)}")
    print("=" * 80)
    print(f"  {'Variable':<10} {'Truth':>12} {'Row 0':>12} {f'Row {rank}':>12} {'Row r/Truth':>12}")
    for k in sorted(truth):
        tv = truth.get(k); v0 = r0.get(k); vi = ri.get(k)
        if tv is None or v0 is None or vi is None: continue
        ratio = (vi/tv) if abs(tv) > 1e-10 else float('nan')
        print(f"  {k:<10} {tv:>12.4f} {v0:>12.4f} {vi:>12.4f} {ratio:>12.4f}")
    print()
