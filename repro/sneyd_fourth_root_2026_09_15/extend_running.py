"""Extend one owned running study without restarting its expensive HC solve.

The original supervisor predates live budget changes. Pause that supervisor,
monitor the same Julia child, then resume the original supervisor to reap it.
Preserve its original report alongside the explicit extended-budget report.
No Julia code, options, inputs, or solver state are changed.
"""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import time


def process_info(pid):
    try:
        raw = Path(f"/proc/{pid}/stat").read_text()
    except FileNotFoundError:
        return None
    fields = raw[raw.rfind(")")+2:].split()
    return {"state": fields[0], "ppid": int(fields[1]), "start_ticks": int(fields[19])}


def write_json(path, value):
    tmp = path.with_name(path.name+".tmp")
    tmp.write_text(json.dumps(value, indent=2)+"\n")
    tmp.replace(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--seconds", type=float, required=True)
    parser.add_argument("--reason", required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    report_path = out / "budget_extension.json"
    assert not report_path.exists() and not (out / "supervisor.json").exists()
    result = json.loads((out / "result.json").read_text())
    pid = result["pid"]
    info = process_info(pid)
    assert info and info["state"] != "Z"
    parent = info["ppid"]
    parent_info = process_info(parent)
    parent_command = Path(f"/proc/{parent}/cmdline").read_bytes().decode().split("\0")
    child_command = Path(f"/proc/{pid}/cmdline").read_bytes().decode().split("\0")
    # Verify both processes belong to exactly this study before signaling either.
    assert str(out) in parent_command and any(arg.endswith("/supervise.py") for arg in parent_command)
    assert str(out / "source/run.jl") in child_command
    original_cap = float(parent_command[parent_command.index("--seconds")+1])
    assert args.seconds > original_cap
    stage_start = result["estimation_started_ns"] / 1e9
    assert time.monotonic()-stage_start < original_cap
    report = {"status": "extending", "reason": args.reason, "pid": pid,
              "original_supervisor_pid": parent, "original_supervisor_command": parent_command,
              "original_estimation_seconds_cap": original_cap,
              "estimation_seconds_cap": args.seconds,
              "extension_at_estimation_seconds": time.monotonic()-stage_start,
              "worker_start_ticks": info["start_ticks"], "profile_signals": []}
    write_json(report_path, report)
    last_profile = time.monotonic()
    os.kill(parent, signal.SIGSTOP)
    print("EXTENDED", pid, original_cap, "->", args.seconds, flush=True)

    def running():
        current = process_info(pid)
        return current and current["start_ticks"] == info["start_ticks"] and current["state"] != "Z"

    try:
        while running():
            elapsed = time.monotonic()-stage_start
            if elapsed >= original_cap and not (out / "original_budget_checkpoint.json").exists():
                checkpoint = json.loads((out / "result.json").read_text())
                log = (out / "worker.log").read_text().replace("\r", "\n")
                latest = lambda pattern: re.findall(pattern,log)[-1:]
                write_json(out / "original_budget_checkpoint.json", {
                    "measured_estimation_seconds": elapsed, "worker_checkpoint": checkpoint,
                    "tracking_total": latest(r"Tracking (\d+) paths"),
                    "paths_tracked": latest(r"# paths tracked: ([^\x1b\n]+)"),
                    "nonsingular_solutions": latest(r"# non-singular solutions \(real\): ([^\x1b\n]+)"),
                    "total_solutions": latest(r"# total solutions \(real\): ([^\x1b\n]+)")})
            if elapsed >= args.seconds:
                report.update(status="timeout", measured_stage_seconds=elapsed)
                # Same bounded shutdown protocol as the original supervisor.
                for sig, grace in ((signal.SIGINT,20),(signal.SIGTERM,10),(signal.SIGKILL,5)):
                    if not running():
                        break
                    os.kill(pid,sig)
                    deadline = time.monotonic()+grace
                    while running() and time.monotonic()<deadline:
                        time.sleep(0.2)
                break
            if time.monotonic()-last_profile >= 60:
                os.kill(pid,signal.SIGUSR1)
                report["profile_signals"].append(elapsed)
                last_profile = time.monotonic()
                write_json(report_path,report)
            time.sleep(1)
    finally:
        # Returning control also restores the original watchdog if this extension
        # is interrupted. Never leave a paused supervisor behind.
        current_parent = process_info(parent)
        if current_parent and current_parent["start_ticks"] == parent_info["start_ticks"]:
            os.kill(parent,signal.SIGCONT)
    deadline = time.monotonic()+30
    while not (out / "supervisor.json").exists() and time.monotonic()<deadline:
        time.sleep(0.2)
    original = json.loads((out / "supervisor.json").read_text())
    write_json(out / "original_supervisor.json", original)
    report.setdefault("measured_stage_seconds",time.monotonic()-stage_start)
    if report["status"] == "extending":
        report["status"] = original["status"]
    write_json(report_path,report)
    updated = dict(original, status=report["status"],
                   estimation_seconds_cap=args.seconds,
                   original_estimation_seconds_cap=original_cap,
                   budget_extension="budget_extension.json")
    write_json(out / "supervisor.json",updated)
    print("EXTENSION_END",report["status"],flush=True)


if __name__ == "__main__":
    main()
