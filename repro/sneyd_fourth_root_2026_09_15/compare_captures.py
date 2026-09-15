"""Verify root/quartic HC families after undoing their automatic unit changes."""
import argparse
from collections import Counter
from fractions import Fraction
import hashlib
import json
import math
from pathlib import Path

import sympy as sp


def canonical(terms):
    terms = {key: value for key, value in terms.items() if value}
    lead = terms[min(terms)]
    return tuple((key, str(value / lead)) for key, value in sorted(terms.items()))


def physical_rows(directory):
    record = json.loads((directory / "result.json").read_text())
    capture = json.loads((directory / "generic_system_1.json").read_text())
    names = capture["unknowns"] + capture["data_variables"]
    sizes = record["scale_info"]
    state_sizes = {key.removesuffix("(t)"): Fraction(value)
                   for key, value in sizes["state_scales"].items()}
    parameter_sizes = {key: Fraction(value) for key, value in sizes["param_scales"].items()}
    output_size = Fraction(next(iter(sizes["observable_scales"].values())))
    factors = []
    physical_names = []
    for i, name in enumerate(names):
        if i >= len(capture["unknowns"]):
            factors.append(output_size)
            physical_names.append("data_" + name.rsplit("_", 1)[1])
        else:
            base, order = name.rsplit("_", 1)
            factors.append(state_sizes[base] if base in state_sizes else parameter_sizes[base])
            physical_names.append(name)
    dynamics, observations = [], []
    for row in capture["polynomials"]:
        converted = {}
        for term in row:
            coefficient = Fraction(int(term["numerator"]), int(term["denominator"]))
            monomial = []
            for name, power, factor in zip(physical_names, term["exponents"], factors):
                if power:
                    coefficient /= factor ** power
                    monomial.append((name, power))
            key = tuple(sorted(monomial))
            converted[key] = converted.get(key, Fraction(0)) + coefficient
        is_observation = any(any(name.startswith("data_") for name, _ in key) for key in converted)
        (observations if is_observation else dynamics).append(canonical(converted))
    return record, capture, dynamics, observations


def expected_observations(order, quartic):
    a = sp.symbols(f"IPR_A_0:{order+1}")
    o = sp.symbols(f"IPR_O_0:{order+1}")
    data = sp.symbols(f"data_0:{order+1}")
    series = [(sp.Rational(9, 10) * a[k] + sp.Rational(1, 10) * o[k]) / math.factorial(k)
              for k in range(order+1)]
    power_series = [sp.Integer(1)] + [sp.Integer(0)] * order
    for _ in range(4 if quartic else 1):
        power_series = [sp.expand(sum(power_series[j] * series[k-j] for j in range(k+1)))
                        for k in range(order+1)]
    variables = list(a) + list(o) + list(data)
    rows = []
    for k in range(order+1):
        polynomial = sp.Poly(math.factorial(k)*power_series[k] - data[k], *variables)
        terms = {tuple(sorted((str(var), exponent) for var, exponent in zip(variables, exponents) if exponent)):
                 Fraction(int(value.p), int(value.q)) for exponents, value in polynomial.terms()}
        rows.append(canonical(terms))
    return Counter(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("quartic", type=Path)
    parser.add_argument("root", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    assert not args.output.exists()
    qr, qc, qd, qo = physical_rows(args.quartic)
    rr, rc, rd, ro = physical_rows(args.root)
    assert qr["model_kind"] == rr["model_kind"]
    assert set(qc["unknowns"]) == set(rc["unknowns"])
    assert qr["scale_info"]["param_scales"] == rr["scale_info"]["param_scales"]
    assert Counter(qd) == Counter(rd), "Dynamical polynomial constraints changed"
    order = len(qo)-1
    assert len(qo) == len(ro)
    assert Counter(qo) == expected_observations(order, True)
    assert Counter(ro) == expected_observations(order, False)
    result = {"model": qr["model_kind"], "same_unknown_names": True,
              "same_parameter_units": True,
              "dynamics_equal_after_undoing_scaling_and_row_normalization": True,
              "dynamic_rows": len(qd), "observation_rows": len(qo),
              "quartic_observation_jets_verified_exactly": True,
              "linear_observation_jets_verified_exactly": True,
              "highest_observation_derivative": order,
              "root_unknowns": rc["unknowns"],
              "inputs": {label: {name: hashlib.sha256((directory/name).read_bytes()).hexdigest()
                                   for name in ("result.json", "generic_system_1.json")}
                         for label, directory in (("quartic", args.quartic), ("root", args.root))},
              "source_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    if rr["model_kind"] == "rational":
        # The previous denominator-domain defect is independent of rooting.
        names = rc["unknowns"]
        poles = [names.index(name) for name in ("l6_0", "l_6_0")]
        zeros = poles + [i for i, name in enumerate(names)
                         if name.startswith(("IPR_A_", "IPR_R_", "IPR_I1_", "IPR_I2_"))]
        dynamics = [row for row in rc["polynomials"]
                    if not any(any(term["exponents"][len(names):]) for term in row)]
        assert len(dynamics) == 61
        assert all(all(any(term["exponents"][i] for i in zeros) for term in row) for row in dynamics)
        # Exact linear-observation checks above prove the remaining rows fix
        # O_0..O_10 individually; S jets and O_11 remain free.
        result["rooted_rational_pole_family_remains"] = True
        result["pole_family_note"] = (
            "Set l6=l_6=0 and all A,R,I1,I2 jets to zero. Every dynamical row vanishes. "
            "Linear observations determine O_0..O_10; S jets and O_11 remain free. "
            "These solutions lie outside the rational ODE domain. This is not a proof of the runtime cause.")
    args.output.write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps({k: v for k, v in result.items() if k != "root_unknowns"}, indent=2))


if __name__ == "__main__":
    main()
