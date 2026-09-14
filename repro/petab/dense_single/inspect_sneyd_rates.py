"""Inspect the fixed-condition effective rates independently of the Julia estimator."""
import argparse
import hashlib
import json
from pathlib import Path
import random
import re
import time

import sympy as sp
import numpy as np
from scipy.linalg import expm
from sympy.parsing.sympy_parser import parse_expr, standard_transformations, implicit_multiplication_application, rationalize, convert_xor


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('result',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    source=json.loads(args.result.read_text())
    model=source['model_definition']
    state_names=[n.removesuffix('(t)') for n in model['retained_states']]
    param_names=list(model['generating_parameters'])
    symbols={n:sp.Symbol(n) for n in state_names+param_names}
    states=[symbols[n] for n in state_names];params=[symbols[n] for n in param_names]
    rhs=[]
    for equation in model['equations']:
        expression=equation.split(' ~ ',1)[1].replace('//','/')
        for name in state_names: expression=expression.replace(name+'(t)',name)
        rhs.append(parse_expr(expression,local_dict=symbols,
            transformations=standard_transformations+(implicit_multiplication_application,rationalize,convert_xor)))
    A=sp.Matrix(rhs).jacobian(states).applyfunc(sp.cancel)
    assert sp.Matrix(rhs)==A*sp.Matrix(states) or all(sp.cancel(e)==0 for e in sp.Matrix(rhs)-A*sp.Matrix(states))
    assert all(sp.cancel(e)==0 for e in (sp.ones(1,len(states))*A))
    rates=[];edges=[]
    for i,to in enumerate(state_names):
        for j,origin in enumerate(state_names):
            if i==j or A[i,j]==0: continue
            expr=A[i,j]
            found=next((k for k,rate in enumerate(rates) if sp.cancel(rate-expr)==0),None)
            if found is None: found=len(rates);rates.append(expr)
            edges.append({'from':origin,'to':to,'rate_index':found+1})
    J=sp.Matrix(rates).jacobian(params)
    rng=random.Random(20260914)
    ranks=[]
    for _ in range(3):
        values={p:sp.Rational(rng.randint(1,20),rng.randint(1,7)) for p in params}
        ranks.append(J.subs(values).rank())
    record={'source':str(args.result),'source_sha256':hashlib.sha256(args.result.read_bytes()).hexdigest(),
            'condition':source['condition'],'parameters':param_names,'states':state_names,
            'state_equations_linear':True,'state_sum_conserved':True,
            'effective_rate_count':len(rates),'effective_rates':[str(r) for r in rates],
            'edges':edges,'effective_rate_jacobian_rank_at_exact_rational_probes':ranks,
            'parameter_nullity_lower_bound':len(params)-len(rates),
            'scope':'Single fixed input condition. Effective-rate rank is not an output-identifiability certificate.',
            'generating_effective_rates':[float(r.subs({symbols[n]:v for n,v in model['generating_parameters'].items()})) for r in rates]}
    data_path=args.result.with_name('data.json')
    data=json.loads(data_path.read_text())
    nominal={symbols[n]:v for n,v in model['generating_parameters'].items()}
    numeric_A=np.array(A.subs(nominal)).astype(float)
    initial=np.array([model['generating_initial_states'][n+'(t)'] for n in state_names])
    c=np.array([0.9 if n=='IPR_A' else 0.1 if n=='IPR_O' else 0.0 for n in state_names])
    expected=np.array([(c @ expm(numeric_A*t) @ initial)**4 for t in data['times']])
    observed=np.array(data['signals'][0]['values'])
    mismatch=float(np.max(np.abs(expected-observed))/max(np.max(np.abs(observed)),np.finfo(float).eps))
    assert mismatch<1e-7
    record['data_sha256']=hashlib.sha256(data_path.read_bytes()).hexdigest()
    record['matrix_exponential_max_relative_signal_error']=mismatch
    record['generator_eigenvalues']=np.linalg.eigvals(numeric_A).real.tolist()
    args.output.write_text(json.dumps(record,indent=2)+'\n')
    print(json.dumps({k:v for k,v in record.items() if k not in ['effective_rates','edges']},indent=2))


if __name__=='__main__': main()
