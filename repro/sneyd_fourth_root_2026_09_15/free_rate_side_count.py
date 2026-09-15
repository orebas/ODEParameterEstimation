"""Bounded side diagnostic of the fixed free-rate characteristic map.

This does not replace the estimator or interrupt its HC tracking. It asks how
many rate preimages a consistent reference fibre has, using the linear-state
structure already verified in the preceding free-coefficient study.
"""
import argparse
import hashlib
import json
from pathlib import Path
import signal
import time

import sympy as sp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--seconds", type=int, default=60)
    args = parser.parse_args()
    assert not args.output.exists()
    spec = json.loads(args.spec.read_text())
    assert spec["state_names"] == ["IPR_A", "IPR_I1", "IPR_I2", "IPR_O", "IPR_R", "IPR_S"]
    rates = sp.symbols("phi1:10")
    matrix = sp.zeros(6)
    for i, row in enumerate(spec["ode_terms"]):
        for term in row:
            matrix[i,term["state_index"]-1] += sp.Rational(term["numerator"],term["denominator"])*rates[term["rate_index"]-1]
    fixed = dict.fromkeys(rates[:4],sp.Integer(1))
    free = rates[4:]
    reference = dict(zip(free,[2,3,5,7,11]))
    matrix = matrix.subs(fixed)
    coefficients = matrix.charpoly().all_coeffs()[1:-1]
    equations = [sp.expand(c-c.subs(reference)) for c in coefficients]
    assert sp.Matrix(coefficients).jacobian(free).subs(reference).det() != 0
    result = {"status":"counting", "fixed_rates":{str(k):str(v) for k,v in fixed.items()},
              "source_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "spec_sha256": hashlib.sha256(args.spec.read_bytes()).hexdigest(),
              "reference_rates":{str(k):str(v) for k,v in reference.items()},
              "unknowns":list(map(str,free)),"equations":list(map(str,equations)),
              "monomials":sum(len(sp.Poly(f,*free).terms()) for f in equations),
              "scope":"Consistent characteristic-coefficient reference fibre; no estimator substitution or generic-HC stopping rule"}
    def save():
        args.output.write_text(json.dumps(result,indent=2)+"\n")
    save()
    def timed_out(*_):
        raise TimeoutError("Side diagnostic budget reached")
    signal.signal(signal.SIGALRM,timed_out)
    signal.alarm(args.seconds)
    started = time.monotonic()
    try:
        basis = sp.groebner(equations,*free,order="grevlex",domain=sp.QQ)
        result["basis"] = list(map(str,basis.polys))
        result["zero_dimensional"] = basis.is_zero_dimensional
        assert basis.is_zero_dimensional
        leading = [poly.LM(order=basis.order).exponents for poly in basis.polys]
        standard = {(0,)*len(free)}
        frontier = list(standard)
        while frontier:
            monomial = frontier.pop()
            for i in range(len(free)):
                candidate = tuple(e+(j==i) for j,e in enumerate(monomial))
                if candidate not in standard and not any(all(a>=b for a,b in zip(candidate,lm)) for lm in leading):
                    standard.add(candidate)
                    frontier.append(candidate)
        result["quotient_dimension"] = len(standard)
        # Verify that the seven parameter points represent simple, observable
        # fibres, rather than merely a quotient length including bad loci.
        jacobian = sp.Matrix(coefficients).jacobian(free).det(method="domain-ge")
        h = sp.Matrix([[sp.Rational(9,10),0,0,sp.Rational(1,10),0,0]])
        observability = sp.Matrix.vstack(*[h*matrix**k for k in range(6)])
        observation_det = observability.det(method="domain-ge")
        def unit_on_fibre(polynomial):
            augmented = sp.groebner(equations+[polynomial],*free,order="grevlex",domain=sp.QQ)
            return len(augmented.polys) == 1 and augmented.polys[0].as_expr() == 1
        assert unit_on_fibre(jacobian)
        assert unit_on_fibre(observation_det)
        initial = sp.Matrix([2,3,5,7,11,13])
        reference_matrix = matrix.subs(reference)
        moments = [(h*reference_matrix**k*initial)[0] for k in range(11)]
        hankel = sp.Matrix(5,5,lambda i,j:moments[i+j+1])
        assert hankel.det() != 0
        assert moments[0] != 0
        result.update(all_kinetic_roots_simple=True, all_kinetic_roots_observable=True,
                      reference_initial_states=list(map(str,initial)),
                      reference_hankel_determinant=str(hankel.det()),
                      rooted_reference_fibre_count=len(standard),
                      quartic_reference_fibre_count=4*len(standard))
        result["status"] = "complete"
    except TimeoutError as err:
        result.update(status="timeout",error=str(err))
    finally:
        signal.alarm(0)
        result["seconds"] = time.monotonic()-started
        save()
    print(json.dumps({k:result[k] for k in ("status","seconds","quotient_dimension") if k in result}),flush=True)


if __name__ == "__main__":
    main()
