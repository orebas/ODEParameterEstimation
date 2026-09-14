"""Run one validation worker with retained progress, profiles, and an external cap."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import time
import tomllib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", choices=("biohydrogenation", "repressilator", "fitzhugh_nagumo", "sneyd"))
    parser.add_argument("output", type=Path)
    parser.add_argument("--seconds", type=float, default=3600)
    parser.add_argument("--si-fix-strategy", choices=("local_basis", "identifiable_functions"))
    parser.add_argument("--julia-optimize", type=int, choices=(0, 1, 2, 3),
                        help="Optional Julia LLVM optimization level for a separate compiler diagnostic")
    args = parser.parse_args()
    if args.si_fix_strategy and args.model == "sneyd":
        parser.error("--si-fix-strategy applies to estimation workers, not the Sneyd derivative-construction probe")
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    here = Path(__file__).resolve().parent
    command = ["julia", "--startup-file=no", "--compiled-modules=existing"]
    if args.julia_optimize is not None:
        command.append(f"--optimize={args.julia_optimize}")
    if args.model == "sneyd":
        command += [str(here / "run_sneyd.jl"), str(out)]
    else:
        command += [str(here / "run_rational.jl"), args.model, str(out)]
    env = os.environ.copy()
    if args.si_fix_strategy:
        env["ODEPE_SI_FIX_STRATEGY"] = args.si_fix_strategy
    for key in ("JULIA_NUM_THREADS", "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
        env[key] = "1"
    report = {"command": command, "stage_seconds_cap": args.seconds,
              "preparation_seconds_cap": 900, "profile_signals": []}

    def checkpoint():
        if (out / "result.toml").exists():
            return tomllib.loads((out / "result.toml").read_text())
        if (out / "result.json").exists():
            return json.loads((out / "result.json").read_text())
        return {}

    started = last_profile = time.monotonic()
    with (out / "worker.log").open("w") as log:
        worker = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, env=env, start_new_session=True)
        report["pid"] = worker.pid
        (out / "supervisor.json").write_text(json.dumps(report, indent=2) + "\n")
        print("START", args.model, worker.pid, flush=True)
        try:
            while worker.poll() is None:
                current = checkpoint()
                stage_start = current.get("estimation_started_unix")
                elapsed = time.monotonic() - started
                if (stage_start and time.time() - stage_start >= args.seconds) or (not stage_start and elapsed >= 900):
                    report.update(status="timeout", last_checkpoint_status=current.get("status"))
                    break
                if current.get("profile_ready") and time.monotonic() - last_profile >= 120:
                    os.kill(worker.pid, signal.SIGUSR1)
                    report["profile_signals"].append(time.time())
                    last_profile = time.monotonic()
                time.sleep(1)
        finally:
            if worker.poll() is None:
                for sig, seconds in ((signal.SIGINT, 20), (signal.SIGTERM, 10), (signal.SIGKILL, 10)):
                    os.killpg(worker.pid, sig)
                    try:
                        worker.wait(timeout=seconds)
                        break
                    except subprocess.TimeoutExpired:
                        continue
    report.update(returncode=worker.returncode, wall_seconds=time.monotonic()-started)
    report.setdefault("status", checkpoint().get("status", "worker_failed"))
    (out / "supervisor.json").write_text(json.dumps(report, indent=2) + "\n")
    print("END", args.model, report["status"], flush=True)
    raise SystemExit(0 if report["status"] in ("complete", "rank_deficient_at_limit") else 1)


if __name__ == "__main__":
    main()
