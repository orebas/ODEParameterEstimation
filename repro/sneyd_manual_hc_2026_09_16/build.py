#!/usr/bin/env python3
"""Construct Sneyd's stacked prepared jets and eliminate data-determined coefficients.

Exact rational arithmetic throughout. Truth is used only in oracle generation
and a separate validation record; the solver input contains no truth root.
"""
import argparse
import csv
import hashlib
import importlib.util
import json
import random
import time
from pathlib import Path

import sympy as sp

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('prepared', HERE.parent/'sneyd_prepared_jets_2026_09_16/probe.py')
prepared = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepared)


def terms(poly):
    return [{'exponents':list(powers),'numerator':str(c.p),'denominator':str(c.q)}
            for powers,c in poly.terms()]


def linear_solve(rows, rhs):
    a,b=sp.Matrix(rows),sp.Matrix(rhs)
    answer,free=a.gauss_jordan_solve(b)
    assert not free.rows and a*answer==b
    return list(answer)


def rooted_jets(r):
    f1,f2,f3,f4,f5,f6,f7,f8,f9=r
    u=f2+f3;v=f1+f5+f8
    return [f2/10,f2*(9*f5-u-v)/10,
            f2*(u*u+f1*f2+f4*f3+(v-9*f5)*(u+v)-8*f5*f6-9*f5*f7+f8*f9)/10]


def generate_data(model,conditions,theta):
    """Generate jets via matrix powers, independently of the displayed formulas."""
    data=[]
    for condition in conditions:
        c,p=map(sp.Rational,(condition['Ca'],condition['IP3']))
        q,r=prepared.qmatrix(theta,c,p);q=sp.Matrix(q)
        state=sp.Matrix([0,0,0,0,1,0]);z=[]
        for k in range(1,4):
            state=q*state;z.append((9*state[0]+state[3])/10)
        assert z==rooted_jets(r)
        a,b,d=z
        data.append({'id':condition['conditionId'],'c':c,'p':p,'z':z,
                     'y456':[24*a**4,240*a**3*b,480*a**3*d+1080*a*a*b*b]})
    return data


def eliminate(data):
    # phi2 / p = (alpha*c + beta)/(c + delta): all rows participate.
    first=[(row['c'],10*row['z'][0]/row['p']) for row in data]
    alpha,beta,delta=linear_solve([[c,1,-v] for c,v in first],[v*c for c,v in first])

    # q(c) = 10*z''/phi2 + phi2.  q(c)*(c+delta) has a quadratic
    # numerator and a monic linear denominator c+s.
    second=[]
    for row in data:
        c=row['c'];f2=10*row['z'][0]
        w=(10*row['z'][1]/f2+f2)*(c+delta)
        second.append((c,w))
    a2,a1,a0,s=linear_solve([[c*c,c,1,-w] for c,w in second],[w*c for c,w in second])
    assert delta!=s and delta!=0
    b0=a0/delta;gamma=(a1-a2*delta-b0)/(delta-s);b1=a2+gamma

    # At a fixed Ca, the third moment after known terms are removed is affine
    # in phi2. Its slope is phi1. Use all matching-input pairs for validation.
    transformed=[]
    for row in data:
        c=row['c'];f2=10*row['z'][0];f3=gamma*c/(c+delta)
        u=f2+f3;v_minus_9f5=-(b1*c+b0)/(c+s)
        value=10*row['z'][2]/f2-u*u-v_minus_9f5*u
        transformed.append((c,row['p'],f2,value))
    r_values=[]
    for i,(c,p,f2,value) in enumerate(transformed):
        for other_c,other_p,other_f2,other_value in transformed[:i]:
            if c==other_c and p!=other_p:
                phi1=(value-other_value)/(f2-other_f2)
                r_values.append(phi1*(c+s)/(s*(1+alpha*c/beta)))
    assert r_values and len(set(r_values))==1
    r=r_values[0]
    return dict(zip(['alpha','beta','delta','gamma','b1','b0','s','r'],
                    [alpha,beta,delta,gamma,b1,b0,s,r]))


def eta_from_remaining(known,unknown):
    a,b,d,g,b1,b0,s,r=[known[k] for k in ['alpha','beta','delta','gamma','b1','b0','s','r']]
    w,v1,v5,v9=unknown
    return [w,g*w/d,v1,s,(b1+s*a*r/b)/8,v5,b/d,r,a*w/(w-d),a*r/b,-b0/s-r,v9]


def reduced_system(data,known):
    w,v1,v5,v9=variables=sp.symbols('L1 V1 V5 k_minus_3')
    a,b,d,g,b1,b0,s,r=[known[k] for k in ['alpha','beta','delta','gamma','b1','b0','s','r']]
    polynomials=[];denominators=[]
    for row in data:
        c=row['c'];f2=10*row['z'][0];f3=g*c/(c+d)
        f1=s*r*(1+a*c/b)/(c+s)
        f5=c*(b1+s*a*r/b)/(8*(c+s));f8=(-b0-s*r)/(c+s)
        u=f2+f3;v=f1+f5+f8
        target=10*row['z'][2]/f2-u*u-f1*f2-(v-9*f5)*(u+v)
        expression=(c+w)*(f3*v1+f8*v9-target)-f5*w*(8*v5+9*g*c/d)
        polynomials.append(sp.Poly(expression,*variables))
        denominators.append(c+w)
    # The distinct-IP3 third-derivative information was used to determine r;
    # remaining equations at a shared Ca must now agree exactly.
    for i,row in enumerate(data):
        for j,other in enumerate(data[:i]):
            if row['c']==other['c']:
                assert polynomials[i]==polynomials[j]
    unique=[];indices=[]
    for i,poly in enumerate(polynomials):
        if poly not in unique:unique.append(poly);indices.append(i)
    assert len(unique)==6
    return variables,polynomials,indices,denominators


def export_case(label,model,conditions,theta,out):
    started=time.monotonic();out.mkdir(parents=True,exist_ok=True)
    data=generate_data(model,conditions,theta)
    # Recover the rooted jets from original quartic derivatives on the
    # physical phi2>0 branch, without reading the rooted values.
    quartic_data=[]
    for row in data:
        y4,y5,y6=row['y456'];fourth=y4/24
        numerator,exact_n=sp.integer_nthroot(fourth.p,4)
        denominator,exact_d=sp.integer_nthroot(fourth.q,4)
        assert exact_n and exact_d
        a=sp.Rational(numerator,denominator);b=y5/(240*a**3)
        d=(y6-1080*a*a*b*b)/(480*a**3)
        assert [a,b,d]==row['z']
        quartic_data.append(row | {'z':[a,b,d]})
    known=eliminate(data)
    assert eliminate(quartic_data)==known
    variables,polynomials,indices,denominators=reduced_system(data,known)
    eta=[v.subs(dict(zip(model['theta'],theta))) for v in model['combinations']]
    truth=[eta[0],eta[2],eta[5],eta[11]]
    assert eta_from_remaining(known,truth)==eta
    assert all(poly.eval(dict(zip(variables,truth)))==0 for poly in polynomials)

    # A square subset is selected by exact generic Jacobian rank, not by the
    # generating parameter values. All six distinct-Ca equations are retained.
    probe=dict(zip(variables,[sp.Rational(2),sp.Rational(3),sp.Rational(5),sp.Rational(7)]))
    selected=[];jac=[]
    for i in indices:
        row=[sp.diff(polynomials[i].as_expr(),v).subs(probe) for v in variables]
        if sp.Matrix(jac+[row]).rank()>len(jac):
            selected.append(i);jac.append(row)
        if len(selected)==4:break
    assert len(selected)==4
    normalized=[];scales=[]
    for poly in polynomials:
        scale=max(abs(c) for c in poly.coeffs());scales.append(scale)
        normalized.append(sp.Poly(poly.as_expr()/scale,*variables))
    # Exact constant row operations on the complete six-condition support.
    # This preserves the generated ideal; no truth values enter this step.
    monomials=sorted({powers for poly in polynomials for powers,_ in poly.terms()},reverse=True)
    coefficient_matrix=sp.Matrix([[poly.coeff_monomial(powers) for powers in monomials] for poly in polynomials])
    rref,pivots=coefficient_matrix.rref()
    reduced=[]
    for j in range(len(pivots)):
        expression=sum(rref[j,k]*sp.prod(v**e for v,e in zip(variables,powers)) for k,powers in enumerate(monomials))
        poly=sp.Poly(expression,*variables)
        reduced.append(sp.Poly(expression/max(map(abs,poly.coeffs())),*variables))
    selected_reduced=[];jac=[]
    for i,poly in enumerate(reduced):
        row=[sp.diff(poly.as_expr(),v).subs(probe) for v in variables]
        if sp.Matrix(jac+[row]).rank()>len(jac):
            selected_reduced.append(i);jac.append(row)
        if len(selected_reduced)==4:break
    assert len(selected_reduced)==4
    system={'label':label,'unknowns':list(map(str,variables)),
            'scope':'All 27 prepared rooted jet equations; exact data-driven elimination leaves 9 quadratic rows (6 distinct). No truth root is supplied.',
            'polynomials':[terms(p) for p in normalized],
            'row_reduced_polynomials':[terms(p) for p in reduced],
            'row_reduced_selected_rows':selected_reduced,
            'coefficient_matrix_rank':len(pivots),
            'quartic_physical_branch_jets_equal_rooted':True,
            'row_scales':list(map(str,scales)),
            'selected_rows':selected,'distinct_rows':indices,
            'data':[{k:([str(v) for v in value] if isinstance(value,list) else str(value)) for k,value in row.items()} for row in data],
            'data_determined_combinations':{k:str(v) for k,v in known.items()},
            'excluded_denominators':['L1','L1-delta']+[str(v) for v in denominators],
            'dimensions':{'stacked_rooted_equations':27,'original_kinetic_parameters':14,'quotient_unknowns':12,
                          'remaining_equations':len(polynomials),'distinct_remaining_equations':6,
                          'remaining_unknowns':4,'selected_degrees':[polynomials[i].total_degree() for i in selected],
                          'terms_per_equation':[len(p.terms()) for p in polynomials]},
            'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    (out/'system.json').write_text(json.dumps(system,indent=2)+'\n')
    reference={'theta':dict(zip(prepared.PARAMETERS,map(str,theta))),
               'eta_names':list(map(str,model['eta'])),'eta':list(map(str,eta)),
               'remaining_truth':list(map(str,truth)),'generation_seconds':time.monotonic()-started}
    (out/'oracle.json').write_text(json.dumps(reference,indent=2)+'\n')
    print(label,'built',system['dimensions'],'selected',selected,flush=True)
    print('remaining truth (validation only)',list(map(float,truth)),flush=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model-dir',type=Path,required=True)
    parser.add_argument('--output',type=Path,default=HERE/'evidence')
    args=parser.parse_args()
    model=prepared.validate_sbml(args.model_dir)
    conditions=list(csv.DictReader((args.model_dir/'experimentalCondition_Sneyd_PNAS2002.tsv').open(),delimiter='\t'))
    rng=random.Random(1)
    export_case('moderate',model,conditions,list(map(sp.Rational,[rng.randrange(2,100) for _ in range(14)])),args.output/'moderate')
    export_case('nominal',model,conditions,[sp.Rational(model['nominal'][p]) for p in prepared.PARAMETERS],args.output/'nominal')


if __name__=='__main__':main()
