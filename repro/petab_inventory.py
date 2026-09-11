"""Inventory canonical PEtab v1 benchmark files without simulation.

Usage: python3 repro/petab_inventory.py CHECKOUT OUTPUT.csv
Requires PyYAML. Reads an existing Benchmark-Models-PEtab checkout; does not
download packages, import PEtab, or change the checkout. Counts describe file
contents, not ODEPE support, identifiability, or successful parameter recovery.
"""

import argparse
from collections import Counter, defaultdict
import csv
import math
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

import yaml


def local_name(element):
    return element.tag.rsplit("}", 1)[-1]


def read_tsv(path):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def inventory(directory, revision):
    # Same canonical YAML selection as the collection's get_problem_yaml_path.
    yaml_path = directory / (directory.name + ".yaml")
    if not yaml_path.exists():
        yaml_path = directory / "problem.yaml"
    if not yaml_path.exists():
        return None
    specification = yaml.safe_load(yaml_path.read_text())
    if specification.get("format_version") != 1 or len(specification["problems"]) != 1:
        raise ValueError(f"Review new format or multiple problem blocks: {yaml_path}")
    problem = specification["problems"][0]
    if len(problem["sbml_files"]) != 1:
        raise ValueError(f"Review multiple SBML models: {yaml_path}")
    parameters = read_tsv(directory / specification["parameter_file"])
    measurements = [row for name in problem["measurement_files"]
                    for row in read_tsv(directory / name)]
    observables = [row for name in problem["observable_files"]
                   for row in read_tsv(directory / name)]
    # Also read condition tables, and check every referenced condition exists.
    conditions = [row for name in problem["condition_files"]
                  for row in read_tsv(directory / name)]
    condition_ids = {row["conditionId"] for row in conditions}
    model = ET.parse(directory / problem["sbml_files"][0]).getroot().find("{*}model")
    if model is None:
        raise ValueError(f"Missing SBML model: {yaml_path}")
    rules = model.findall("{*}listOfRules/*")
    math_containers = (model.findall("{*}listOfReactions/{*}reaction/{*}kineticLaw")
                       + rules
                       + model.findall("{*}listOfFunctionDefinitions/*"))
    piecewise_blocks = sum(local_name(node) == "piecewise"
                           for container in math_containers for node in container.iter())
    series = defaultdict(set)
    samples = Counter()
    condition_pairs = set()
    infinite_rows = 0
    for row in measurements:
        pair = (row.get("preequilibrationConditionId", ""), row["simulationConditionId"])
        if any(name and name not in condition_ids for name in pair):
            raise ValueError(f"Undefined condition in {yaml_path}: {pair}")
        condition_pairs.add(pair)
        # Different observable overrides can represent different signals/batches.
        # Noise overrides do not change signal identity; preserve their rows.
        signal = (*pair, row["observableId"], row.get("observableParameters", ""))
        time = float(row["time"])
        if math.isfinite(time):
            series[signal].add(time)
        elif time == math.inf:
            infinite_rows += 1
        else:
            raise ValueError(f"Invalid measurement time in {yaml_path}: {time}")
        samples[(*signal, time)] += 1
    by_condition = defaultdict(list)
    for key, times in series.items():
        by_condition[key[:2]].append(times)
    finite_counts = [len(times) for times in series.values()]
    finite_times = set().union(*series.values()) if series else set()
    return {
        "problem": directory.name,
        "revision": revision,
        "species": len(model.findall("{*}listOfSpecies/{*}species")),
        "rate_rule_variables": ";".join(node.get("variable") for node in rules
                                        if local_name(node) == "rateRule"),
        "estimated_parameters": sum(row["estimate"] == "1" for row in parameters),
        "condition_pairs": len(condition_pairs),
        "measurements": len(measurements),
        "observables": len({row["observableId"] for row in measurements}),
        "finite_series": len(series),
        "finite_times_min_per_series": min(finite_counts, default=0),
        "finite_times_max_per_series": max(finite_counts, default=0),
        "series_with_at_most_two_times": sum(n <= 2 for n in finite_counts),
        "finite_time_min": min(finite_times, default=""),
        "finite_time_max": max(finite_times, default=""),
        "replicate_excess_rows": sum(n - 1 for n in samples.values()),
        "conditions_with_unequal_grids": sum(any(times != grids[0] for times in grids[1:])
                                             for grids in by_condition.values()),
        "preequilibration_conditions": len({a for a, _ in condition_pairs if a}),
        "infinite_time_rows": infinite_rows,
        "events": len(model.findall("{*}listOfEvents/{*}event")),
        "sbml_piecewise_blocks": piecewise_blocks,
        "initial_assignments": len(model.findall("{*}listOfInitialAssignments/*")),
        "observation_overrides": int(any(row.get("observableParameters") for row in measurements)),
        "noise_overrides": int(any(row.get("noiseParameters") for row in measurements)),
        "observation_transformations": ";".join(sorted({row.get("observableTransformation") or "lin"
                                                       for row in observables})),
        "noise_distributions": ";".join(sorted({row.get("noiseDistribution") or "normal"
                                              for row in observables})),
        "objective_priors": ";".join(sorted({row["objectivePriorType"] for row in parameters
                                            if row["estimate"] == "1" and row.get("objectivePriorType")})),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    revision = subprocess.check_output(
        ["git", "-C", str(args.checkout), "rev-parse", "HEAD"], text=True,
    ).strip()
    rows = [inventory(directory, revision)
            for directory in sorted((args.checkout / "Benchmark-Models").iterdir())
            if directory.is_dir()]
    rows = [row for row in rows if row is not None]
    if not rows:
        raise ValueError("No canonical benchmark problems found")
    with args.output.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"Inventoried {len(rows)} problems at {revision} into {args.output}")


if __name__ == "__main__":
    main()
