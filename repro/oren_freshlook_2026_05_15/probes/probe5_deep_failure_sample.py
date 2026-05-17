#!/usr/bin/env python3
"""Probe 5: Sample 5 of the 8% deep-failure cells, characterize each.

Step 1: from 300-cell sample, find cells where min(oracle over rows) > 0.5.
Step 2: stratify by system family; sample 5 cells across families.
Step 3: per cell, dump diagnostic info for a written-up mini-report.

We don't compute sensitivity here — that goes in the per-cell .md report
(can be added later as needed).
"""
import json, csv, random, collections
from pathlib import Path

ROOT14 = Path('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run')
HUGE = {e['id']: e for e in json.load(open('/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/huge_json.json'))['instances']}

def rel_err(v, t): return abs(v - t) / max(abs(t), 1.0)
def fl(s):
    try: return float(s)
    except: return float('inf')

def is_neg1(r): return r['polish_source_hc_idx'] in ('-1.0', '-1')

def analyze_cell(cell):
    t = HUGE.get(cell)
    if not t: return None
    csvp = ROOT14 / cell / 'result.csv'
    if not csvp.exists(): return None
    rows = list(csv.DictReader(open(csvp)))
    if not rows: return None
    meta = json.load(open(ROOT14 / cell / 'odepe_metadata.json'))
    unident = meta.get('best', {}).get('all_unidentifiable', [])
    truth_map = {**{k: v for k, v in t['parameter_values'].items()},
                 **{f'{k}(t)': v for k, v in t['state_values'].items()}}
    cmp_cols = [c for c in rows[0]
                if c not in ('err', 'post_polish_error', 'branch_size', 'polish_source_hc_idx')
                and not c.startswith('_trfn_') and c in truth_map and c not in unident]
    if not cmp_cols: return None
    def oracle(r): return max(rel_err(fl(r[c]), truth_map[c]) for c in cmp_cols)
    oracles = [oracle(r) for r in rows]
    errs = [fl(r['err']) for r in rows]
    return {
        'cell': cell,
        'system': t['name'],
        'noise': cell.split('_')[-1],
        'min_oracle': min(oracles),
        'min_oracle_idx': oracles.index(min(oracles)),
        'rank1_oracle': oracles[0],
        'rank1_err': errs[0],
        'err_min': min(errs),
        'err_max': max(errs),
        'n_rows': len(rows),
        'unident': unident,
        'best_meta': meta['best'],
        'raw_count': meta['raw_count'],
        'cmp_cols': cmp_cols,
        'rows': rows,
        'oracles': oracles,
        'errs': errs,
        'n_neg1': sum(1 for r in rows if is_neg1(r)),
        'truth_map': truth_map,
    }

def main():
    random.seed(0)
    cells = sorted([d.name for d in ROOT14.iterdir() if d.is_dir() and (d / 'result.csv').exists()])
    sample = random.sample(cells, 300)

    # Find deep failures
    deep = []
    for cell in sample:
        r = analyze_cell(cell)
        if r is None: continue
        if r['min_oracle'] > 0.5:
            deep.append(r)

    print(f"# Probe 5: deep-failure cells")
    print(f"# Sample size: 300; deep failures (min oracle > 0.5): {len(deep)}")
    print()

    by_system = collections.Counter(r['system'] for r in deep)
    print(f"# Deep failures by system family:")
    for sys, n in by_system.most_common():
        print(f"  {sys}: {n}")
    print()

    # By noise level
    by_noise = collections.Counter(r['noise'] for r in deep)
    print(f"# Deep failures by noise level:")
    for n_lvl, n in by_noise.most_common():
        print(f"  {n_lvl}: {n}")
    print()

    # Sample 5: one from each of the 5 most common systems
    sampled = []
    seen_systems = set()
    for r in deep:
        if r['system'] in seen_systems:
            continue
        sampled.append(r)
        seen_systems.add(r['system'])
        if len(sampled) >= 5:
            break

    print(f"# Sampled {len(sampled)} cells (one per system, top families):")
    for r in sampled:
        print(f"  {r['cell']} (system={r['system']}, noise={r['noise']})")
    print()

    # For each sample, dump diagnostic info to a per-cell file
    out_dir = Path(__file__).parent / 'probe5_cell_diagnostics'
    out_dir.mkdir(exist_ok=True)

    for r in sampled:
        cell = r['cell']
        path = out_dir / f'{cell}.md'
        with open(path, 'w') as f:
            t = HUGE[cell]
            f.write(f"# Deep-failure characterization: {cell}\n\n")
            f.write(f"System: **{r['system']}**  | Noise: **{r['noise']}**\n\n")
            f.write(f"## ODE\n\n")
            f.write(f"State variables: {t['state_variables']}\n\n")
            f.write(f"Parameters: {t['parameter_variables']}\n\n")
            f.write(f"Observables:\n```\n")
            for k, v in t['measurements'].items():
                f.write(f"  {k} = {v}\n")
            f.write(f"```\n\n")
            f.write(f"ODE system:\n```\n")
            for k, v in t['ode_system'].items():
                f.write(f"  d{k}/dt = {v}\n")
            f.write(f"```\n\n")
            f.write(f"Truth:\n")
            f.write(f"- params: {t['parameter_values']}\n")
            f.write(f"- ICs: {t['state_values']}\n\n")
            f.write(f"## Result.csv summary\n\n")
            f.write(f"- rows: {r['n_rows']}\n")
            f.write(f"- err range: [{r['err_min']:.4g}, {r['err_max']:.4g}]\n")
            f.write(f"- oracle range: [{r['min_oracle']:.3g}, {max(r['oracles']):.3g}]\n")
            f.write(f"- rank-1 oracle: {r['rank1_oracle']:.3g}\n")
            f.write(f"- best-oracle row: rank {r['min_oracle_idx']+1}, oracle {r['min_oracle']:.3g}\n")
            f.write(f"- polish_source_hc_idx == -1: {r['n_neg1']} of {r['n_rows']}\n")
            f.write(f"- SIAN non_identifiable: {t['non_identifiable']}\n")
            f.write(f"- ODEPE all_unidentifiable: {r['unident']}\n\n")
            f.write(f"## Best (from metadata)\n\n")
            b = r['best_meta']
            f.write(f"- raw_count: {r['raw_count']}\n")
            f.write(f"- primary_method: {b['primary_method']}\n")
            f.write(f"- source_type: {b['source_type']}\n")
            f.write(f"- aggregation_strategy: {b['aggregation_strategy']}\n")
            f.write(f"- rescue_path: {b['rescue_path']}\n")
            f.write(f"- was_terminal_fallback: {b['was_terminal_fallback']}\n")
            f.write(f"- notes: {b['notes']}\n")
            f.write(f"- best params: {b['parameters']}\n")
            f.write(f"- best states (non-trfn): {dict((k, v) for k, v in b['states'].items() if not k.startswith('_trfn_'))}\n\n")
            f.write(f"## Per-axis status at the best-oracle row (rank {r['min_oracle_idx']+1})\n\n")
            best_row = r['rows'][r['min_oracle_idx']]
            f.write(f"| axis | estimate | truth | rel_err |\n|---|---|---|---|\n")
            for c in r['cmp_cols']:
                est = fl(best_row[c])
                tr = r['truth_map'][c]
                f.write(f"| {c} | {est:.5g} | {tr:.5g} | {rel_err(est, tr):.3g} |\n")
            f.write(f"\n## Failure mode classification (TBD — fill in via inspection)\n\n")
            f.write(f"_To be filled in by inspection. Candidate categories:_\n")
            f.write(f"- column-scaling / stiff ODE pathology (brusselator pattern)\n")
            f.write(f"- HC missed truth basin entirely (no real solution in pool)\n")
            f.write(f"- polish convergence to wrong basin from all starts\n")
            f.write(f"- aggregate-noise overfit with no HC-source truth-near\n")
            f.write(f"- structural unidentifiability that wasn't pegged\n")
        print(f"  wrote {path}")

    # Also write a top-level summary CSV
    with open(out_dir / 'sampled_cells.csv', 'w') as f:
        f.write("cell,system,noise,min_oracle,rank1_oracle,err_min,err_max,raw_count,source_type\n")
        for r in sampled:
            b = r['best_meta']
            f.write(f"{r['cell']},{r['system']},{r['noise']},{r['min_oracle']},{r['rank1_oracle']},{r['err_min']},{r['err_max']},{r['raw_count']},{b['source_type']}\n")

    # Print summary table
    print()
    print(f"# Quick characterization:")
    print(f"  {'cell':<40s} {'min_or':>8s} {'r1_or':>8s} {'raw':>6s} {'source':>20s} {'best_unident':>30s}")
    for r in sampled:
        b = r['best_meta']
        print(f"  {r['cell']:<40s} {r['min_oracle']:>8.3g} {r['rank1_oracle']:>8.3g} {r['raw_count']:>6d} {b['source_type']:>20s} {str(r['unident'])[:30]:>30s}")

if __name__ == '__main__':
    main()
