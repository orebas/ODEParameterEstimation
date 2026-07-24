#!/usr/bin/env python3
"""Run a bounded Julia SIGTERM termination ladder.

Every case must emit its explicit READY marker before the runner sends SIGTERM.
The runner waits a fixed grace period, escalates the private process group to
SIGKILL if necessary, and persists one JSON record after every run.
"""

from __future__ import annotations

import argparse
import datetime
import json
import math
import os
from pathlib import Path
import platform
import shutil
import shlex
import signal
import subprocess
import sys
import time
from typing import Any


CASES = (
    ("base_idle", "base_idle.jl"),
    ("hc_idle", "hc_idle.jl"),
    ("odepe_idle", "odepe_idle.jl"),
)
COMMON_READY_FIELDS = {
    "case",
    "pid",
    "julia",
    "julia_executable",
    "active_project",
    "load_path",
    "depot_path",
    "threads",
    "gc_threads",
}
CASE_READY_FIELDS = {
    "base_idle": set(),
    "hc_idle": {"hc", "nsolutions"},
    "odepe_idle": {
        "odepe",
        "odepe_path",
        "source_root",
        "source_commit",
        "source_tree",
        "source_dirty",
    },
}


def utc_now() -> str:
    return (
        datetime.datetime.now(datetime.timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z")
    )


def positive_float(text: str) -> float:
    value = float(text)
    if not math.isfinite(value) or value <= 0:
        raise argparse.ArgumentTypeError("must be a finite number greater than zero")
    return value


def positive_integer(text: str) -> int:
    value = int(text)
    if value < 1:
        raise argparse.ArgumentTypeError("must be at least one")
    return value


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, help="new results directory")
    parser.add_argument("--repetitions", type=positive_integer, default=3)
    parser.add_argument(
        "--repetition-start",
        type=positive_integer,
        default=1,
        help="first repetition label (default: 1)",
    )
    parser.add_argument(
        "--case",
        dest="selected_cases",
        action="append",
        choices=[case for case, _ in CASES],
        help="run only this case; may be repeated (default: all cases)",
    )
    parser.add_argument(
        "--ready-timeout-seconds",
        type=positive_float,
        default=180.0,
    )
    parser.add_argument(
        "--term-grace-seconds",
        type=positive_float,
        default=15.0,
    )
    parser.add_argument(
        "--kill-wait-seconds",
        type=positive_float,
        default=5.0,
    )
    parser.add_argument(
        "--expected-odepe-root",
        help="require the ODEPE READY source root and active project to match",
    )
    parser.add_argument("--julia", default="julia")
    return parser.parse_args(argv)


def atomic_json(path: Path, value: Any) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def group_exists(pgid: int) -> bool:
    try:
        os.killpg(pgid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def signal_group(pgid: int, sig: int) -> bool:
    try:
        os.killpg(pgid, sig)
        return True
    except ProcessLookupError:
        return False


def wait_for_group(
    process: subprocess.Popen[bytes],
    pgid: int,
    timeout_seconds: float,
) -> bool:
    deadline = time.monotonic() + timeout_seconds
    while True:
        process.poll()
        if not group_exists(pgid):
            return True
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return False
        time.sleep(min(0.05, remaining))


def wait_for_ready(
    process: subprocess.Popen[bytes],
    log_path: Path,
    case: str,
    timeout_seconds: float,
) -> tuple[bool, str, str | None, dict[str, str] | None]:
    deadline = time.monotonic() + timeout_seconds
    offset = 0
    carry = b""
    while True:
        try:
            with log_path.open("rb") as handle:
                handle.seek(offset)
                chunk = handle.read()
                offset = handle.tell()
        except FileNotFoundError:
            chunk = b""
        if chunk:
            carry += chunk
            lines = carry.split(b"\n")
            carry = lines.pop()
            for raw_line in lines:
                ready_fields = parse_ready_line(raw_line, case, process.pid)
                if ready_fields is not None:
                    ready_line = raw_line.decode("utf-8", errors="strict")
                    return True, "ready", ready_line, ready_fields
        returncode = process.poll()
        if returncode is not None:
            return False, "exited_before_ready", None, None
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return False, "ready_timeout", None, None
        time.sleep(min(0.05, remaining))


def parse_ready_line(
    raw_line: bytes,
    expected_case: str,
    expected_pid: int,
) -> dict[str, str] | None:
    try:
        line = raw_line.decode("utf-8", errors="strict")
    except UnicodeDecodeError:
        return None
    if not line or "\r" in line:
        return None
    parts = line.split("\t")
    if not parts or parts[0] != "READY":
        return None
    fields: dict[str, str] = {}
    for part in parts[1:]:
        if "=" not in part:
            return None
        key, value = part.split("=", 1)
        if not key or key in fields:
            return None
        fields[key] = value
    required = COMMON_READY_FIELDS | CASE_READY_FIELDS[expected_case]
    if not required.issubset(fields):
        return None
    if fields["case"] != expected_case or fields["pid"] != str(expected_pid):
        return None
    return fields


def verify_ready_provenance(
    case: str,
    fields: dict[str, str],
    julia_executable_proc: str | None,
    expected_odepe_root: str | None,
) -> tuple[bool, dict[str, bool]]:
    checks = {
        "julia_executable_matches_proc": (
            julia_executable_proc is not None
            and os.path.realpath(fields["julia_executable"])
            == os.path.realpath(julia_executable_proc)
        ),
        "active_project_recorded": bool(fields["active_project"]),
        "load_path_recorded": bool(fields["load_path"]),
        "depot_path_recorded": bool(fields["depot_path"]),
    }
    if case == "odepe_idle":
        source_root = os.path.realpath(fields["source_root"])
        odepe_path = os.path.realpath(fields["odepe_path"])
        checks.update(
            {
                "odepe_path_matches_source_root": (
                    odepe_path
                    == os.path.join(
                        source_root,
                        "src",
                        "ODEParameterEstimation.jl",
                    )
                ),
                "source_commit_is_hex40": (
                    len(fields["source_commit"]) == 40
                    and all(
                        character in "0123456789abcdef"
                        for character in fields["source_commit"].lower()
                    )
                ),
                "source_tree_is_hex40": (
                    len(fields["source_tree"]) == 40
                    and all(
                        character in "0123456789abcdef"
                        for character in fields["source_tree"].lower()
                    )
                ),
                "source_dirty_is_boolean": fields["source_dirty"]
                in {"true", "false"},
            }
        )
        if expected_odepe_root is not None:
            expected_root = os.path.realpath(expected_odepe_root)
            checks.update(
                {
                    "source_root_matches_expected": source_root
                    == expected_root,
                    "active_project_matches_expected": (
                        os.path.realpath(fields["active_project"])
                        == os.path.join(expected_root, "Project.toml")
                    ),
                    "load_path_contains_expected_project": (
                        os.path.join(expected_root, "Project.toml")
                        in fields["load_path"].split(";")
                    ),
                }
            )
    return all(checks.values()), checks


def normalized_returncode(returncode: int | None) -> int | None:
    if returncode is None:
        return None
    return 128 + (-returncode) if returncode < 0 else returncode


def proc_starttime(pid: int) -> int | None:
    try:
        text = Path(f"/proc/{pid}/stat").read_text(encoding="utf-8")
        fields = text[text.rfind(")") + 2 :].split()
        return int(fields[19])
    except (FileNotFoundError, PermissionError, ValueError, IndexError):
        return None


def ambient_julia_processes() -> list[dict[str, Any]]:
    processes: list[dict[str, Any]] = []
    for entry in Path("/proc").iterdir():
        if not entry.name.isdecimal():
            continue
        try:
            executable = os.readlink(entry / "exe")
            if "julia" not in os.path.basename(executable):
                continue
            stat_text = (entry / "stat").read_text(encoding="utf-8")
            stat_fields = stat_text[stat_text.rfind(")") + 2 :].split()
            command = (
                (entry / "cmdline")
                .read_bytes()
                .replace(b"\0", b" ")
                .decode("utf-8", errors="replace")
                .strip()
            )
            processes.append(
                {
                    "pid": int(entry.name),
                    "ppid": int(stat_fields[1]),
                    "state": stat_fields[0],
                    "starttime": int(stat_fields[19]),
                    "executable": executable,
                    "command": command,
                }
            )
        except (FileNotFoundError, PermissionError, ValueError, IndexError, OSError):
            continue
    return sorted(processes, key=lambda process: process["pid"])


def run_case(
    *,
    case: str,
    script_path: Path,
    repetition: int,
    julia: str,
    logs_dir: Path,
    ready_timeout_seconds: float,
    term_grace_seconds: float,
    kill_wait_seconds: float,
    expected_odepe_root: str | None,
) -> dict[str, Any]:
    command = [julia, "--startup-file=no", str(script_path)]
    log_path = logs_dir / f"{case}_rep{repetition:02d}.log"
    started_ns = time.monotonic_ns()
    record: dict[str, Any] = {
        "case": case,
        "repetition": repetition,
        "command": command,
        "command_shell": shlex.join(command),
        "log": str(log_path),
        "started_utc": utc_now(),
        "ready_observed": False,
        "ready_status": None,
        "ready_seconds": None,
        "ready_line": None,
        "ready_fields": None,
        "provenance_verified": False,
        "provenance_checks": None,
        "term_attempted": False,
        "term_attempt_utc": None,
        "term_attempt_monotonic_ns": None,
        "sigterm_sent": False,
        "term_grace_elapsed_seconds": None,
        "term_exit_seconds": None,
        "kill_attempted": False,
        "kill_attempt_utc": None,
        "kill_attempt_monotonic_ns": None,
        "sigkill_sent": False,
        "kill_cleanup_elapsed_seconds": None,
        "returncode_raw": None,
        "returncode_shell": None,
        "process_group_gone": False,
        "outcome": "runner_error",
    }
    process: subprocess.Popen[bytes] | None = None
    pgid: int | None = None
    try:
        with log_path.open("wb", buffering=0) as log_handle:
            process = subprocess.Popen(
                command,
                stdin=subprocess.DEVNULL,
                stdout=log_handle,
                stderr=subprocess.STDOUT,
                start_new_session=True,
                shell=False,
            )
            pgid = process.pid
            record["pid"] = process.pid
            record["process_starttime"] = proc_starttime(process.pid)
            try:
                record["julia_executable_proc_at_launch"] = os.readlink(
                    f"/proc/{process.pid}/exe"
                )
            except OSError:
                record["julia_executable_proc_at_launch"] = None
            record["process_group_id"] = os.getpgid(process.pid)
            record["session_id"] = os.getsid(process.pid)
            if (
                record["process_group_id"] != pgid
                or record["session_id"] != pgid
                or pgid == os.getpgrp()
            ):
                raise RuntimeError("child did not enter a safe private process group")

            ready, ready_status, ready_line, ready_fields = wait_for_ready(
                process,
                log_path,
                case,
                ready_timeout_seconds,
            )
            ready_ns = time.monotonic_ns()
            record["ready_observed"] = ready
            record["ready_status"] = ready_status
            record["ready_line"] = ready_line
            record["ready_fields"] = ready_fields
            try:
                record["julia_executable_proc_at_ready"] = os.readlink(
                    f"/proc/{process.pid}/exe"
                )
            except OSError:
                record["julia_executable_proc_at_ready"] = None
            if ready and ready_fields is not None:
                verified, checks = verify_ready_provenance(
                    case,
                    ready_fields,
                    record["julia_executable_proc_at_ready"],
                    expected_odepe_root,
                )
                record["provenance_verified"] = verified
                record["provenance_checks"] = checks
            record["ready_seconds"] = (ready_ns - started_ns) / 1e9

            group_alive_before_term = process.poll() is None or group_exists(pgid)
            record["group_alive_before_term"] = group_alive_before_term
            if group_alive_before_term:
                record["term_attempted"] = True
                record["term_attempt_utc"] = utc_now()
                term_ns = time.monotonic_ns()
                record["term_attempt_monotonic_ns"] = term_ns
                record["sigterm_sent"] = signal_group(pgid, signal.SIGTERM)
                exited_after_term = wait_for_group(
                    process,
                    pgid,
                    term_grace_seconds,
                )
                record["term_grace_elapsed_seconds"] = (
                    time.monotonic_ns() - term_ns
                ) / 1e9
                if exited_after_term and record["sigterm_sent"]:
                    record["term_exit_seconds"] = record[
                        "term_grace_elapsed_seconds"
                    ]
                if not exited_after_term:
                    record["kill_attempted"] = True
                    record["kill_attempt_utc"] = utc_now()
                    kill_ns = time.monotonic_ns()
                    record["kill_attempt_monotonic_ns"] = kill_ns
                    record["sigkill_sent"] = signal_group(pgid, signal.SIGKILL)
                    record["process_group_gone"] = wait_for_group(
                        process,
                        pgid,
                        kill_wait_seconds,
                    )
                    record["kill_cleanup_elapsed_seconds"] = (
                        time.monotonic_ns() - kill_ns
                    ) / 1e9
                else:
                    record["process_group_gone"] = True
            else:
                record["process_group_gone"] = True

            process.poll()
            if process.returncode is None:
                try:
                    process.wait(timeout=0.5)
                except subprocess.TimeoutExpired:
                    pass
            record["returncode_raw"] = process.returncode
            record["returncode_shell"] = normalized_returncode(process.returncode)

            record["outcome"] = classify_outcome(record)
    except Exception as error:
        record["error_type"] = type(error).__name__
        record["error_message"] = str(error)
        record["outcome"] = "runner_error"
    finally:
        if process is not None:
            process.poll()
        if pgid is not None and group_exists(pgid):
            if not record["kill_attempted"]:
                record["kill_attempted"] = True
                record["kill_attempt_utc"] = utc_now()
                cleanup_started_ns = time.monotonic_ns()
                record["kill_attempt_monotonic_ns"] = cleanup_started_ns
            else:
                cleanup_started_ns = time.monotonic_ns()
            final_kill_sent = signal_group(pgid, signal.SIGKILL)
            record["sigkill_sent"] = (
                record["sigkill_sent"] or final_kill_sent
            )
            if process is not None:
                record["process_group_gone"] = wait_for_group(
                    process,
                    pgid,
                    kill_wait_seconds,
                )
                final_cleanup_seconds = (
                    time.monotonic_ns() - cleanup_started_ns
                ) / 1e9
                prior_cleanup_seconds = (
                    record["kill_cleanup_elapsed_seconds"] or 0.0
                )
                record["kill_cleanup_elapsed_seconds"] = (
                    prior_cleanup_seconds + final_cleanup_seconds
                )
        if process is not None:
            process.poll()
            record["returncode_raw"] = process.returncode
            record["returncode_shell"] = normalized_returncode(process.returncode)
        if "error_type" not in record:
            record["outcome"] = classify_outcome(record)
        record["finished_utc"] = utc_now()
        record["total_seconds"] = (time.monotonic_ns() - started_ns) / 1e9
    return record


def classify_outcome(record: dict[str, Any]) -> str:
    """Classify a completed run from explicit signal-delivery evidence."""
    if not record["process_group_gone"]:
        return "cleanup_failed"
    if not record["ready_observed"]:
        if record["ready_status"] == "ready_timeout":
            return "ready_timeout"
        return "startup_failed"
    if (
        record["sigterm_sent"]
        and not record["kill_attempted"]
        and not record["sigkill_sent"]
        and record["process_group_gone"]
        and record["term_exit_seconds"] is not None
    ):
        return "term_exit"
    if record["sigkill_sent"]:
        return "kill_required"
    if record["kill_attempted"]:
        return "term_grace_expired"
    if not record["term_attempted"]:
        return "exit_after_ready_before_term"
    return "term_not_delivered"


def build_summary(
    metadata: dict[str, Any],
    records: list[dict[str, Any]],
    selected_cases: tuple[tuple[str, str], ...],
) -> dict[str, Any]:
    cases: dict[str, dict[str, Any]] = {}
    expected_per_case = int(metadata["repetitions"])
    for case, _ in selected_cases:
        selected = [record for record in records if record["case"] == case]
        cases[case] = {
            "runs": len(selected),
            "expected_runs": expected_per_case,
            "complete": len(selected) == expected_per_case,
            "ready": sum(bool(record["ready_observed"]) for record in selected),
            "term_exit": sum(record["outcome"] == "term_exit" for record in selected),
            "kill_required": sum(
                record["outcome"] == "kill_required" for record in selected
            ),
            "other_outcomes": [
                record["outcome"]
                for record in selected
                if record["outcome"] not in {"term_exit", "kill_required"}
            ],
            "ready_seconds": [
                record["ready_seconds"] for record in selected
            ],
            "term_exit_seconds": [
                record["term_exit_seconds"] for record in selected
            ],
            "term_grace_elapsed_seconds": [
                record["term_grace_elapsed_seconds"] for record in selected
            ],
            "kill_cleanup_elapsed_seconds": [
                record["kill_cleanup_elapsed_seconds"] for record in selected
            ],
        }
    expected_run_count = expected_per_case * len(selected_cases)
    complete = len(records) == expected_run_count and all(
        case_summary["complete"] for case_summary in cases.values()
    )
    return {
        "schema_version": "julia-termination-ladder-v2",
        "metadata": metadata,
        "completed_utc": utc_now(),
        "run_count": len(records),
        "expected_run_count": expected_run_count,
        "complete": complete,
        "all_ready": complete and all(
            record["ready_observed"] for record in records
        ),
        "all_exited_on_term": complete and all(
            record["outcome"] == "term_exit" for record in records
        ),
        "all_provenance_verified": complete and all(
            record["provenance_verified"] for record in records
        ),
        "sigkill_count": sum(bool(record["sigkill_sent"]) for record in records),
        "cleanup_failure_count": sum(
            record["outcome"] == "cleanup_failed" for record in records
        ),
        "cases": cases,
    }


def main(argv: list[str]) -> int:
    if sys.platform != "linux":
        print("run_ladder.py supports Linux only", file=sys.stderr)
        return 64
    args = parse_args(argv)
    root = Path(__file__).resolve().parent
    requested = set(args.selected_cases or (case for case, _ in CASES))
    selected_cases = tuple(
        (case, script_name)
        for case, script_name in CASES
        if case in requested
    )
    if (
        any(case == "odepe_idle" for case, _ in selected_cases)
        and args.expected_odepe_root is None
    ):
        print(
            "--expected-odepe-root is required when odepe_idle is selected",
            file=sys.stderr,
        )
        return 64
    if args.expected_odepe_root is not None:
        expected_root = Path(args.expected_odepe_root).expanduser().resolve()
        if not (expected_root / "Project.toml").is_file():
            print(
                "expected ODEPE root has no Project.toml: "
                f"{expected_root}",
                file=sys.stderr,
            )
            return 64
    output = Path(args.output).expanduser().resolve()
    output.mkdir(parents=True, exist_ok=False)
    logs_dir = output / "logs"
    logs_dir.mkdir()
    results_path = output / "results.jsonl"
    metadata_path = output / "run_metadata.json"
    summary_path = output / "summary.json"
    metadata = {
        "schema_version": "julia-termination-ladder-v2",
        "started_utc": utc_now(),
        "runner": str(Path(__file__).resolve()),
        "working_directory": os.getcwd(),
        "host": platform.node(),
        "platform": platform.platform(),
        "python": sys.version,
        "julia_executable": args.julia,
        "julia_executable_which": shutil.which(args.julia),
        "julia_executable_realpath": (
            None
            if shutil.which(args.julia) is None
            else os.path.realpath(shutil.which(args.julia))
        ),
        "julia_load_path_env": os.environ.get("JULIA_LOAD_PATH"),
        "julia_depot_path_env": os.environ.get("JULIA_DEPOT_PATH"),
        "repetitions": args.repetitions,
        "repetition_start": args.repetition_start,
        "ready_timeout_seconds": args.ready_timeout_seconds,
        "term_grace_seconds": args.term_grace_seconds,
        "kill_wait_seconds": args.kill_wait_seconds,
        "expected_odepe_root": (
            None
            if args.expected_odepe_root is None
            else str(Path(args.expected_odepe_root).expanduser().resolve())
        ),
        "julia_num_threads_env": os.environ.get("JULIA_NUM_THREADS"),
        "julia_num_gc_threads_env": os.environ.get("JULIA_NUM_GC_THREADS"),
        "ambient_julia_processes_at_start_namespace_local": (
            ambient_julia_processes()
        ),
        "cases": [
            {
                "name": case,
                "script": str((root / script_name).resolve()),
                "command": [
                    args.julia,
                    "--startup-file=no",
                    str((root / script_name).resolve()),
                ],
            }
            for case, script_name in selected_cases
        ],
    }
    atomic_json(metadata_path, metadata)

    records: list[dict[str, Any]] = []
    with results_path.open("a", encoding="utf-8", buffering=1) as results_handle:
        repetitions = range(
            args.repetition_start,
            args.repetition_start + args.repetitions,
        )
        final_repetition = args.repetition_start + args.repetitions - 1
        for repetition in repetitions:
            for case, script_name in selected_cases:
                print(
                    f"[{utc_now()}] {case} repetition "
                    f"{repetition}/{final_repetition}",
                    flush=True,
                )
                record = run_case(
                    case=case,
                    script_path=(root / script_name).resolve(),
                    repetition=repetition,
                    julia=args.julia,
                    logs_dir=logs_dir,
                    ready_timeout_seconds=args.ready_timeout_seconds,
                    term_grace_seconds=args.term_grace_seconds,
                    kill_wait_seconds=args.kill_wait_seconds,
                    expected_odepe_root=metadata["expected_odepe_root"],
                )
                records.append(record)
                results_handle.write(json.dumps(record, sort_keys=True) + "\n")
                results_handle.flush()
                os.fsync(results_handle.fileno())
                atomic_json(
                    summary_path,
                    build_summary(metadata, records, selected_cases),
                )
                ready_text = (
                    "n/a"
                    if record["ready_seconds"] is None
                    else f"{record['ready_seconds']:.3f}s"
                )
                term_text = (
                    "n/a"
                    if record["term_exit_seconds"] is None
                    else f"{record['term_exit_seconds']:.3f}s"
                )
                print(
                    f"  outcome={record['outcome']} "
                    f"ready={ready_text} "
                    f"term_exit={term_text}",
                    flush=True,
                )

    summary = build_summary(metadata, records, selected_cases)
    summary["ambient_julia_processes_at_finish_namespace_local"] = (
        ambient_julia_processes()
    )
    atomic_json(summary_path, summary)
    print(json.dumps(
        {
            "run_count": summary["run_count"],
            "expected_run_count": summary["expected_run_count"],
            "complete": summary["complete"],
            "all_ready": summary["all_ready"],
            "all_exited_on_term": summary["all_exited_on_term"],
            "all_provenance_verified": summary[
                "all_provenance_verified"
            ],
            "sigkill_count": summary["sigkill_count"],
            "summary": str(summary_path),
        },
        sort_keys=True,
    ))
    return (
        0
        if summary["complete"]
        and summary["all_ready"]
        and summary["all_exited_on_term"]
        and summary["all_provenance_verified"]
        else 1
    )


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
