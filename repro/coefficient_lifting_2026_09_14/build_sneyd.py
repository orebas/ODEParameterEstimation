"""Lift reaction coefficients in the frozen Sneyd multiplicity system.

The output is an exactly equivalent ideal on the ORIGINAL saturated domain.
It keeps the frozen observations, coordinates, and representative assignments.
No new sampling, equation selection, or identifiability convention is used.
"""
import argparse
import hashlib
import json
from pathlib import Path
import time
import tomllib

import sympy as sp


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("structure", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    repo = Path(__file__).resolve().parents[2]
    base = repo / "repro/fixed_multiplicity_2026_09_14"
    metadata_path = base / "evidence/input/fixed.toml"
    polynomial_path = base / "evidence/input/fixed_polynomials.txt"
    model_path = base / "sneyd_si_model.toml"
    metadata = tomllib.loads(metadata_path.read_text())
    model = tomllib.loads(model_path.read_text())
    structure = json.loads(args.structure.read_text())
    names = set(structure["variables"]) | set(metadata["variables"]) | set(model["outputs"])
    symbols = {name: sp.Symbol(name) for name in names}

    def parse(text):
        return sp.sympify(text.replace("//", "/").replace("^", "**"), locals=symbols)

    variables = [symbols[name] for name in metadata["variables"]]
    original = [parse(line.removesuffix(" = 0")) for line in polynomial_path.read_text().splitlines()
                if line and not line.startswith("#")]
    assert len(original) == 74 and len(variables) == 73
    assert sum(len(sp.Poly(f, *variables).terms()) for f in original) == 2706
    assert max(sp.Poly(f, *variables).total_degree() for f in original) == 6
    parameter_jets = {p: symbols[p + "_0"] for p in model["parameters"] if p + "_0" in symbols}
    fixed = {symbols[k.removesuffix("_0")]: parse(v) for k, v in metadata["fixed_coordinates"].items()}
    rename = {symbols[p]: v for p, v in parameter_jets.items()}
    coefficient_names = sorted(structure["expanded_coefficients"])
    coefficient_vars = [symbols[name] for name in coefficient_names]
    full_definitions = {symbols[k]: parse(v) for k, v in structure["expanded_coefficients"].items()}
    definitions = {k: sp.cancel(v.subs(fixed).xreplace(rename)) for k, v in full_definitions.items()}
    states = [symbols[name] for name in model["states"]]
    compact = sp.Matrix([parse(structure["dynamics"][name]) for name in model["states"]]).jacobian(states)
    physical = compact.subs(full_definitions)
    frozen = sp.Matrix([parse(model["state_equations"][name]) for name in model["states"]]).jacobian(states)
    # Infer and verify each exact state-coordinate scaling from the saved model.
    # No generating parameter values or fitted candidates enter this comparison.
    for i in range(len(states)):
        for j in range(len(states)):
            if physical[i, j] == 0:
                assert frozen[i, j] == 0
                continue
            ratio = sp.cancel(frozen[i, j] / physical[i, j])
            assert ratio.is_Rational, (states[i], states[j], ratio)
            compact[i, j] *= ratio
            assert sp.cancel(compact[i, j].subs(full_definitions) - frozen[i, j]) == 0
    print("Verified all state-matrix identities against the frozen SI model", flush=True)

    z = next(v for v in variables if str(v).startswith("z_aux")) if any(str(v).startswith("z_aux") for v in variables) else symbols["z_aux"]
    saturation = next(f for f in original if z in f.free_symbols)
    q = sp.diff(saturation, z)
    assert sp.expand(saturation - (z*q - 1)) == 0

    def is_unit_on_original_domain(polynomial):
        if polynomial == 0:
            return False
        for factor, _ in sp.factor_list(polynomial)[1]:
            if sp.cancel(q / factor).as_numer_denom()[1].free_symbols:
                return False
        return True

    jets = [v for v in variables if str(v).rsplit("_", 1)[0] in model["states"]]
    jet_orders = {v: int(str(v).rsplit("_", 1)[1]) for v in jets}
    lifted = []
    certificates = []
    for index, polynomial in enumerate(original):
        if polynomial == saturation or sp.Poly(polynomial, *jets).total_degree() != 1:
            lifted.append(polynomial)
            certificates.append({"index": index, "kind": "unchanged"})
            continue
        present = polynomial.free_symbols.intersection(jets)
        order = max(jet_orders[v] for v in present)
        highest = [v for v in present if jet_orders[v] == order]
        assert len(highest) == 1 and order > 0
        derivative = highest[0]
        state = str(derivative).rsplit("_", 1)[0]
        row = model["states"].index(state)
        replacement = derivative
        for j, state_j in enumerate(model["states"]):
            if compact[row, j] != 0:
                replacement -= compact[row, j] * symbols[f"{state_j}_{order-1}"]
        factor = sp.diff(polynomial, derivative)
        assert is_unit_on_original_domain(factor), factor
        assert sp.cancel(polynomial - factor*replacement.subs(definitions)) == 0
        lifted.append(sp.expand(replacement))
        certificates.append({"index": index, "kind": "ODE recurrence", "derivative": str(derivative),
                             "unit_factor": str(factor), "identity_verified": True})
    assert sum(c["kind"] == "ODE recurrence" for c in certificates) == 61
    for variable, definition in definitions.items():
        numerator, denominator = sp.fraction(definition)
        assert is_unit_on_original_domain(denominator), denominator
        lifted.append(sp.expand(denominator*variable - numerator))
    lifted_variables = variables + coefficient_vars

    def serialize(polynomials, variables):
        return {"variables": list(map(str, variables)), "polynomials": [
            [[str(c.p), str(c.q), list(m)] for m, c in sp.Poly(f, *variables, domain=sp.QQ).terms()]
            for f in polynomials]}

    for label, polynomials, vars_ in [("original", original, variables), ("lifted", lifted, lifted_variables)]:
        artifact = serialize(polynomials, vars_)
        (args.output / f"{label}.json").write_text(json.dumps(artifact, separators=(",", ":")) + "\n")
    sizes = {label: {"equations": len(fs), "variables": len(vs),
                     "terms": sum(len(sp.Poly(f, *vs).terms()) for f in fs),
                     "max_degree": max(sp.Poly(f, *vs).total_degree() for f in fs)}
             for label, fs, vs in [("original", original, variables), ("lifted", lifted, lifted_variables)]}
    report = {"input_hashes": {str(p.relative_to(repo)) if p.is_relative_to(repo) else str(p): digest(p)
                              for p in [args.structure, model_path, metadata_path, polynomial_path]},
              "sizes": sizes, "definitions": {str(k): str(v) for k, v in definitions.items()},
              "row_certificates": certificates, "elapsed_seconds": time.monotonic() - started,
              "equivalence": "Exact substitution identities; every recurrence multiplier and coefficient denominator is a unit on original Q != 0. All original observations and saturation retained.",
              "scope": "Rate coefficients are lifted after expanding named assignments ONCE. The original frozen SI domain is preserved; source-SBML exclusions are a separate domain."}
    (args.output / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(sizes, indent=2), flush=True)


if __name__ == "__main__":
    main()
