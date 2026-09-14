"""Bounded exact elimination of auxiliary jets in the retained Fujita SIAN basis.

This diagnostic changes no production policy. Every eliminated variable has an
explicit defining equation with a nonzero constant coefficient. No parameter
value is fixed and no division by an unknown is introduced.
"""
import argparse
import hashlib
import json
from pathlib import Path
import random
import re
import time

import sympy as sp
from sympy.polys.domains import QQ
from sympy.polys.rings import ring


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--max-equation-terms', type=int, default=5000)
    parser.add_argument('--max-total-terms', type=int, default=50000)
    parser.add_argument('--seconds', type=float, default=180)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    source = json.loads(args.source.read_text())
    names = source['variables']
    symbols = {n: sp.Symbol(n) for n in names}
    R, *gens = ring(names, QQ)
    polys = [(i, R.from_expr(sp.sympify(source['equations'][i-1].replace('^','**').replace('//','/'), locals=symbols)))
             for i in source['selected_indices']]
    original = list(polys)
    # Cross-check the independently retained support report, including exact
    # rational coefficients (Julia's // must not become Python floor division).
    support_path=args.source.with_name(args.source.stem+'_support.json')
    support=json.loads(support_path.read_text())
    reference={row['index']:row['expression'] for row in support['rows']}
    assert all(p==R.from_expr(sp.sympify(re.sub(r'\bdata_y', 'dense_y', reference[i]), locals=symbols))
               for i,p in original)
    unknown_indices = {j for j,n in enumerate(names) if not n.startswith('dense_y')}
    data_indices = set(range(len(names))) - unknown_indices
    jet_indices = {j for j in unknown_indices if int(names[j].rsplit('_',1)[1]) > 0}
    eliminated = []
    started = time.monotonic()
    record = {'status':'reducing', 'source':str(args.source),
              'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest(),
              'sympy_version':sp.__version__, 'basis':'Retained SIAN selected_indices, not the uncaptured interrupted noise-frontier basis',
              'independent_input_polynomial_check':True,
              'max_equation_terms':args.max_equation_terms, 'max_total_terms':args.max_total_terms,
              'steps':[], 'snapshots':[]}
    def stats():
        terms = [len(p) for _,p in polys]
        degrees = [max((sum(m[j] for j in unknown_indices) for m in p), default=0) for _,p in polys]
        return {'equations':len(polys), 'unknowns':len(unknown_indices),
                'total_terms':sum(terms), 'max_equation_terms':max(terms,default=0),
                'max_degree':max(degrees,default=0), 'seconds':time.monotonic()-started}
    def checkpoint():
        record['current']=stats()
        temp=args.output/'result.json.tmp'
        temp.write_text(json.dumps(record,indent=2)+'\n')
        temp.replace(args.output/'result.json')
    def snapshot():
        stat=stats()
        filename=f"system_{len(unknown_indices):02d}.json"
        used={j for _,p in polys for mon in p for j,e in enumerate(mon) if e}
        payload={**stat,'equations':[str(p) for _,p in polys],
                 'source_equation_indices':[i for i,_ in polys],
                 'unknowns':[names[j] for j in sorted(unknown_indices)],
                 'data_variables':[names[j] for j in sorted(data_indices & used)],
                 'reconstruction':[{'variable':names[j],'equation_index':i,'expression':str(f)} for j,i,f in eliminated]}
        (args.output/filename).write_text(json.dumps(payload,indent=2)+'\n')
        record['snapshots'].append({'file':filename,**stat})
        checkpoint()
    snapshot()
    while jet_indices:
        if time.monotonic()-started > args.seconds:
            record['status']='time_budget'; break
        candidates=[]
        for ei,(source_i,e) in enumerate(polys):
            for mon,c in e.items():
                if sum(mon)!=1: continue
                j=mon.index(1)
                if j not in jet_indices or sum(bool(m[j]) for m in e)!=1: continue
                f=gens[j]-e/c
                prediction=[]
                for qi,(_,q) in enumerate(polys):
                    if qi==ei: continue
                    prediction.append(sum(min(args.max_equation_terms+1,len(f)**m[j]) if m[j] else 1 for m in q))
                worst=max(prediction,default=0)
                total=sum(prediction)
                if worst<=args.max_equation_terms and total<=args.max_total_terms:
                    candidates.append(((worst,total,len(f),-int(names[j].rsplit('_',1)[1]),names[j]),ei,j,f))
        if not candidates:
            record['status']='support_budget_or_no_constant_pivot'; break
        _,ei,j,f=min(candidates,key=lambda c:c[0])
        source_i=polys[ei][0]
        step_start=time.monotonic()
        polys=[(i,p.compose(gens[j],f)) for k,(i,p) in enumerate(polys) if k!=ei]
        unknown_indices.remove(j)
        jet_indices.remove(j)
        eliminated.append((j,source_i,f))
        row={'variable':names[j],'defining_equation':source_i,'replacement_terms':len(f),
             'substitution_seconds':time.monotonic()-step_start,**stats()}
        record['steps'].append(row)
        print(json.dumps(row),flush=True)
        checkpoint()
        if len(unknown_indices) in (75,65,55,45,35,25,23): snapshot()
    else:
        record['status']='all_auxiliary_jets_eliminated'
    if record['snapshots'][-1]['unknowns']!=len(unknown_indices): snapshot()
    # Independent exact-rational substitution check of the original equations
    # after lifting three assignments from the retained coordinates.
    rng=random.Random(20260914)
    checks=[]
    for probe in range(3):
        values=[QQ(rng.randint(1,11),20) for _ in names]
        for j,_,f in reversed(eliminated):
            values[j]=f.evaluate(list(zip(gens,values)))
        final_values={i:p.evaluate(list(zip(gens,values))) for i,p in polys}
        differences=[p.evaluate(list(zip(gens,values)))-final_values.get(i,QQ.zero) for i,p in original]
        checks.append(all(v==0 for v in differences))
    record['exact_rational_lift_checks']=checks
    assert all(checks)
    checkpoint()
    print('FINISHED',record['status'],record['current'],flush=True)


if __name__=='__main__':
    main()
