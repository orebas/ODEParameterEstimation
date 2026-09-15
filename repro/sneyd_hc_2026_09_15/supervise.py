"""Bound a captured-system HC diagnostic with a monotonic operation clock."""
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
    parser.add_argument("system", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("mode", choices=("polyhedral", "monodromy"))
    parser.add_argument("--seconds", type=float, default=1800)
    parser.add_argument("--known-start", type=Path, help="Independent exact start for monodromy only")
    args = parser.parse_args()
    if args.seconds <= 0:
        parser.error("--seconds must be positive")
    if args.known_start and args.mode != "monodromy":
        parser.error("--known-start applies only to monodromy")
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    source = out / "source"
    source.mkdir()
    worker = Path(__file__).with_name("probe.jl")
    for path in (worker, Path(__file__)):
        shutil.copyfile(path, source / path.name)
    shutil.copyfile(args.system, out / "system.json")
    command = ["julia", "--startup-file=no", "--compiled-modules=existing",
               str(source / worker.name), str(out / "system.json"), str(out),
               args.mode, str(args.seconds)]
    if args.known_start:
        shutil.copyfile(args.known_start, out / "known_start.json")
        command.append(str(out / "known_start.json"))
    env = os.environ.copy()
    for key in ("JULIA_NUM_THREADS", "OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS"):
        env[key] = "1"
    started = time.monotonic()
    operation_started = None
    last_profile = started
    report = {"command": command, "operation_seconds_cap": args.seconds,
              "loading_seconds_cap": 300, "profile_signals": []}
    with (out / "worker.log").open("w") as log:
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                   env=env, start_new_session=True)
        report["pid"] = process.pid
        try:
            while process.poll() is None:
                path = out / "result.json"
                checkpoint = json.loads(path.read_text()) if path.exists() else {}
                now = time.monotonic()
                if operation_started is None and checkpoint.get("operation_started_ns"):
                    # Both Python monotonic_ns and Julia time_ns use CLOCK_MONOTONIC on this host.
                    operation_started = checkpoint["operation_started_ns"] / 1e9
                    if not started <= operation_started <= now:
                        raise RuntimeError("Worker and supervisor monotonic clocks disagree")
                elapsed = now - (operation_started if operation_started is not None else started)
                cap = args.seconds if operation_started is not None else 300
                if elapsed >= cap:
                    report.update(status="timeout", last_stage=checkpoint.get("status"),
                                  operation_elapsed_seconds=elapsed)
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
    print("END", args.mode, report["status"], flush=True)


if __name__ == "__main__":
    main()
