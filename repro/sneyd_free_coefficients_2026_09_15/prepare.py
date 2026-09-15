"""Build an independent-rate Sneyd model specification from the retained SBML extraction."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path

import sympy as sp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Use a fresh output file")
    repo = Path(__file__).resolve().parents[2]
    structure_path = repo / "repro/coefficient_lifting_2026_09_14/evidence/structure.json"
    report_path = repo / "repro/sneyd_hc_2026_09_15/evidence/capture/result.json.gz"
    data_path = repo / "repro/sneyd_hc_2026_09_15/evidence/capture/data.json.gz"
    structure = json.loads(structure_path.read_text())
    report = json.loads(gzip.decompress(report_path.read_bytes()))
    data = json.loads(gzip.decompress(data_path.read_bytes()))
    names = {n:sp.Symbol(n) for n in structure["variables"]}
    parse = lambda s: sp.sympify(s.replace("//","/").replace("^","**"), locals=names)
    coefficient_ids = sorted(structure["coefficients"],key=lambda n:int(n.rsplit("_",1)[1]))
    rates = [names[n] for n in coefficient_ids]
    states = [names[n] for n in structure["state_ids"]]
    definitions = {names[n]:parse(structure["expanded_coefficients"][n]) for n in coefficient_ids}
    nominal = {names[n]:sp.Rational(v) for n,v in report["model_definition"]["generating_parameters"].items()}
    terms = []
    for state in states:
        expression = parse(structure["dynamics"][str(state)])
        assert sp.cancel(expression.subs(definitions)-parse(structure["expanded_dynamics"][str(state)])) == 0
        row = []
        for exponents, coefficient in sp.Poly(expression,*(states+rates),domain=sp.QQ).terms():
            assert sum(exponents[:6]) == sum(exponents[6:]) == 1
            row.append({"state_index":exponents[:6].index(1)+1,"rate_index":exponents[6:].index(1)+1,
                        "numerator":str(coefficient.p),"denominator":str(coefficient.q)})
        terms.append(row)
    # Preserve conservation and the shared return coefficient exactly.
    assert sp.expand(sum(parse(structure["dynamics"][str(s)]) for s in states)) == 0
    spec = {"condition":structure["condition_id"],"state_names":list(map(str,states)),
        "rate_names":[f"phi{i+1}" for i in range(len(rates))],"source_coefficient_ids":coefficient_ids,
        "source_coefficient_maps":{f"phi{i+1}":str(definitions[r]) for i,r in enumerate(rates)},
        "ode_terms":terms,"original_rates":[float(definitions[r].subs(nominal)) for r in rates],
        "moderate_rates":[0.7,1.3,0.9,1.1,0.6,1.4,0.8,1.2,0.5],
        "initial_values":[report["model_definition"]["generating_initial_states"][str(s)+"(t)"] for s in states],
        "original_data":data,"original_interval":report["model_definition"]["time_interval"],
        "observation":"(0.9*IPR_A + 0.1*IPR_O)^4",
        "scope":"Nine independent effective rates; no defining equations tying rates to original kinetic parameters. Shared rates and six-state reaction topology retained.",
        "exact_original_vector_field_identity":True,"exact_total_state_conservation":True,
        "source_sha256":{str(p.relative_to(repo)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [structure_path,report_path,data_path,Path(__file__)]}}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(spec,indent=2)+"\n")
    print(json.dumps({"states":len(states),"free_rates":len(rates),"original_rates":spec["original_rates"],
                      "exact_vector_field_identity":True,"state_conservation":True},indent=2))


if __name__ == "__main__":
    main()
