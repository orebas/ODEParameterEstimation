"""Independently re-evaluate the retained Bruno seeds/fits with canonical AMICI."""
import argparse
import hashlib
import importlib.metadata
import json
import math
from pathlib import Path
import subprocess

import numpy as np
import petab.v1 as petab
from pypesto.petab import PetabImporter


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--model-root", type=Path,
                        default=Path("/tmp/odepe-petab-full-20260910/Benchmark-Models"))
    parser.add_argument("--model-cache", type=Path,
                        default=Path("repro/petab/pilot_results/amici_models"))
    args = parser.parse_args()
    name = "Bruno_JExpBot2016"
    canonical = petab.Problem.from_yaml(str(args.model_root / name / f"{name}.yaml"))
    importer = PetabImporter(canonical, output_folder=str(args.model_cache / name),
                             model_name=name, hierarchical=False)
    problem = importer.create_problem()
    ids = [problem.x_names[i] for i in problem.x_free_indices]
    revision = subprocess.check_output(
        ["git", "-C", str(args.model_root), "rev-parse", "HEAD"], text=True).strip()
    rows = []
    for path in sorted(args.directory.glob(f"{name}.odepe_blocks*.json")):
        record = json.loads(path.read_text())
        if revision != record["benchmark_revision"]:
            raise ValueError("Wrong canonical model revision")
        candidates = record["result"]["candidates"]
        best = min(candidates, key=lambda c: c["nllh"])
        for stage, candidate in (("best_raw", best), ("refined", record["result"]["refined"])):
            mapping = dict(zip(record["parameter_ids"], candidate["x"]))
            if set(mapping) != set(ids):
                raise ValueError("Estimated parameter identities differ")
            x = np.array([mapping[p] for p in ids], dtype=float)
            if not np.all(problem.lb <= x) or not np.all(x <= problem.ub):
                raise ValueError("Retained vector is outside canonical bounds")
            actual = float(problem.objective(x))
            expected = candidate["nllh"]
            if not math.isclose(actual, expected, rel_tol=1e-5, abs_tol=1e-4):
                raise ValueError(f"Objective mismatch: {path}, {stage}, {expected}, {actual}")
            rows.append(dict(method=record["method"], stage=stage,
                             julia_nllh=expected, amici_nllh=actual,
                             absolute_difference=abs(actual-expected)))
    if len(rows) != 6:
        raise ValueError("Expected raw and refined checks for 2, 4 and 6 conditions")
    result = dict(problem=name, benchmark_revision=revision, checks=rows,
                  description="Independent canonical likelihood evaluation; no optimization or new starts",
                  versions={p: importlib.metadata.version(p) for p in ("petab", "pypesto", "amici")},
                  script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    (args.directory / "bruno_amici_validation.json").write_text(
        json.dumps(result, indent=2, allow_nan=False) + "\n")
    print(json.dumps(result, indent=2), flush=True)


if __name__ == "__main__":
    main()
