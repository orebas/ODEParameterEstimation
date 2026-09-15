"""Run the saved-root anchor comparison with a wall limit and retained log."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_run", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--seconds", type=float, default=1800)
    args = parser.parse_args()
    if args.seconds <= 0:
        parser.error("--seconds must be positive")
    out = args.output.resolve()
    log_path = out.with_name(out.name+".worker.log")
    if out.exists() or log_path.exists():
        parser.error("Use a fresh output path")
    command = ["julia", "--startup-file=no", "--compiled-modules=existing",
               str(Path(__file__).with_name("replay_targets.jl").resolve()),
               str(args.source_run.resolve()), str(out)]
    env = os.environ.copy()
    for key in ("JULIA_NUM_THREADS", "OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS"):
        env[key] = "1"
    started = time.monotonic()
    report = {"command": command, "wall_seconds_cap": args.seconds}
    with log_path.open("w") as log:
        process = subprocess.Popen(command, env=env, stdout=log,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        report["pid"] = process.pid
        try:
            process.wait(timeout=args.seconds)
        except subprocess.TimeoutExpired:
            report["status"] = "timeout"
            os.killpg(process.pid, signal.SIGINT)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
    out.mkdir(exist_ok=True)
    log_path.rename(out/"worker.log")
    path = out/"result.json"
    result = json.loads(path.read_text()) if path.exists() else {}
    report.setdefault("status", result.get("status", "worker_failed") if process.returncode == 0 else "worker_failed")
    report.update(returncode=process.returncode, elapsed_seconds=time.monotonic()-started)
    (out/"supervisor.json").write_text(json.dumps(report, indent=2)+"\n")
    (out/"supervise_replay.py").write_bytes(Path(__file__).read_bytes())
    print(json.dumps(report), flush=True)


if __name__ == "__main__":
    main()
