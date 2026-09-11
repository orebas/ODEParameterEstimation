"""One AMICI/Fides-BFGS fit, using the recorded Julia starting vector by name."""
import importlib.metadata
import hashlib
import json
import logging
import math
import os
from pathlib import Path
import sys
import time
import traceback
import tomllib

import amici
import fides
import numpy as np
import petab.v1 as petab
from pypesto.petab import PetabImporter
from pypesto.optimize import FidesOptimizer


def safe(value):
    if isinstance(value, np.ndarray):
        return safe(value.tolist())
    if isinstance(value, dict):
        return {str(k): safe(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [safe(v) for v in value]
    if isinstance(value, (float, np.floating)):
        return float(value) if math.isfinite(value) else str(value)
    if isinstance(value, np.integer):
        return int(value)
    return value


def main():
    name, root, prefix = sys.argv[1:]
    root, prefix = Path(root), Path(prefix)
    config = tomllib.loads(Path(__file__).with_name("targets.toml").read_text())
    started = time.time()
    marker = Path(str(prefix) + ".ready.tmp")
    marker.write_text(str(started))
    marker.replace(Path(str(prefix) + ".ready"))
    result_path = Path(str(prefix) + ".json")
    record = dict(problem=name, method="pypesto_amici", seconds_cap=config["seconds_per_method"],
                  benchmark_revision=config["benchmark_revision"], seed=config["seed"],
                  worker_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  thread_settings={k: os.environ.get(k, "unset") for k in
                      ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "CMAKE_BUILD_PARALLEL_LEVEL")},
                  versions={p: importlib.metadata.version(p) for p in ("amici", "pypesto", "petab", "fides", "numpy", "scipy")})

    def write():
        temp = Path(str(result_path) + ".tmp")
        temp.write_text(json.dumps(safe(record), indent=2, allow_nan=False) + "\n")
        temp.replace(result_path)

    try:
        path = root / name / f"{name}.yaml"
        if not path.exists():
            path = root / name / "problem.yaml"
        petab_problem = petab.Problem.from_yaml(str(path))
        importer = PetabImporter(petab_problem,
            output_folder=str(prefix.parent / "amici_models" / name), model_name=name,
            hierarchical=False)
        problem = importer.create_problem()
        solver = problem.objective.amici_solver
        record["ode_solver"] = type(solver).__name__
        record["ode_tolerances"] = dict(abstol=solver.get_absolute_tolerance(),
                                        reltol=solver.get_relative_tolerance())
        record["python_version"] = sys.version
        record["optimizer_options"] = dict(hessian="BFGS", maxiter=10000,
            fatol=1e-8, frtol=1e-8, gatol=1e-6, grtol=0.0, xtol=0.0)
        start = json.loads((prefix.parent / f"{name}.start.json").read_text())
        mapping = dict(zip(start["parameter_ids"], start["x"]))
        free_ids = [problem.x_names[i] for i in problem.x_free_indices]
        if set(free_ids) != set(mapping):
            raise ValueError("The two implementations disagree on estimated parameter identities")
        x0 = np.array([mapping[xid] for xid in free_ids], dtype=float)
        initial = float(problem.objective(x0))
        record.update(parameter_ids=free_ids, x0=x0, initial_nllh=initial,
                      preparation_seconds=time.time()-started, status="prepared")
        write()
        julia_path = prefix.parent / f"{name}.petab_julia.json"
        if julia_path.exists():
            julia = json.loads(julia_path.read_text())
            other = float(julia["initial_nllh"])
            if math.isfinite(initial) != math.isfinite(other) or (math.isfinite(initial) and not math.isclose(initial, other, rel_tol=1e-5, abs_tol=1e-4)):
                raise ValueError(f"Initial objective mismatch: AMICI={initial}, Julia={other}")
        remaining = config["seconds_per_method"] - (time.time() - started)
        if remaining <= 0:
            raise TimeoutError("Model preparation exhausted the budget")
        optimizer = FidesOptimizer(hessian_update=fides.BFGS(),
            options={"maxtime": remaining, "maxiter": 10000}, verbose=logging.WARNING)
        result = optimizer.minimize(problem, x0, id="0")
        x = None if result.x is None else np.asarray(result.x)
        if x is not None and x.ndim == 1 and len(x) == len(problem.x_names):
            x = x[problem.x_free_indices]
        converged = int(result.exitflag or 0) > 0
        record.update(status=("success" if converged else "optimizer_stopped") if math.isfinite(result.fval) else "optimization_failed",
                      result=dict(x=x, nllh=result.fval, status=str(result.exitflag),
                                  converged=converged, message=str(result.message)))
    except Exception:
        record.update(status="failed", error=traceback.format_exc())
    record["total_seconds"] = time.time() - started
    write()
    print(name, record["status"], flush=True)


if __name__ == "__main__":
    main()
