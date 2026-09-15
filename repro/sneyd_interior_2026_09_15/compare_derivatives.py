"""Compare saved interpolated derivatives with the linear generator, diagnostically."""
import argparse
import hashlib
import json
from pathlib import Path

import mpmath as mp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("probe", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Use a fresh output file")
    spec = json.loads(args.spec.read_text())
    probe = json.loads(args.probe.read_text())
    mp.mp.dps = 90
    rates = [mp.mpf(str(value)) for value in spec["original_rates"]]
    matrix = mp.matrix(6)
    for i, row in enumerate(spec["ode_terms"]):
        for term in row:
            coefficient = mp.mpf(term["numerator"]) / mp.mpf(term["denominator"])
            matrix[i, term["state_index"]-1] += coefficient * rates[term["rate_index"]-1]
    initial = mp.matrix([mp.mpf(str(x)) for x in spec["initial_values"]])
    observable = mp.matrix([[mp.mpf(".9"), 0, 0, mp.mpf(".1"), 0, 0]])
    derivative_rows = [observable]
    for _ in range(10):
        derivative_rows.append(derivative_rows[-1] * matrix)
    rows = []
    scale = probe["observation_scale"]
    for time, estimated in zip(probe["times"], probe["jets"]):
        state = mp.expm(matrix * mp.mpf(str(time))) * initial
        actual = [(row * state)[0] for row in derivative_rows]
        physical = [value * scale for value in estimated]
        rows.append({"time": time, "oracle_physical": [float(x) for x in actual],
                     "interpolated_physical": physical,
                     "absolute_errors": [float(abs(mp.mpf(x)-y)) for x, y in zip(physical, actual)],
                     "relative_errors": [None if y == 0 else float(abs((mp.mpf(x)-y)/y))
                                         for x, y in zip(physical, actual)]})
    # Independent roundtrip to the retained data at every sampled comparison time.
    samples = dict(zip(spec["original_data"]["times"], spec["original_data"]["signals"][0]["values"]))
    discrepancy = max(abs(row["oracle_physical"][0]**4-samples[row["time"]]) for row in rows)
    report = {"scope": "Generator-only diagnostic: z^(k)(t)=c Q^k exp(Qt) x0; these values are never estimator inputs",
              "mpmath_version": mp.__version__, "decimal_precision": mp.mp.dps,
              "spec_sha256": hashlib.sha256(args.spec.read_bytes()).hexdigest(),
              "probe_sha256": hashlib.sha256(args.probe.read_bytes()).hexdigest(),
              "fourth_power_roundtrip_max_abs_error": discrepancy,
              "rows": rows}
    args.output.write_text(json.dumps(report, indent=2)+"\n")
    print("oracle fourth-power discrepancy:", discrepancy)
    print("time     z′ oracle       z′ interpolated     z¹⁰ oracle      z¹⁰ interpolated")
    chosen = [rows[0], rows[1], rows[min(range(len(rows)), key=lambda i: abs(rows[i]["time"]-.2))],
              rows[min(range(len(rows)), key=lambda i: abs(rows[i]["time"]-.5))], rows[-1]]
    for row in chosen:
        truth, estimate = row["oracle_physical"], row["interpolated_physical"]
        print(f'{row["time"]:6.4f} {truth[1]:15.6e} {estimate[1]:15.6e} {truth[10]:15.6e} {estimate[10]:15.6e}')


if __name__ == "__main__":
    main()
