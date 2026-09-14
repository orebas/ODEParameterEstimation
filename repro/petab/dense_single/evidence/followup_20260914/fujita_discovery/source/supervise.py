"""Bound one dense-data study, saving live profiles and a separate timeout record."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import shutil
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", choices=("bruno", "fujita", "sneyd", "sneyd_profile", "fujita_tracking", "fujita_discovery"))
    parser.add_argument("output", type=Path)
    parser.add_argument("--seconds", type=float, default=1200)
    parser.add_argument("--input", type=Path, help="Exact start pairs for Fujita tracking/discovery")
    args = parser.parse_args()
    tracking = args.model in ("fujita_tracking", "fujita_discovery")
    if tracking != (args.input is not None):
        parser.error("--input is required only for Fujita tracking/discovery")
    here = Path(__file__).resolve().parent
    out = args.output.resolve()
    if out.exists():
        raise SystemExit("Use a fresh output directory")
    out.mkdir(parents=True)
    command = ["julia", "--startup-file=no", "--compiled-modules=existing"]
    if tracking:
        source = out / "source"
        source.mkdir()
        worker = source / "track_fujita_known_starts.jl"
        shutil.copyfile(here / worker.name, worker)
        shutil.copyfile(__file__, source / Path(__file__).name)
        shutil.copyfile(args.input, out / "input.json")
        command += [str(worker), str(out / "input.json"), str(out)]
        if args.model == "fujita_discovery":
            command += ["monodromy"]
    elif args.model == "sneyd_profile":
        command += [str(here / "profile_denominators.jl"), str(out)]
    else:
        model, condition = {"bruno": ("Bruno_JExpBot2016", "model1_data4"),
                            "fujita": ("Fujita_SciSignal2010", "condition_step_01_0"),
                            "sneyd": ("Sneyd_PNAS2002", "Ca_dose_response__1")}[args.model]
        command += [str(here / "run.jl"), model, condition, str(out)]
    env = os.environ.copy()
    for key in ("JULIA_NUM_THREADS", "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
        env[key] = "1"
    started = time.monotonic()
    last_profile = started
    report = {"command": command, "stage_seconds_cap": args.seconds,
              "load_and_preparation_seconds_cap": 600, "profile_signals": []}
    print("START", args.model, flush=True)
    with (out / "worker.log").open("w") as log:
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                   env=env, start_new_session=True)
        report["pid"] = process.pid
        try:
            while process.poll() is None:
                path = out / "result.json"
                checkpoint = json.loads(path.read_text()) if path.exists() else {}
                stage_start = checkpoint.get("estimation_started_unix")
                stage_elapsed = time.time() - stage_start if stage_start else None
                elapsed = time.monotonic() - started
                if (stage_elapsed is not None and stage_elapsed >= args.seconds) or (stage_start is None and elapsed >= 600):
                    report.update(status="timeout", last_checkpoint_status=checkpoint.get("status"),
                                  measured_stage_seconds=stage_elapsed)
                    break
                if (stage_start or checkpoint.get("profile_ready")) and time.monotonic() - last_profile > 60:
                    os.kill(process.pid, signal.SIGUSR1)
                    report["profile_signals"].append(time.time())
                    last_profile = time.monotonic()
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
    report.update(returncode=process.returncode, wall_seconds=time.monotonic()-started)
    result_path = out / "result.json"
    final = json.loads(result_path.read_text()) if result_path.exists() else {}
    report.setdefault("status", final.get("status", "worker_failed"))
    (out / "supervisor.json").write_text(json.dumps(report, indent=2) + "\n")
    print("END", args.model, report["status"], flush=True)


if __name__ == "__main__":
    main()
