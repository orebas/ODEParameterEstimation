#!/usr/bin/env python3
"""For each multiplicity-≥ 2 system, print row 0 and row 1 of a representative
wallaby cell side-by-side along with their ratios. From the pattern, derive
the explicit branch transformation T.

Picks the LOWEST-noise cell where row 0 is near truth AND row 1 is far from
row 0 (so both branches are well-represented in the top 2 rows).

Run: python3 repro/multiplicity_complete_2026_05_19/branch_transformations.py
"""
import csv, json, math
from pathlib import Path

REPO = Path("/home/orebas/rsync-readonly-PEB")
WAL = REPO / "benchmark_wallaby_2026-05-17"

SYSTEMS = ['daisy_mamil4', 'seir', 'slow_fast', 'biohydrogenation']

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

with open(WAL / "huge_json.json") as f: j = json.load(f)
truths = {inst['id']: {**inst['state_values'], **inst['parameter_values']} for inst in j['instances']}

# Find a cell for each system where row 0 is near truth AND row 1 is far away
def pick_representative(sys_name, est='odepe_v2_nopolish'):
    """Return (cell_id, row0_normalized_dict, row1_normalized_dict, raw0, raw1, unid_set)."""
    best = None  # (cell_id, r0_truth_dist, r0_to_r1, info...)
    for cid in sorted(c for c in truths if c.startswith(sys_name + '_')):
        d = WAL / "filetree" / f"{est}_run" / cid
        if not (d / "result.csv").exists(): continue
        rows = parse_rows(d / "result.csv")
        if not rows: continue
        nrm, raw = rows
        if len(nrm) < 2: continue
        truth = truths[cid]
        unid = get_unid(d)
        id_axes = set(nrm[0].keys()) & set(truth.keys())
        r0 = nrm[0]; r1 = nrm[1]
        # row 0 close to truth
        max_r0_err = 0
        for k in id_axes - unid:
            try: ev = float(r0[k]); tv = truth[k]
            except: continue
            if math.isnan(ev) or math.isinf(ev): continue
            rel = abs(ev - tv) / abs(tv) if abs(tv) > 1e-10 else abs(ev - tv)
            max_r0_err = max(max_r0_err, rel)
        # row 0 to row 1 distance
        max_r0r1 = 0
        for k in id_axes - unid:
            try: v0 = float(r0[k]); v1 = float(r1[k])
            except: continue
            if math.isnan(v0) or math.isinf(v0) or math.isnan(v1) or math.isinf(v1): continue
            denom = max(abs(v0), abs(v1), 1e-10)
            rel = abs(v0 - v1) / denom
            max_r0r1 = max(max_r0r1, rel)
        # We want low max_r0_err and high max_r0r1 — pick the lowest-noise cell
        if max_r0_err < 0.10 and max_r0r1 > 0.05:
            return (cid, r0, r1, raw[0], raw[1], unid, truth, max_r0_err, max_r0r1)
    return None

for sys_name in SYSTEMS:
    print()
    print("=" * 80)
    print(f"SYSTEM: {sys_name}")
    print("=" * 80)
    pick = pick_representative(sys_name)
    if pick is None:
        # Try polish if nopolish fails
        pick = pick_representative(sys_name, est='odepe_v2_polish')
    if pick is None:
        print("  No representative cell found.")
        continue
    cid, r0, r1, raw0, raw1, unid, truth, r0_err, r0r1 = pick
    print(f"  Cell: {cid}  (r0~truth: {r0_err:.2e}, r0~r1: {r0r1:.2e}, unid: {sorted(unid) or '-'})")
    print()
    # Get all relevant keys
    truth_keys = sorted(set(truth.keys()) - unid)
    print(f"  {'Variable':<14} {'Truth':>14} {'Row 0':>14} {'Row 1':>14} {'Row1/Row0':>10} {'Row1/Truth':>11}")
    print(f"  {'-'*14} {'-'*14} {'-'*14} {'-'*14} {'-'*10} {'-'*11}")
    for k in truth_keys:
        tv = truth.get(k)
        try: v0 = float(r0.get(k, 'nan'))
        except: v0 = float('nan')
        try: v1 = float(r1.get(k, 'nan'))
        except: v1 = float('nan')
        tv_s = f"{tv:.6g}" if tv is not None else "-"
        v0_s = f"{v0:.6g}" if not math.isnan(v0) else "NaN"
        v1_s = f"{v1:.6g}" if not math.isnan(v1) else "NaN"
        ratio_10 = f"{v1/v0:.4f}" if not math.isnan(v0) and not math.isnan(v1) and abs(v0) > 1e-10 else "-"
        ratio_1t = f"{v1/tv:.4f}" if tv is not None and abs(tv) > 1e-10 and not math.isnan(v1) else "-"
        print(f"  {k:<14} {tv_s:>14} {v0_s:>14} {v1_s:>14} {ratio_10:>10} {ratio_1t:>11}")
