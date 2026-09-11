"""Count the saved Fujita template's polynomial support without Julia or solving.

Run with the existing PEtab Python environment (SymPy is required):
  /tmp/odepe-pypesto-env/bin/python repro/petab/dense_single/inspect_fujita.py SAVED_TEMPLATE OUTPUT_JSON
The saved template is trusted repo-generated input, parsed as polynomial text.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

import sympy as sp
from sympy.parsing.sympy_parser import (
    convert_xor, implicit_multiplication_application, parse_expr, rationalize, standard_transformations,
)


def clean(expression):
    expression = re.sub(r"Differential\(t, (\d+)\)\(dense_y(\d+)\(t\)\)",
                        lambda m: f"data_y{m[2]}_{m[1]}", expression)
    expression = re.sub(r"dense_y(\d+)\(t\)", lambda m: f"data_y{m[1]}_0", expression)
    expression = re.sub(r"\bdense_y(\d+)_(\d+)\b", lambda m: f"data_y{m[1]}_{m[2]}", expression)
    return expression.replace("//", "/")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("template", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    source = args.template.read_text()
    if args.template.suffix == ".json":
        saved = json.loads(source)
        names = [clean(s) for s in saved["variables"]]
        lines = saved["equations"]
    else:
        names = [clean(s) for s in re.search(r'varlist_str = """\n(.*?)\n"""', source, re.S)[1].splitlines()]
        lines = re.search(r"poly_system = \[\n(.*?)\n\]", source, re.S)[1].splitlines()
    symbols = {name: sp.Symbol(name) for name in names}
    data = [v for k, v in symbols.items() if k.startswith("data_")]
    unknowns = [v for k, v in symbols.items() if not k.startswith("data_")]
    expressions = [parse_expr(clean(s.strip().removesuffix(",")), local_dict=symbols,
                  transformations=standard_transformations + (convert_xor, implicit_multiplication_application, rationalize))
                  for s in lines if s.strip()]
    assert set().union(*(e.free_symbols for e in expressions)) == set(symbols.values())
    rows = []
    union_support = set()
    highest_variable_degree = 0
    for i, expr in enumerate(expressions, 1):
        assert expr.free_symbols <= set(symbols.values())
        poly = sp.Poly(expr, *unknowns)
        union_support.update(poly.monoms())
        highest_variable_degree = max(highest_variable_degree, *(max(m) for m in poly.monoms()))
        rows.append({"index": i, "terms": len(poly.terms()), "degree": poly.total_degree(),
                     "unknowns_used": len(expr.free_symbols & set(unknowns)),
                     "data_used": sorted(map(str, expr.free_symbols & set(data))),
                     "expression": str(expr)})
    state_jets = [str(v) for v in unknowns if not str(v).startswith(("reaction_", "scaling_", "EGFR_turnover"))]
    parameters = [str(v) for v in unknowns if str(v) not in state_jets]
    state_orders = {}
    for name in state_jets:
        base, order = name.rsplit("_", 1)
        state_orders.setdefault(base, []).append(int(order))
    for orders in state_orders.values():
        orders.sort()
    report = {"source": str(args.template), "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
              "sympy_version": sp.__version__, "equations": len(rows), "unknowns": len(unknowns),
              "data_coefficients": len(data), "parameters": parameters, "state_jet_orders": state_orders,
              "data_symbols": sorted(map(str, data)), "monomial_occurrences": sum(r["terms"] for r in rows),
              "distinct_unknown_monomials_across_system": len(union_support),
              "terms_per_equation_histogram": dict(sorted(Counter(r["terms"] for r in rows).items())),
              "degree_histogram": dict(sorted(Counter(r["degree"] for r in rows).items())),
              "max_individual_variable_degree": highest_variable_degree,
              "count_convention": "Expanded monomials in solve unknowns; observable jets are coefficients. Constants count as one monomial. Cross-equation union is also reported separately.",
              "rows": rows}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k:v for k,v in report.items() if k != "rows"}, indent=2))


if __name__ == "__main__":
    main()
