"""A Sneyd-only off-line count using its linear state matrix.

At a fixed condition, y=(4 O+9 A)^4/2500 in the saved SI coordinates.
The five nonconstant eigenmodes identify five characteristic coefficients.
Each regular kinetic solution gives four initial-state solutions. This
diagnostic records the exact maps; numerical completeness is a separate check.
"""
import argparse
import hashlib
import json
from pathlib import Path
import time
import tomllib

import sympy as sp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    repo = Path(__file__).resolve().parents[2]
    structure_path = repo / "repro/coefficient_lifting_2026_09_14/evidence/structure.json"
    model_path = repo / "repro/fixed_multiplicity_2026_09_14/sneyd_si_model.toml"
    metadata_path = repo / "repro/fixed_multiplicity_2026_09_14/evidence/input/fixed.toml"
    structure = json.loads(structure_path.read_text())
    model = tomllib.loads(model_path.read_text())
    metadata = tomllib.loads(metadata_path.read_text())
    symbols = {name: sp.Symbol(name) for name in structure["variables"]}

    def parse(s):
        return sp.sympify(s.replace("//", "/").replace("^", "**"), locals=symbols)

    states = [symbols[name] for name in model["states"]]
    fixed = {symbols[k.removesuffix("_0")]: parse(v) for k, v in metadata["fixed_coordinates"].items()}
    theta = [symbols[p] for p in model["parameters"] if symbols[p] not in fixed]
    assert list(map(str, theta)) == ["l4", "l6", "l_2", "l_4", "l_6"]
    rates = {symbols[k]: parse(v) for k, v in structure["expanded_coefficients"].items()}
    compact = sp.Matrix([parse(structure["dynamics"][s]) for s in model["states"]]).jacobian(states)
    original = sp.Matrix([parse(model["state_equations"][s]) for s in model["states"]]).jacobian(states)
    physical = compact.subs(rates)
    for i in range(6):
        for j in range(6):
            if physical[i, j] == 0:
                assert original[i, j] == 0
            else:
                scale = sp.cancel(original[i, j] / physical[i, j])
                assert scale.is_Rational
                compact[i, j] *= scale
                assert sp.cancel(compact[i, j].subs(rates) - original[i, j]) == 0
    rate_values = {v: sp.cancel(f.subs(fixed)) for v, f in rates.items()}
    matrix = compact.subs(rate_values).applyfunc(sp.cancel)
    c = sp.Matrix([[4, 0, 0, 0, 0, 9]])
    assert sp.expand(parse(model["output_equations"]["dense_y1"]) - (c*sp.Matrix(states))[0]**4/2500) == 0
    lam = sp.Symbol("lambda")
    characteristic = compact.charpoly(lam).all_coeffs()
    assert characteristic[-1] == 0
    maps = [sp.cancel(f.subs(rate_values)) for f in reversed(characteristic[1:-1])]
    print("Characteristic maps built", flush=True)
    # A fresh exact generic kinetic point is used for the side count, independent
    # of the dense-data generator and the earlier frozen random jet.
    seed = list(map(sp.Rational, [2, 3, 5, 7, 11]))
    substitution = dict(zip(theta, seed))
    target = [f.subs(substitution) for f in maps]
    a0 = matrix.subs(substitution)
    assert list(reversed(a0.charpoly(lam).all_coeffs()[1:-1])) == target
    observability = sp.Matrix.vstack(*[c*a0**i for i in range(6)])
    assert observability.det() != 0
    assert sp.Matrix(maps).jacobian(theta).subs(substitution).det() != 0
    # Retain the ORIGINAL SI saturation domain, including factors removed by
    # rational simplification of the matrix or characteristic coefficients.
    polynomial_path = repo / "repro/fixed_multiplicity_2026_09_14/evidence/input/fixed_polynomials.txt"
    saturation_line = next(line for line in polynomial_path.read_text().splitlines()
                           if "z_aux" in line and not line.startswith("#"))
    saturation = parse(saturation_line.removesuffix(" = 0"))
    q = sp.diff(saturation, sp.Symbol("z_aux")).subs({sp.Symbol(str(v)+"_0"):v for v in theta})
    assert sp.expand(saturation-(sp.Symbol("z_aux")*sp.diff(saturation,sp.Symbol("z_aux"))-1)) == 0
    for f in list(matrix)+maps:
        for factor,_ in sp.factor_list(sp.denom(f))[1]:
            assert not sp.cancel(q/factor).as_numer_denom()[1].free_symbols
    assert q.subs(substitution) != 0
    initial = sp.Matrix([2,3,5,7,11,13])
    moments = [(c*a0**i*initial)[0] for i in range(12)]
    hankel = sp.Matrix(5,5,lambda i,j:moments[i+j+1])
    assert hankel.det() != 0
    assert hankel.inv()*sp.Matrix([-moments[i+6] for i in range(5)]) == sp.Matrix(target)
    assert moments[11]+sum(target[i]*moments[i+6] for i in range(5)) == 0
    eta = sp.symbols("eta1:6")
    z = sp.Symbol("inverse_denominator")
    equations = [sp.expand(sp.denom(f)*p-sp.numer(f)) for f, p in zip(maps, eta)]
    equations.append(sp.expand(z*q-1))
    variables = theta+[z]
    root = seed+[1/q.subs(substitution)]
    parameterization = dict(zip(eta, target))
    assert all(f.subs(parameterization).subs(dict(zip(variables, root))) == 0 for f in equations)

    def serialize(f, variables):
        return [[str(c.p), str(c.q), list(m)] for m, c in sp.Poly(f, *variables, domain=sp.QQ).terms()]

    all_vars = variables+list(eta)
    artifact = {
        "variables": list(map(str, variables)), "parameters": list(map(str, eta)),
        "polynomials": [serialize(f, all_vars) for f in equations],
        "start_root": list(map(str, root)), "start_parameters": list(map(str, target)),
        "matrix": [[serialize(sp.numer(matrix[i,j]), theta) for j in range(6)] for i in range(6)],
        "matrix_denominators": [[serialize(sp.denom(matrix[i,j]), theta) for j in range(6)] for i in range(6)],
        "characteristic_maps": list(map(str, maps)), "denominator": str(q),
        "state_order": model["states"], "observable_linear_weights": [4,0,0,0,0,9],
        "scope": "Generic kinetic characteristic-coefficient fibre on the same nine representative fixes. Four observable fourth-root branches per regular kinetic solution. Not the earlier frozen random jet, not a fit to data.",
        "sample_observability_determinant": str(observability.det()),
        "sample_map_jacobian_determinant": str(sp.Matrix(maps).jacobian(theta).subs(substitution).det()),
        "sample_moments":list(map(str,moments)),"sample_hankel_determinant":str(hankel.det()),
        "fixed_parameters": {str(k): str(v) for k,v in fixed.items()},
        "source_sha256": {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest()
                           for p in [structure_path,model_path,metadata_path,polynomial_path,Path(__file__)]},
        "elapsed_seconds": time.monotonic()-started,
        "sizes": {"equations":len(equations),"variables":len(variables),
                  "terms":sum(len(sp.Poly(f,*all_vars).terms()) for f in equations),
                  "degrees_in_unknowns":[sp.Poly(f,*variables).total_degree() for f in equations]}}
    (args.output/"counter.json").write_text(json.dumps(artifact,indent=2)+"\n")
    frozen = [sp.expand(f.subs(parameterization)) for f in equations]
    (args.output/"counter_fixed.json").write_text(json.dumps({"variables":list(map(str,variables)),
        "polynomials":[serialize(f,variables) for f in frozen]},separators=(",",":"))+"\n")
    print(json.dumps(artifact["sizes"],indent=2),flush=True)


if __name__ == "__main__":
    main()
