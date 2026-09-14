"""Generate independent, exact synthetic roots for an HC tracking diagnostic."""
import argparse
import hashlib
import json
from pathlib import Path
import random

import sympy as sp
from sympy.polys.domains import QQ
from sympy.polys.rings import ring


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    source=json.loads(args.source.read_text())
    names=source['variables'];symbols={n:sp.Symbol(n) for n in names}
    R,*gens=ring(names,QQ)
    polys=[R.from_expr(sp.sympify(e.replace('^','**').replace('//','/'),locals=symbols)) for e in source['equations']]
    selected=[polys[i-1] for i in source['selected_indices']]
    data_indices={j for j,n in enumerate(names) if n.startswith('dense_y')}
    unknown_indices=set(range(len(names)))-data_indices
    physical={j for j in unknown_indices if int(names[j].rsplit('_',1)[1])==0}
    supports=[{j for m in e for j,k in enumerate(m) if k} for e in polys]
    def lift(physical_values):
        assigned=set(physical);values=[QQ.zero for _ in names]
        for j,v in physical_values.items():values[j]=v
        while len(assigned)<len(names):
            before=len(assigned)
            for e,support in zip(polys,supports):
                missing=support-assigned
                if len(missing)!=1:continue
                j=next(iter(missing))
                terms=[(m,c) for m,c in e.items() if m[j]]
                if len(terms)!=1 or sum(terms[0][0])!=1:continue
                value=e.evaluate(list(zip(gens,values)))
                values[j]=-value/terms[0][1];assigned.add(j)
            if len(assigned)==before:raise RuntimeError('Unresolved jet definitions: '+str([names[j] for j in set(range(len(names)))-assigned]))
        assert all(e.evaluate(list(zip(gens,values)))==0 for e in polys)
        return values
    rng=random.Random(20260914)
    starting={j:QQ(rng.randint(3,9),10) for j in sorted(physical)}
    nearby={j:v+QQ(rng.choice([-2,-1,1,2]),1000) for j,v in starting.items()}
    distant={j:QQ(rng.randint(3,9),10) for j in sorted(physical)}
    used={j for e in selected for m in e for j,k in enumerate(m) if k}
    data_used=sorted(used&data_indices);unknowns=sorted(unknown_indices)
    cases=[]
    for name,values in [('start',starting),('nearby',nearby),('distant',distant)]:
        lifted=lift(values)
        cases.append({'name':name,'root':[float(lifted[j]) for j in unknowns],
                      'data':[float(lifted[j]) for j in data_used],
                      'all_data':[float(lifted[j]) for j in sorted(data_indices)],
                      'exact_root':[str(lifted[j]) for j in unknowns],
                      'all_88_equations_exactly_zero':True})
    record={'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest(),'seed':20260914,
            'scope':'Solver diagnostic; sampled physical coordinates and forward-generated exact jets. No published parameter values or fitted observations used.',
            'equations':[str(e) for e in selected],'all_equations':[str(e) for e in polys],
            'unknowns':[names[j] for j in unknowns],'data_variables':[names[j] for j in data_used],
            'all_data_variables':[names[j] for j in sorted(data_indices)],'physical_indices':[unknowns.index(j)+1 for j in sorted(physical)],'cases':cases}
    args.output.write_text(json.dumps(record,indent=2)+'\n')
    print('Verified three exact roots of all 88 equations;',len(unknowns),'unknowns;',len(data_used),'selected data values.')


if __name__=='__main__':main()
