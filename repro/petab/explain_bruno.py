"""Audit recorded Bruno fits using matrix exponentials of the canonical SBML.

No fitting or new starts. Writes every measurement, prediction and likelihood
contribution, the raw algebraic state comparison, and a six-panel figure.
"""
import argparse
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

os.environ.setdefault("MPLCONFIGDIR", "/tmp/odepe-bruno-matplotlib")
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy.linalg import expm


def table(path):
    with path.open() as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-root", type=Path, default=Path("/tmp/odepe-petab-full-20260910/Benchmark-Models"))
    parser.add_argument("--output", type=Path, default=Path("repro/petab/bruno_explained"))
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    name = "Bruno_JExpBot2016"
    directory = args.model_root / name
    args.output.mkdir(parents=True, exist_ok=True)
    measurements = table(directory / f"measurementData_{name}.tsv")
    conditions = {r["conditionId"]: r for r in table(directory / f"experimentalCondition_{name}.tsv")}
    observables = {r["observableId"]: r["observableFormula"] for r in table(directory / f"observables_{name}.tsv")}
    parameters = table(directory / f"parameters_{name}.tsv")
    assert all(r["parameterScale"] == "log10" and r["estimate"] == "1" for r in parameters)
    ns = {"s": "http://www.sbml.org/sbml/level2/version4", "m": "http://www.w3.org/1998/Math/MathML"}
    model = ET.parse(directory / f"model_{name}.xml").getroot().find("s:model", ns)
    states = [r.attrib["id"] for r in model.findall("s:listOfSpecies/s:species", ns)]
    defaults = {r.attrib["id"]: float(r.attrib["value"]) for r in model.findall("s:listOfParameters/s:parameter", ns)}
    defaults.update({r.attrib["id"]: float(r.attrib["size"]) for r in model.findall("s:listOfCompartments/s:compartment", ns)})
    initials = {r.attrib["symbol"]: r.find("m:math/m:ci", ns).text.strip() for r in model.findall("s:listOfInitialAssignments/s:initialAssignment", ns)}
    reactions = []
    for reaction in model.findall("s:listOfReactions/s:reaction", ns):
        law = reaction.find("s:kineticLaw/m:math/m:apply", ns)
        assert law[0].tag == "{" + ns["m"] + "}times"
        factors = [r.text.strip() for r in law[1:]]
        assert all(r.tag == "{" + ns["m"] + "}ci" for r in law[1:])
        substrates = [f for f in factors if f in states]
        assert len(substrates) == 1, "Matrix-exponential audit requires a linear state system"
        stoichiometry = np.zeros(len(states))
        for side, sign in (("listOfReactants", -1), ("listOfProducts", 1)):
            for r in reaction.findall(f"s:{side}/s:speciesReference", ns):
                stoichiometry[states.index(r.attrib["species"])] += sign * float(r.attrib.get("stoichiometry", 1))
        reactions.append((states.index(substrates[0]), [f for f in factors if f not in states], stoichiometry))

    def system(physical, cid):
        values = defaults | physical
        for key, value in conditions[cid].items():
            if key in ("conditionId", "conditionName"):
                continue
            values[key] = values[value] if value in values else float(value)
        matrix = np.zeros((len(states), len(states)))
        for substrate, factors, stoichiometry in reactions:
            matrix[:, substrate] += math.prod(values[f] for f in factors) * stoichiometry
        initial = np.array([values[initials[s]] if s in initials else 0.0 for s in states])
        return matrix, initial

    run = json.loads((here / "block_results" / f"{name}.odepe_blocks6.json").read_text())
    revision = subprocess.check_output(["git", "-C", str(args.model_root), "rev-parse", "HEAD"], text=True).strip()
    assert revision == run["benchmark_revision"]
    candidate = min(run["result"]["candidates"], key=lambda c: c["nllh"])
    refined = run["result"]["refined"]
    physical = lambda ids, x: dict(zip(ids, np.power(10.0, x).tolist()))
    vectors = {"raw_seed": physical(run["parameter_ids"], candidate["x"]),
               "refined": physical(run["parameter_ids"], refined["x"]),
               "recorded_start": physical(run["parameter_ids"], run["x0"]),
               "reference": {r["parameterId"]: float(r["nominalValue"]) for r in parameters}}
    expected = {"raw_seed": candidate["nllh"], "refined": refined["nllh"], "recorded_start": run["initial_nllh"]}
    for method in ("petab_julia", "pypesto_amici"):
        baseline = json.loads((here / "pilot_results" / f"{name}.{method}.json").read_text())
        vectors[method] = physical(baseline["parameter_ids"], baseline["result"]["x"])
        expected[method] = baseline["result"]["nllh"]
    systems = {key: {cid: system(vector, cid) for cid in conditions} for key, vector in vectors.items()}
    rows = []
    for measurement in measurements:
        cid, oid = measurement["simulationConditionId"], measurement["observableId"]
        t, y, sigma = (float(measurement[k]) for k in ("time", "measurement", "noiseParameters"))
        row = dict(condition=cid, observable=oid, time=t, measurement=y, sigma=sigma,
                   nllh_constant=math.log(sigma * math.sqrt(2 * math.pi)))
        for key in vectors:
            matrix, initial = systems[key][cid]
            predicted = float((expm(matrix * t) @ initial)[states.index(observables[oid])])
            row[key + "_prediction"] = predicted
            row[key + "_squared_standardized_residual"] = ((predicted-y)/sigma)**2
        rows.append(row)
    constant = sum(r["nllh_constant"] for r in rows)
    scores = {}
    for key in vectors:
        chi2 = sum(r[key + "_squared_standardized_residual"] for r in rows)
        nllh = constant + chi2 / 2
        scores[key] = dict(nllh=nllh, chi_square=chi2, rms_standardized_residual=math.sqrt(chi2/len(rows)))
        if key in expected:
            scores[key]["recorded_nllh"] = expected[key]
            assert np.isclose(nllh, expected[key], atol=1e-4, rtol=1e-6), (key, nllh, expected[key])
    mapping = json.loads((here / "derivative10_results" / f"{name}.system6.json").read_text())["state_ids"]
    state_rows = []
    for symbolic_state, value in candidate["algebraic_states"].items():
        number = int(symbolic_state.split("_c")[1].split("_")[0])
        cid = f"model1_data{number}"
        t = candidate["state_times"][cid]
        state = mapping[symbolic_state].removesuffix("(t)")
        matrix, initial = systems["raw_seed"][cid]
        prediction = float((expm(matrix * t) @ initial)[states.index(state)])
        state_rows.append(dict(condition=cid, state=state, anchor_time=t,
                               algebraic_root=value, prepared_raw_seed=prediction))
    for filename, content in (("measurements_and_predictions.csv", rows), ("algebraic_states.csv", state_rows)):
        with (args.output / filename).open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(content[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(content)
    report = dict(problem=name, benchmark_revision=revision,
                  canonical_file_sha256={p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in sorted(directory.iterdir()) if p.suffix in (".tsv", ".xml", ".yaml")},
                  measurement_count=len(rows), nllh_constant=constant,
                  scores=scores, physical_parameters=vectors, raw_candidate_index=candidate["index"],
                  raw_preparation_residual=candidate["preparation_residual"], algebraic_states=state_rows,
                  method="Independent matrix exponential of the canonical linear-in-state SBML; no optimization")
    (args.output / "audit.json").write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    colors = dict(ob10="#d97706", obcar="#167d8d", obcry="#8550a0", oohb10="#4575b4", ozea="#438c52")
    titles = ["1: beta-10 initially present", "2: beta-carotene initially present",
              "3: beta-carotene; activity scaled", "4: beta-cryptoxanthin initially present",
              "5: OH-beta-10 initially present", "6: zeaxanthin; activity scaled"]
    fig, axes = plt.subplots(3, 2, figsize=(12, 11), layout="constrained")
    for ax, (cid, condition), title in zip(axes.flat, conditions.items(), titles):
        local = [r for r in rows if r["condition"] == cid]
        for oid in dict.fromkeys(r["observable"] for r in local):
            data = [r for r in local if r["observable"] == oid]
            color = colors[oid]
            ax.errorbar([r["time"] for r in data], [r["measurement"] for r in data],
                        yerr=[r["sigma"] for r in data], fmt="o", markersize=4, capsize=2,
                        color=color, alpha=.85, label=observables[oid])
            times = np.linspace(0, 180, 240)
            for key, style in (("raw_seed", "--"), ("refined", "-")):
                matrix, initial = systems[key][cid]
                curve = [(expm(matrix*t) @ initial)[states.index(observables[oid])] for t in times]
                ax.plot(times, curve, style, color=color, lw=1.7)
        ax.set(title=title, xlabel="Time (minutes)", ylabel="Concentration (benchmark units)")
        ax.spines[["top", "right"]].set_visible(False)
        ax.grid(alpha=.15)
        ax.legend(fontsize=9, frameon=False)
    fig.suptitle("Bruno: all 77 measurements and the recorded six-experiment fit\n"
                 "Dots ± supplied sigma; dashed = prepared algebraic seed; solid = refined fit", fontsize=14)
    fig.savefig(args.output / "bruno_fits.png", dpi=170)
    fig.savefig(args.output / "bruno_fits.pdf")
    plt.close(fig)
    print(json.dumps(dict(nllh_constant=constant, scores=scores), indent=2))


if __name__ == "__main__":
    main()
