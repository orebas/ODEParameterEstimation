"""Forward-generate one exact Sneyd jet, independently of the dense-data truth."""
import argparse
from fractions import Fraction as Q
import hashlib
import json
from math import factorial, prod
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("system", type=Path)
    parser.add_argument("counter", type=Path, help="The earlier exact coefficient-counter matrix artifact")
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    system = json.loads(args.system.read_text())
    counter = json.loads(args.counter.read_text())
    theta = list(map(Q, [2, 3, 5, 7, 11]))
    initial = list(map(Q, [2, 3, 5, 7, 11, 13]))

    def evaluate(terms):
        return sum(Q(int(a),int(b))*prod(x**e for x,e in zip(theta,p)) for a,b,p in terms)

    matrix = [[evaluate(counter["matrix"][i][j])/evaluate(counter["matrix_denominators"][i][j])
               for j in range(6)] for i in range(6)]
    jets = [initial]
    for k in range(11):
        jets.append([sum(a*x for a,x in zip(row,jets[-1])) for row in matrix])
    values = {name+"_0":value for name,value in zip(counter["variables"][:5],theta)}
    values.update({f"{state}_{k}":jets[k][i] for i,state in enumerate(counter["state_order"]) for k in range(12)})
    # Taylor coefficients, then four exact truncated convolutions for y=w^4/2500.
    w = [sum(Q(c)*x for c,x in zip(counter["observable_linear_weights"],j))/factorial(k)
         for k,j in enumerate(jets)]
    powered = [Q(1)] + [Q(0)]*11
    for _ in range(4):
        powered = [sum(powered[j]*w[k-j] for j in range(k+1)) for k in range(12)]
    values.update({f"p_dense_y1_{k}":powered[k]*factorial(k)/2500 for k in range(12)})
    ordered = [values[n] for n in system["unknowns"]+system["data_variables"]]
    for terms in system["polynomials"]:
        assert sum(Q(int(t["numerator"]),int(t["denominator"]))*prod(v**e for v,e in zip(ordered,t["exponents"]))
                   for t in terms) == 0
    record = {"source": "Independent exact kinetic point (2,3,5,7,11), initial states (2,3,5,7,11,13), same reference as the side counter; forward jets, no observed-data or nominal-value fitting",
              "system_sha256": hashlib.sha256(args.system.read_bytes()).hexdigest(),
              "counter_sha256": hashlib.sha256(args.counter.read_bytes()).hexdigest(),
              "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "root": list(map(str,ordered[:len(system["unknowns"])])),
              "parameters": list(map(str,ordered[len(system["unknowns"]):])),
              "all_selected_equations_exactly_zero": True,
              "kinetics": list(map(str,theta)), "initial_states": list(map(str,initial))}
    args.output.write_text(json.dumps(record,indent=2)+"\n")
    print("Verified every selected equation exactly at the generated start")


if __name__ == "__main__":
    main()
