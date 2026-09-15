"""Bound one matched Sneyd observation-transformation experiment."""
import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--model", choices=("free", "rational"), default="free")
    parser.add_argument("--observation", choices=("quartic", "root"), default="root")
    parser.add_argument("--phase", choices=("estimate", "selection", "multiplicity", "global", "functions", "local", "denominators"), default="estimate")
    parser.add_argument("--seconds", type=float, default=5400)
    parser.add_argument("--cache", type=Path, required=True)
    parser.add_argument("--anchor-mode", choices=("exclude_zero", "all", "midpoint"), default="exclude_zero")
    args = parser.parse_args()
    if args.seconds <= 0:
        parser.error("--seconds must be positive")
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    source = out / "source"
    source.mkdir()
    here = Path(__file__).resolve().parent
    for filename in ("model.jl", "run.jl", "coefficient_model.jl", "dense_common.jl", "capture_and_solve.jl", "probes.jl", "anchor_hooks.jl", "supervise.py"):
        shutil.copyfile(here / filename, source / filename)
    shutil.copyfile(args.spec, out / "spec.json")
    import gzip
    baseline = here.parent / "sneyd_fourth_root_2026_09_15/evidence/free_root/generic_system_1.json.gz"
    (out / "baseline_family.json").write_bytes(gzip.decompress(baseline.read_bytes()))
    command = ["julia", "--startup-file=no", "--compiled-modules=existing",
               str(source / "run.jl"), str(out / "spec.json"), str(out), args.model, args.observation, args.phase]
    env = os.environ.copy()
    env["ODEPE_SNEYD_START_CACHE"] = str(args.cache.resolve())
    env["ODEPE_SNEYD_ANCHOR_MODE"] = args.anchor_mode
    for key in ("JULIA_NUM_THREADS", "OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS"):
        env[key] = "1"
    started = time.monotonic()
    stage_started = None
    last_profile = started
    report = {"command": command, "estimation_seconds_cap": args.seconds,
              "loading_and_preparation_seconds_cap": 600, "profile_signals": [], "source_revision": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()}
    print("START", (args.model, args.observation, args.phase), flush=True)
    with (out / "worker.log").open("w") as log:
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                   env=env, start_new_session=True)
        report["pid"] = process.pid
        try:
            while process.poll() is None:
                path = out / "result.json"
                checkpoint = json.loads(path.read_text()) if path.exists() else {}
                now = time.monotonic()
                if stage_started is None and checkpoint.get("estimation_started_ns"):
                    stage_started = checkpoint["estimation_started_ns"] / 1e9
                    if not started <= stage_started <= now:
                        raise RuntimeError("Worker and supervisor monotonic clocks disagree")
                elapsed = now - (stage_started if stage_started is not None else started)
                cap = args.seconds if stage_started is not None else 600
                if elapsed >= cap:
                    report.update(status="timeout", last_stage=checkpoint.get("status"),
                                  measured_stage_seconds=elapsed)
                    break
                if checkpoint.get("profile_ready") and now - last_profile >= 60:
                    os.kill(process.pid, signal.SIGUSR1)
                    report["profile_signals"].append(now - started)
                    last_profile = now
                time.sleep(1)
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGINT)
                try:
                    process.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
    final_path = out / "result.json"
    final = json.loads(final_path.read_text()) if final_path.exists() else {}
    report.setdefault("status", final.get("status", "worker_failed"))
    report.update(returncode=process.returncode, elapsed_seconds=time.monotonic()-started)
    (out / "supervisor.json").write_text(json.dumps(report, indent=2) + "\n")
    print("END", (args.model, args.observation, args.phase), report["status"], flush=True)


if __name__ == "__main__":
    main()
