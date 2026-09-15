"""Exact structural checks for the captured Sneyd family (not a generic parser)."""
import argparse
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path

import sympy as sp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("system", type=Path)
    parser.add_argument("si_template", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    data = json.loads(args.system.read_text())
    names = data["unknowns"]
    nx = len(names)
    state_indices = [i for i, n in enumerate(names) if n.startswith("IPR_")]
    dynamics, observations = [], []
    for i, terms in enumerate(data["polynomials"]):
        (observations if any(any(t["exponents"][nx:]) for t in terms) else dynamics).append(i+1)
    assert all(max(sum(t["exponents"][i] for i in state_indices)
                   for t in data["polynomials"][r-1]) == 1 for r in dynamics)
    pole_indices = [names.index(n) for n in ("l6_0", "l_6_0")]
    vanished = [i+1 for i, terms in enumerate(data["polynomials"])
                if all(any(t["exponents"][j] > 0 for j in pole_indices) for t in terms)]
    # At l6=l_6=0, set A,R,I1,I2 jets to zero. The remaining non-observation
    # rows vanish too; S jets and O_11 are unconstrained. Observation rows
    # remain the triangular derivative equations for (4O)^4/2500.
    zeros = pole_indices + [i for i,n in enumerate(names) if n.startswith(("IPR_A_", "IPR_R_", "IPR_I1_", "IPR_I2_"))]
    assert all(all(any(t["exponents"][j] > 0 for j in zeros)
                   for t in data["polynomials"][r-1]) for r in dynamics)
    observation_pivots = []
    for r in observations:
        terms = [t for t in data["polynomials"][r-1] if not any(t["exponents"][j] for j in zeros)]
        data_orders = {i-nx for t in terms for i,e in enumerate(t["exponents"]) if e and i >= nx}
        assert len(data_orders) == 1
        order = next(iter(data_orders))
        assert data["data_variables"][order] == f"p_dense_y1_{order}"
        pivot = names.index(f"IPR_O_{order}")
        if order > 0:
            pivot_terms = [t for t in terms if t["exponents"][pivot]]
            assert len(pivot_terms) == 1 and pivot_terms[0]["exponents"][pivot] == 1
            assert pivot_terms[0]["exponents"][names.index("IPR_O_0")] == 3
        observation_pivots.append(order)
    assert sorted(observation_pivots) == list(range(11))
    # Compare selected equations to the separately saved SI template exactly.
    repo = Path(__file__).resolve().parents[2]
    reader = repo / "repro/polynomial_zero_2026_09_15/compare_templates.py"
    spec = importlib.util.spec_from_file_location("saved_template_reader", reader)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    template = module.polynomials(args.si_template)
    symbols = list(map(sp.Symbol, names + [f"y_{i}" for i in range(11)]))
    selected = [sp.Poly.from_dict({tuple(t["exponents"]): sp.Rational(t["numerator"]+"/"+t["denominator"])
                                 for t in terms}, symbols).as_expr() for terms in data["polynomials"]]
    equal = [sp.expand(a.as_expr()-b) == 0 for a,b in zip(template,selected)]
    assert len(template) == len(selected) and all(equal)
    report = {"input_sha256": hashlib.sha256(args.system.read_bytes()).hexdigest(),
              "template_sha256": hashlib.sha256(args.si_template.read_bytes()).hexdigest(),
              "inspector_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "ordered_selected_template_equality": True,
              "equations": len(selected), "unknowns": nx, "data_parameters": 11,
              "kinetic_unknowns": [n for n in names if not n.startswith("IPR_")],
              "anchor_states": sum(n.endswith("_0") for n in names if n.startswith("IPR_")),
              "auxiliary_state_derivatives": sum(not n.endswith("_0") for n in names if n.startswith("IPR_")),
              "dynamics_rows": dynamics, "observation_rows": observations,
              "dynamic_rows_linear_in_state_jets": True,
              "terms": sum(len(t) for t in data["polynomials"]),
              "largest_row_terms": max(len(t) for t in data["polynomials"]),
              "degree_histogram": dict(Counter(max(sum(t["exponents"][:nx]) for t in terms) for terms in data["polynomials"])),
              "vanishing_rows_at_l6_l_6_zero": vanished,
              "nonempty_denominator_zero_family": True,
              "pole_family_note": "Set l6=l_6=0 and all A,R,I1,I2 jets to zero. Every ODE row vanishes. For nonzero y0, choose O0 from the quartic and solve O1..O10 successively. S jets and O11 remain free. This is outside the rational ODE domain; it proves the cleared family has extraneous positive-dimensional solutions."}
    args.output.write_text(json.dumps(report, indent=2)+"\n")
    print(json.dumps({k:v for k,v in report.items() if not isinstance(v,list)}, indent=2))


if __name__ == "__main__":
    main()
