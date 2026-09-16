#!/usr/bin/env python3
"""Export all 27 prepared Sneyd jets in 12 variables, without data elimination.

Numerators/denominators are exact, and the derivative targets stay separate.
The SBML and independently generated matrix-power jets are checked first.
"""
import argparse
import csv
import functools
import hashlib
import importlib.util
import json
import time
from pathlib import Path

import sympy as sp

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "manual", HERE.parent / "sneyd_manual_hc_2026_09_16/build.py")
manual = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manual)


@functools.cache
def polynomial_jets(eta,c,p):
    """Clear the known jet denominators by polynomial arithmetic, no data use."""
    L1,U1,V1,L5,U5,V5,k2,km2,l4,lm4,k3,km3 = [sp.Poly(v,*eta,domain=sp.QQ) for v in eta]
    h=c*(L1*k2*lm4+km2*l4)+L1*km2*l4
    g=c+L5; f=c+L1
    n1=L5*(c*lm4+km2); n2=p*L1*l4*k2*(c*lm4+km2)
    n3=c*U1*km2*l4; n5=c*U5; n6=L1*V5; n7=c*U1; n8=L5*k3
    nu=n2+n3; nv=n1+n5+n8
    pairs=[(n2,10*h), (n2*(9*n5*h-nu*g-nv*h),10*h**2*g),
           (n2*(nu**2*g**2*f+n1*n2*h*g*f+V1*n3*h*g**2*f+
                 (nv-9*n5)*(nu*g+nv*h)*h*f-(8*n5*n6+9*n5*n7)*h**2*g+
                 n8*km3*h**2*g*f),10*h**3*g**2*f)]
    result=[]
    for n,d in pairs:
        # Poly.cancel avoids expanding a tower of nested rational expressions.
        coefficient,n,d=n.cancel(d)
        result.append((n.mul_ground(coefficient),d))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=HERE / "evidence/system.json")
    args = parser.parse_args()
    started = time.monotonic()
    model = manual.prepared.validate_sbml(args.model_dir)
    conditions = list(csv.DictReader(
        (args.model_dir / "experimentalCondition_Sneyd_PNAS2002.tsv").open(), delimiter="\t"))
    eta = model["eta"]
    L1,U1,V1,L5,U5,V5,k2,km2,l4,lm4,k3,km3 = eta
    L3 = km2*l4/(k2*lm4)
    c,p = model["c"],model["p"]
    rates = [(c*lm4+km2)/(c/L5+1), p*(c*l4+L3*k2)/(c*(1+L3/L1)+L3),
             c*U1/(c*(1+L1/L3)+L1), V1, c*U5/(c+L5), L1*V5/(c+L1),
             c*U1/(c+L1), L5*k3/(c+L5), km3]
    jets = manual.rooted_jets(rates)
    rows = []
    for i, condition in enumerate(conditions):
        inputs = {c:sp.Rational(condition["Ca"]), p:sp.Rational(condition["IP3"])}
        for order, (n,d) in enumerate(polynomial_jets(eta,inputs[c],inputs[p]), 1):
            row = {"index":len(rows)+1, "condition_index":i+1,
                   "condition_id":condition["conditionId"], "Ca":str(inputs[c]), "IP3":str(inputs[p]),
                   "order":order, "numerator":manual.terms(n), "denominator":manual.terms(d),
                   "numerator_terms":len(n.terms()), "denominator_terms":len(d.terms()),
                   "solve_degree":max(n.total_degree(),d.total_degree()),
                   "terms_after_data_substitution":len(set(n.monoms()) | set(d.monoms()))}
            rows.append(row)
            print("ROW",row["index"],"order",order,"degree",row["solve_degree"],
                  "terms",row["terms_after_data_substitution"],flush=True)

    cases = {}
    for label in ("moderate", "nominal"):
        old = HERE.parent / "sneyd_manual_hc_2026_09_16/evidence" / label
        oracle = json.loads((old / "oracle.json").read_text())
        theta = [sp.Rational(oracle["theta"][name]) for name in manual.prepared.PARAMETERS]
        actual = manual.generate_data(model,conditions,theta)
        truth = [sp.Rational(s) for s in oracle["eta"]]
        subs = dict(zip(eta,truth))
        targets = []
        for row in rows:
            value = actual[row["condition_index"]-1]["z"][row["order"]-1]
            expr = jets[row["order"]-1].subs({c:sp.Rational(row["Ca"]),p:sp.Rational(row["IP3"])})
            assert expr.subs(subs) == value
            n,d=polynomial_jets(eta,sp.Rational(row["Ca"]),sp.Rational(row["IP3"]))[row["order"]-1]
            assert d.eval(subs)!=0 and n.eval(subs)/d.eval(subs)==value
            targets.append(str(value))
        cases[label] = {"targets":targets,
                        "oracle_sha256":hashlib.sha256((old / "oracle.json").read_bytes()).hexdigest()}

    record = {"unknowns":list(map(str,eta)), "rows":rows, "cases":cases,
              "equation_count":27, "unique_equation_count":24,
              "parameter_elimination":False, "known_initial_state":[0,0,0,0,1,0],
              "observable":"z = (9A + O)/10", "sbml_validation":True,
              "matrix_power_oracle_validation":True, "sympy_version":sp.__version__,
              "generation_seconds":time.monotonic()-started,
              "source_sha256":{f.name:hashlib.sha256(f.read_bytes()).hexdigest()
                               for f in sorted(args.model_dir.iterdir()) if f.suffix in (".xml", ".tsv", ".yaml")}}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(record,indent=2)+"\n")
    print("COMPLETE",record["generation_seconds"],flush=True)


if __name__ == "__main__":
    main()
