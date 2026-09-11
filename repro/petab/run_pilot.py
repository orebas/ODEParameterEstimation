"""Run each requested pilot cell once, with an external model-specific time cap."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import time
import tomllib


def stop_worker(process):
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()


def supervise(process, ready, seconds, *, load_seconds=1800, poll_seconds=0.5):
    launched = time.monotonic()
    deadline = None
    try:
        while process.poll() is None:
            if deadline is None and ready.exists():
                stamp = ready.read_text().strip()
                # Older workers published the file before its contents. Wait
                # for the timestamp instead of abandoning an unsupervised fit.
                if stamp:
                    elapsed = time.time() - float(stamp)
                    deadline = time.monotonic() + max(0, seconds - elapsed)
            if deadline is not None and time.monotonic() >= deadline:
                return "timeout"
            if deadline is None and time.monotonic() - launched > load_seconds:
                return "package_load_timeout"
            time.sleep(poll_seconds)
        return None
    finally:
        # Also contain a worker when monitoring itself raises or is interrupted.
        stop_worker(process)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--models", nargs="+")
    parser.add_argument("--methods", nargs="+", choices=["odepe", "odepe_blocks2", "odepe_blocks4", "odepe_blocks6", "petab_julia", "pypesto_amici"],
                        default=["odepe", "petab_julia", "pypesto_amici"])
    parser.add_argument("--python", type=Path, default=Path("/tmp/odepe-pypesto-env/bin/python"))
    parser.add_argument("--model-root", type=Path, default=Path("/tmp/odepe-petab-full-20260910/Benchmark-Models"))
    parser.add_argument("--output", type=Path, default=Path("repro/petab/results"))
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    config = tomllib.loads((here / "targets.toml").read_text())
    revision = subprocess.check_output(["git", "-C", str(args.model_root), "rev-parse", "HEAD"], text=True).strip()
    if revision != config["benchmark_revision"]:
        raise SystemExit(f"Wrong benchmark revision: {revision}")
    args.output.mkdir(parents=True, exist_ok=True)
    models = args.models or config["main"] + config["challenge"]
    for model in models:
        for method in args.methods:
            prefix = (args.output / f"{model}.{method}").resolve()
            result_path = Path(str(prefix) + ".json")
            if result_path.exists():
                old_status = json.loads(result_path.read_text()).get("status")
                if old_status in ("prepared", "algebraic_complete"):
                    raise SystemExit(f"Cell has an incomplete checkpoint; inspect its worker before resuming: {prefix}")
                print(f"SKIP existing cell {model} {method}", flush=True)
                continue
            command = ["julia", "--startup-file=no", "--compiled-modules=existing",
                       str(here / "run.jl"), model, method, str(args.model_root), str(prefix)]
            if method == "pypesto_amici":
                command = [str(args.python), str(here / "run_pypesto.py"), model,
                           str(args.model_root), str(prefix)]
            ready = Path(str(prefix) + ".ready")
            if ready.exists():
                raise SystemExit(f"Stale running marker {ready}; inspect before resuming")
            print(f"START {model} {method}", flush=True)
            launched = time.monotonic()
            with open(str(prefix) + ".log", "w") as log:
                worker_env = os.environ.copy()
                worker_env["PATH"] = str(args.python.parent) + os.pathsep + worker_env["PATH"]
                for variable in ("JULIA_NUM_THREADS", "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
                    worker_env[variable] = "1"
                worker_env["CMAKE_BUILD_PARALLEL_LEVEL"] = "1"
                process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                           env=worker_env, start_new_session=True)
                status = supervise(process, ready, config["seconds_per_method"])
            result = json.loads(result_path.read_text()) if result_path.exists() else {}
            if status or not result or result.get("status") in ("prepared", "algebraic_complete"):
                result.update(problem=model, method=method, status=status or "worker_failed",
                              returncode=process.returncode, benchmark_revision=revision)
            result["worker_returncode"] = process.returncode
            result["worker_wall_seconds"] = time.monotonic() - launched
            if "total_seconds" not in result and ready.exists() and ready.read_text().strip():
                result["total_seconds"] = time.time() - float(ready.read_text())
            temporary = Path(str(result_path) + ".tmp")
            temporary.write_text(json.dumps(result, indent=2, allow_nan=False) + "\n")
            temporary.replace(result_path)
            print(f"END {model} {method}: {result.get('status')}", flush=True)


if __name__ == "__main__":
    main()
