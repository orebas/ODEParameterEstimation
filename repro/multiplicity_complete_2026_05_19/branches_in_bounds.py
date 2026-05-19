#!/usr/bin/env python3
"""For each multiplicity-≥2 system, check whether the algebraic second branch
satisfies ODEPE's bounds [1e-5, 10.0]. If both branches are in bounds, the
multiplicity in ODEPE's operational subspace is 2; if only one is, it's 1.
"""
import csv, json, math
from pathlib import Path

REPO = Path("/home/orebas/rsync-readonly-PEB")
WAL = REPO / "benchmark_wallaby_2026-05-17"
LB, UB = 1e-5, 10.0
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

def to_floats(r, axes):
    out = {}
    for k in axes:
        try:
            v = float(r[k])
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

def in_bounds(row, axes):
    """All identifiable-axis values in [LB, UB]?"""
    bad = []
    for k in axes:
        if k not in row: continue
        v = row[k]
        if v < LB or v > UB:
            bad.append((k, v))
    return (len(bad) == 0, bad)

with open(WAL / "huge_json.json") as f: j = json.load(f)
truths = {inst['id']: {**inst['state_values'], **inst['parameter_values']} for inst in j['instances']}

print(f"Bounds: [{LB}, {UB}]")
print()
for sys_name in SYSTEMS:
    print("=" * 80)
    print(f"SYSTEM: {sys_name}")
    print("=" * 80)
    n_total = n_in_bounds_alt = n_oob_alt = n_no_alt = 0
    examples_in = []
    examples_oob = []
    for est in ['odepe_v2_polish', 'odepe_v2_nopolish']:
        for cid in sorted(c for c in truths if c.startswith(sys_name + '_')):
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

            d0 = max_rel_dist(rows_f[0], truth_f, id_axes)
            if d0 is None or d0 > 0.1: continue
            n_total += 1

            # Find first row > 0 that's > 30% from row 0 (a true alternate branch)
            alt = None; alt_rank = None
            for i in range(1, len(rows_f)):
                di = max_rel_dist(rows_f[i], rows_f[0], id_axes)
                if di is not None and di > 0.30:
                    alt = rows_f[i]; alt_rank = i; break
            if alt is None:
                n_no_alt += 1; continue

            ok, bad = in_bounds(alt, id_axes)
            if ok:
                n_in_bounds_alt += 1
                if len(examples_in) < 2:
                    examples_in.append((cid, est, alt_rank, alt, truth_f))
            else:
                n_oob_alt += 1
                if len(examples_oob) < 2:
                    examples_oob.append((cid, est, alt_rank, alt, truth_f, bad))

    print(f"  Of {n_total} cells with row 0 near truth:")
    print(f"    {n_in_bounds_alt:>3}  have a distinct alt branch IN BOUNDS")
    print(f"    {n_oob_alt:>3}  have a distinct alt branch OUT OF BOUNDS [1e-5, 10]")
    print(f"    {n_no_alt:>3}  have no distinct alt branch in result.csv")
    print()
    for ex in examples_in:
        cid, est, rank, alt, truth = ex
        print(f"  [IN BOUNDS] {cid} {est} rank {rank}:")
        for k in sorted(alt):
            tv = truth.get(k, 0)
            print(f"    {k:<8} truth={tv:>10.4f}  alt={alt[k]:>10.4f}")
    for ex in examples_oob:
        cid, est, rank, alt, truth, bad = ex
        bad_str = ", ".join(f"{k}={v:.4g}" for k,v in bad)
        print(f"  [OUT OF BOUNDS] {cid} {est} rank {rank}:  ({bad_str})")
        for k in sorted(alt):
            tv = truth.get(k, 0)
            flag = "  <-- OOB" if alt[k] < LB or alt[k] > UB else ""
            print(f"    {k:<8} truth={tv:>10.4f}  alt={alt[k]:>10.4f}{flag}")
    print()
