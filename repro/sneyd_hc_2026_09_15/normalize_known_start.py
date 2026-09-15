"""Exact invertible column, data-parameter and row scaling for a known-start diagnostic."""
import argparse
from fractions import Fraction as Q
import hashlib
import json
from math import prod
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("system", type=Path)
    parser.add_argument("start", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=False)
    system = json.loads(args.system.read_text())
    start = json.loads(args.start.read_text())
    assert start["system_sha256"] == hashlib.sha256(args.system.read_bytes()).hexdigest()
    root, parameters = list(map(Q,start["root"])), list(map(Q,start["parameters"]))
    scales = [x if x else Q(1) for x in root+parameters]
    normalized = dict(system)
    normalized["polynomials"] = []
    row_scales = []
    for terms in system["polynomials"]:
        coefficients = [Q(int(t["numerator"]),int(t["denominator"]))*prod(s**e for s,e in zip(scales,t["exponents"])) for t in terms]
        row_scale = max(map(abs,coefficients))
        row_scales.append(row_scale)
        normalized["polynomials"].append([{"numerator":str((c/row_scale).numerator),
            "denominator":str((c/row_scale).denominator),"exponents":t["exponents"]} for c,t in zip(coefficients,terms)])
    # The capture's displayed expressions describe unscaled polynomials only.
    normalized.pop("equations",None)
    normalized["generic_parameters_real"] = [x/float(s) for x,s in zip(system["generic_parameters_real"],scales[len(root):])]
    normalized["generic_parameters_imag"] = [x/float(s) for x,s in zip(system["generic_parameters_imag"],scales[len(root):])]
    normalized["normalization"] = {"original_system_sha256":start["system_sha256"],
        "root_scales":list(map(str,scales[:len(root)])),"parameter_scales":list(map(str,scales[len(root):])),
        "row_scales":list(map(str,row_scales)),
        "mapping":"original_unknown_i = root_scales_i * normalized_unknown_i; likewise for data parameters; normalized equation_j = original equation_j / row_scales_j after substitution"}
    path = args.output/"system.json"
    path.write_text(json.dumps(normalized, separators=(",",":"))+"\n")
    nstart = dict(start)
    nstart["source"] += "; exact known-start normalization of unknowns, data parameters and rows"
    nstart["root"] = [str(x/s) for x,s in zip(root,scales)]
    nstart["parameters"] = [str(p/s) for p,s in zip(parameters,scales[len(root):])]
    nstart["system_sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
    nstart["normalizer_sha256"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    ordered = list(map(Q,nstart["root"]+nstart["parameters"]))
    for old, new, row_scale in zip(system["polynomials"],normalized["polynomials"],row_scales):
        for a,b in zip(old,new):
            assert a["exponents"] == b["exponents"]
            assert Q(int(a["numerator"]),int(a["denominator"]))*prod(s**e for s,e in zip(scales,a["exponents"])) == Q(int(b["numerator"]),int(b["denominator"]))*row_scale
        assert sum(Q(int(t["numerator"]),int(t["denominator"]))*prod(v**e for v,e in zip(ordered,t["exponents"])) for t in new) == 0
    (args.output/"known_start.json").write_text(json.dumps(nstart,indent=2)+"\n")
    print("Exact scaling identities and normalized root verified for every equation")


if __name__ == "__main__":
    main()
