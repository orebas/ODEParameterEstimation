#!/usr/bin/env python3
"""Validate returned HC roots against all equations and the independent SBML oracle."""
import argparse
import hashlib
import json
from pathlib import Path

import mpmath as mp
import sympy as sp

import build


def unpack(rows,variables):
    return [sum(sp.Rational(t['numerator'])/sp.Rational(t['denominator'])*sp.prod(v**e for v,e in zip(variables,t['exponents'])) for t in row) for row in rows]


def exact_recovery(equations,variables):
    """Repeatedly use a linear equation in one remaining variable.

    Unlike an oracle check, this function receives no generating parameters.
    Its successful trace also proves uniqueness of this reduced finite system.
    """
    values={};trace=[]
    while len(values)<len(variables):
        previous=len(values)
        for equation in equations:
            current=sp.expand(equation.subs(values))
            free=current.free_symbols
            if len(free)==1:
                variable=next(iter(free));poly=sp.Poly(current,variable)
                if poly.degree()==1:
                    value=-poly.nth(0)/poly.nth(1)
                    values[variable]=value
                    trace.append({'variable':str(variable),'linear_equation':str(current),'value':str(value)})
        assert len(values)>previous,'Elimination stopped before a unique solution'
    assert all(sp.cancel(e.subs(values))==0 for e in equations)
    return [values[v] for v in variables],trace


def run(case,model,hc_name='hc.json',output_name='validation.json'):
    mp.mp.dps=100
    system=json.loads((case/'system.json').read_text())
    oracle=json.loads((case/'oracle.json').read_text())
    hc=json.loads((case/hc_name).read_text())
    assert hc['status']=='complete','HC worker has not completed this case'
    assert hc['system_sha256']==hashlib.sha256((case/'system.json').read_bytes()).hexdigest()
    variables=sp.symbols(' '.join(system['unknowns']))
    equations=unpack(system['polynomials'],variables)
    reduced=unpack(system['row_reduced_polynomials'],variables)
    recovered,trace=exact_recovery(reduced,variables)
    known={k:sp.Rational(v) for k,v in system['data_determined_combinations'].items()}
    eta=build.eta_from_remaining(known,recovered)
    assert eta==list(map(sp.Rational,oracle['eta']))
    assert all(e.subs(dict(zip(variables,recovered)))==0 for e in equations)
    truth=list(map(sp.Rational,oracle['remaining_truth']))
    assert recovered==truth
    assert all(v>0 for v in eta)
    q_oracle=model['reduced_q'].subs(dict(zip(model['eta'],eta)))
    for row in system['data']:
        q=q_oracle.subs({model['c']:sp.Rational(row['c']),model['p']:sp.Rational(row['p'])})
        state=sp.Matrix([0,0,0,0,1,0])
        for target in row['z']:
            state=q*state
            assert (9*state[0]+state[3])/10==sp.Rational(target)
    selected=system['row_reduced_selected_rows']
    functions=sp.lambdify(variables,[reduced[i] for i in selected],modules='mpmath')
    all_equations=sp.lambdify(variables,equations,modules='mpmath')
    def real(x):return mp.mpf(str(x.p))/mp.mpf(str(x.q))
    expected=list(map(real,truth))
    eta_fn=sp.lambdify(variables,build.eta_from_remaining(known,list(variables)),modules='mpmath')
    exact_eta=list(map(real,eta))
    def relative_errors(a,b):return [abs(x-y)/max(abs(y),mp.mpf('1e-100')) for x,y in zip(a,b)]
    report={'exact_recovery':list(map(str,recovered)),
            'exact_recovery_trace':trace,'all_12_combinations_exact':True,
            'all_27_rooted_constraints_exact':True,
            'quartic_positive_branch_equivalent':system['quartic_physical_branch_jets_equal_rooted'],
            'hc_sha256':hashlib.sha256((case/hc_name).read_bytes()).hexdigest(),
            'runs':[]}
    for hc_run in hc['runs']:
        record={'variant':hc_run['variant'],'start_system':hc_run['start_system'],'roots':[]}
        for reals,imags in zip(hc_run.get('roots_real',[]),hc_run.get('roots_imag',[])):
            start=[mp.mpc(str(a),str(b)) for a,b in zip(reals,imags)]
            root={'hc_max_relative_parameter_error':mp.nstr(max(relative_errors(start,expected)),20),
                  'hc_full_reduced_residual_inf':mp.nstr(max(map(abs,all_equations(*start))),20),
                  'hc_max_imaginary_part':mp.nstr(max(abs(v.imag) for v in start),20),
                  'hc_relative_truth_error_below_1e_minus_8':max(relative_errors(start,expected))<mp.mpf('1e-8'),
                  'refinement_scope':'Newton on the full-data row-reduced equations, not necessarily the original square subsystem'}
            initial_eta=list(eta_fn(*start))
            root['hc_all_12_max_relative_error']=mp.nstr(max(relative_errors(initial_eta,exact_eta)),20)
            root['hc_12_combinations_positive_and_real_at_1e_minus_8']=all(v.real>0 and abs(v.imag)<mp.mpf('1e-8')*max(1,abs(v.real)) for v in initial_eta)
            try:
                refined=mp.findroot(functions,tuple(start),tol=mp.mpf('1e-85'),maxsteps=30)
                root['refined_max_relative_parameter_error']=mp.nstr(max(relative_errors(refined,expected)),20)
                root['refined_full_reduced_residual_inf']=mp.nstr(max(map(abs,all_equations(*refined))),20)
                root['refined_values_real']=[mp.nstr(v.real,60) for v in refined]
                root['refined_values_imag']=[mp.nstr(v.imag,10) for v in refined]
                # Validate the unreduced prepared jets through Q^k, using the
                # independently parsed SBML-equivalent 12-combination model.
                estimated_eta=list(eta_fn(*refined))
                root['refined_all_12_max_relative_error']=mp.nstr(max(relative_errors(estimated_eta,exact_eta)),20)
                max_rates=mp.mpf(0);max_jets=mp.mpf(0)
                for row in system['data']:
                    c,p=map(sp.Rational,(row['c'],row['p']))
                    q_symbolic=model['reduced_q'].subs({model['c']:c,model['p']:p})
                    q_fn=sp.lambdify(model['eta'],q_symbolic,modules='mpmath')
                    q=q_fn(*estimated_eta);q_true=q_fn(*exact_eta)
                    for a,b in zip(q,q_true):
                        if b:max_rates=max(max_rates,abs(a-b)/abs(b))
                    state=mp.matrix([0,0,0,0,1,0])
                    for target in row['z']:
                        state=q*state;value=(9*state[0]+state[3])/10
                        target=real(sp.Rational(target))
                        max_jets=max(max_jets,abs(value-target)/max(abs(target),mp.mpf('1e-100')))
                root['refined_all_condition_generator_max_relative_error']=mp.nstr(max_rates,20)
                root['refined_all_27_rooted_jets_max_relative_error']=mp.nstr(max_jets,20)
            except Exception as err:
                root['refinement_error']=repr(err)
            record['roots'].append(root)
        report['runs'].append(record)
    (case/output_name).write_text(json.dumps(report,indent=2)+'\n')
    print(case.name,'exact recovery of all 12 combinations; HC checks:',flush=True)
    for row in report['runs']:
        print(row['variant'],row['start_system'],[(r['hc_max_relative_parameter_error'],r.get('refined_all_12_max_relative_error'),r.get('refinement_error')) for r in row['roots']],flush=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model-dir',type=Path,required=True)
    parser.add_argument('--evidence',type=Path,default=build.HERE/'evidence')
    args=parser.parse_args();model=build.prepared.validate_sbml(args.model_dir)
    for label in ('moderate','nominal'):
        case=args.evidence/label;run(case,model)
        if (case/'hc_float.json').exists():
            run(case,model,'hc_float.json','validation_float.json')


if __name__=='__main__':main()
