"""Refine discovered coefficient roots against the exact rational side system."""
import argparse
import hashlib
import json
from pathlib import Path
import time

import mpmath as mp
import sympy as sp


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('counter',type=Path)
    parser.add_argument('discovery',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    if args.output.exists(): raise SystemExit('Use a fresh output path')
    started=time.monotonic()
    data=json.loads(args.counter.read_text())
    discovery=json.loads(args.discovery.read_text())
    mp.mp.dps=100
    variables=sp.symbols(data['variables'])
    eta=sp.symbols(data['parameters'])
    all_vars=list(variables)+list(eta)
    def polynomial(terms,variables):
        return sp.Add(*(sp.Rational(n,d)*sp.prod(v**e for v,e in zip(variables,exps)) for n,d,exps in terms))
    equations=sp.Matrix([polynomial(ts,all_vars).subs(dict(zip(eta,map(sp.Rational,data['start_parameters']))))
                         for ts in data['polynomials']])
    f=sp.lambdify(variables,equations,'mpmath',cse=True)
    jacobian=sp.lambdify(variables,equations.jacobian(variables),'mpmath',cse=True)
    matrix=sp.Matrix(6,6,lambda i,j:polynomial(data['matrix'][i][j],variables[:5])/
                     polynomial(data['matrix_denominators'][i][j],variables[:5]))
    a=sp.lambdify(variables[:5],matrix,'mpmath',cse=True)
    def number(text):
        q=sp.Rational(text);return mp.mpf(str(q.p))/mp.mpf(str(q.q))
    scales=list(map(number,data['start_root']))
    moments=list(map(number,data['sample_moments']))
    c=mp.matrix([data['observable_linear_weights']])
    records=[]
    refined_roots=[]
    for index,(re,im) in enumerate(zip(discovery['scaled_roots_real'],discovery['scaled_roots_imag'])):
        seed=[mp.mpc(str(r),str(i))*s for r,i,s in zip(re,im,scales)]
        root=mp.findroot(lambda *xs:tuple(f(*xs)),seed,J=jacobian,tol=mp.mpf('1e-75'),maxsteps=50)
        residual=max(abs(v) for v in f(*root))
        matrix=a(*root[:5])
        rows=[c*matrix**i for i in range(6)]
        obs=mp.matrix([[rows[i][0,j] for j in range(6)] for i in range(6)])
        initial=mp.lu_solve(obs,mp.matrix(moments[:6]))
        jets=[(c*matrix**i*initial)[0] for i in range(12)]
        error=max(abs(u-v)/max(1,abs(v)) for u,v in zip(jets,moments))
        separation=min((max(abs(u-v)/max(1,abs(u),abs(v)) for u,v in zip(root,other))
                        for other in refined_roots),default=mp.inf)
        assert residual<mp.mpf('1e-60') and error<mp.mpf('1e-55') and separation>mp.mpf('1e-40')
        refined_roots.append(root)
        records.append({'index':index,'polynomial_residual':str(residual),'relative_linear_jet_error':str(error),
                        'root_real':[str(mp.re(v)) for v in root],'root_imag':[str(mp.im(v)) for v in root],
                        'initial_state_real':[str(mp.re(v)) for v in initial],
                        'initial_state_imag':[str(mp.im(v)) for v in initial]})
        if (index+1)%20==0:print('Validated roots',index+1,flush=True)
    record={'status':'complete','decimal_precision':mp.mp.dps,'kinetic_roots':len(records),
            'provisional_M':4*len(records),'completeness':'not established by this refinement',
            'scope':'Exact rational coefficient equations at the recorded generic target; twelve reconstructed linear-observable derivatives per root, yielding four fourth-power observation branches.',
            'elapsed_seconds':time.monotonic()-started,'roots':records,
            'input_sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in (args.counter,args.discovery,Path(__file__))}}
    args.output.write_text(json.dumps(record,indent=2)+'\n')
    print('Complete:',len(records),'kinetic roots; provisional M =',record['provisional_M'],flush=True)


if __name__=='__main__':main()
