"""Compare ordered saved Julia polynomial templates with exact arithmetic."""
import argparse
from fractions import Fraction
import gzip
import json
from pathlib import Path
import re

import sympy as sp


def polynomials(path):
    source = gzip.open(path, "rt").read() if path.suffix == ".gz" else path.read_text()
    body = source.split("poly_system = [\n", 1)[1].rsplit("\n]", 1)[0]
    equations = []
    for line in body.splitlines():
        text = line.strip().rstrip(",")
        text = re.sub(r"Differential\(t, (\d+)\)\(dense_y1\(t\)\)", r"y_\1", text)
        text = text.replace("dense_y1(t)", "y_0")
        text = re.sub(r"(?<=\d)(?=IPR_)", "*", text)
        # Preserve the exact Float64 value of old printed decimal coefficients.
        def exact_float(match):
            value = Fraction.from_float(float(match[0]))
            return f"({value.numerator}/{value.denominator})"
        text = re.sub(r"(?<![\w.])\d+\.\d+(?:[eE][+-]?\d+)?", exact_float, text)
        equations.append(sp.Poly(sp.sympify(text.replace("//", "/").replace("^", "**"))))
    return equations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    args = parser.parse_args()
    before, after = polynomials(args.before), polynomials(args.after)
    assert len(before) == len(after)
    equal = [sp.expand(a.as_expr()-b.as_expr()) == 0 for a, b in zip(before, after)]
    result = {"equations_before": len(before), "equations_after": len(after),
              "ordered_exact_equality": all(equal),
              "different_rows": [i+1 for i, value in enumerate(equal) if not value],
              "terms": sum(len(p.terms()) for p in after),
              "max_terms_per_equation": max(len(p.terms()) for p in after),
              "max_degree": max(p.total_degree() for p in after)}
    print(json.dumps(result, indent=2))
    assert result["ordered_exact_equality"]


if __name__ == "__main__":
    main()
