"""Exact linear-system invariants and support statistics for the independent-rate trial."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

import numpy as np
import sympy as sp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--system", type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Use a fresh output file")
    spec = json.loads(args.spec.read_text())
    rates = sp.symbols("phi1:10")
    matrix = sp.zeros(6)
    for i, row in enumerate(spec["ode_terms"]):
        for term in row:
            matrix[i, term["state_index"]-1] += sp.Rational(term["numerator"], term["denominator"]) * rates[term["rate_index"]-1]
    coefficients = matrix.charpoly().all_coeffs()
    point = dict(zip(rates, [2, 3, 5, 7, 11, 13, 17, 19, 23]))
    jacobian = sp.Matrix(coefficients[1:-1]).jacobian(rates).subs(point)
    h = sp.Matrix([[sp.Rational(9, 10), 0, 0, sp.Rational(1, 10), 0, 0]])
    observability = sp.Matrix.vstack(*[h * matrix.subs(point)**k for k in range(6)])
    assert coefficients[-1] == 0
    assert jacobian.rank() == 5
    assert observability.rank() == 6
    # These nonzero exact minors establish generic ranks, without global SI or GB.
    pivots = jacobian.rref()[1]
    assert len(pivots) == 5
    original_matrix = np.array(matrix.subs(dict(zip(rates, spec["original_rates"]))), dtype=float)
    eigenvalues = sorted(np.linalg.eigvals(original_matrix), key=lambda x: x.real)
    exact_original = matrix.subs(dict(zip(rates, map(sp.Rational, spec["original_rates"]))))
    x0 = sp.Matrix(list(map(sp.Rational, spec["initial_values"])))
    original_observability = sp.Matrix.vstack(*[h * exact_original**k for k in range(6)])
    original_krylov = sp.Matrix.hstack(*[exact_original**k * x0 for k in range(6)])
    assert original_observability.det() != 0
    assert original_krylov.det() != 0
    decay_polynomial = (-exact_original).charpoly().as_poly()
    nonzero_decay_polynomial = decay_polynomial.exquo(sp.Poly(decay_polynomial.gen, decay_polynomial.gen))
    assert nonzero_decay_polynomial.count_roots(0, 1) == 0
    result = {
        "matrix": [[str(matrix[i, j]) for j in range(6)] for i in range(6)],
        "characteristic_coefficients_descending": list(map(str, coefficients)),
        "characteristic_coefficient_term_counts": [len(sp.Poly(c, *rates).terms()) if c else 0 for c in coefficients],
        "exact_generic_point": {str(k): int(v) for k, v in point.items()},
        "coefficient_jacobian_rank": 5,
        "nonzero_jacobian_minor_columns": list(pivots),
        "nonzero_jacobian_minor_determinant": str(jacobian[:, pivots].det()),
        "state_observability_rank": 6,
        "observability_determinant": str(observability.det()),
        "generic_continuous_rate_ambiguity_dimension_with_free_ics": 4,
        "scope": "For w=0.9*A+0.1*O, the scalar sixth-order ODE has five free constant coefficients. Its six initial jets can be chosen freely by the six unknown states when the observability matrix is invertible. y=w^4 preserves these local dimensions away from w=0.",
        "original_generator_eigenvalues_float64": [{"real": float(v.real), "imag": float(v.imag)} for v in eigenvalues],
        "original_sample_spacing": float(spec["original_data"]["times"][1]-spec["original_data"]["times"][0]),
        "original_generator_exact_checks": {
            "state_observability_rank": 6, "initial_vector_krylov_rank": 6,
            "nonzero_decay_eigenvalues_in_closed_interval_0_to_1": 0,
            "arithmetic": "Exact rational representations of the native generator's Float64 effective rates",
        },
        "spec_sha256": hashlib.sha256(args.spec.read_bytes()).hexdigest(),
        "analyzer_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    }
    if args.system:
        system = json.loads(args.system.read_text())
        n = len(system["unknowns"])
        degrees = [max(sum(t["exponents"][:n]) for t in row) for row in system["polynomials"]]
        result["selected_system"] = {
            "equations": len(degrees), "unknowns": n,
            "data_parameters": len(system["data_variables"]),
            "monomials": sum(map(len, system["polynomials"])),
            "max_monomials_per_equation": max(map(len, system["polynomials"])),
            "equation_degree_histogram_in_unknowns": dict(Counter(degrees)),
            "unknown_names": system["unknowns"],
            "sha256": hashlib.sha256(args.system.read_bytes()).hexdigest(),
        }
        # Read the fixed leaf return coefficient in the actual solver coordinates.
        # State rescaling cancels between a state's derivative and its diagonal
        # coefficient, and ODEPE's current problem rescaling does not change time.
        def monomial(name):
            exponents = [0] * (n + len(system["data_variables"]))
            exponents[system["unknowns"].index(name)] = 1
            return tuple(exponents)
        i0, i1, r0 = map(monomial, ("IPR_I1_0", "IPR_I1_1", "IPR_R_0"))
        leaf_rows = []
        for row in system["polynomials"]:
            terms = {tuple(t["exponents"]): sp.Rational(t["numerator"], t["denominator"]) for t in row}
            if set(terms) == {i0, i1, r0}:
                leaf_rows.append(terms)
        assert len(leaf_rows) == 1
        fixed_return = leaf_rows[0][i0] / leaf_rows[0][i1]
        assert fixed_return == 1
        result["selected_system"]["fixed_return_rate_phi4_physical_units"] = str(fixed_return)
        result["selected_system"]["positive_representative_caveat"] = (
            "For strictly positive rates this tree generator is similar to a symmetric matrix. "
            "The principal block on I1 and I2 of the negative generator is phi4*I, so eigenvalue "
            "interlacing bounds its smallest nonzero decay by phi4. The selected slice fixes "
            "phi4=1, while the native generating trajectory has minimal order six and all five "
            "nonzero decays greater than one. Thus the fixed raw algebraic slice cannot reproduce "
            "that complete trajectory with strictly positive rates. This does not rule out an "
            "approximate fit on finite samples or trajectory polish that releases the fixed rates.")
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({k: v for k, v in result.items() if k not in (
        "matrix", "characteristic_coefficients_descending", "scope")}, indent=2))


if __name__ == "__main__":
    main()
