#!/usr/bin/env python3
"""Run a small local A/B pilot for the 2026-06-17 `_trfn_` multipoint fix.

The final-v2 benchmark tree is treated as read-only.  For each selected cell,
this script copies only the generated inputs into an artifact directory, patches
the copied `script.jl` to activate the local ODEParameterEstimation project and
to include the local benchmark `dump_pool.jl`, runs the copied cell, and writes a
CSV/Markdown comparison against the archived final-v2 metadata.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


PACKAGE_ROOT = Path("/home/orebas/.julia/dev/ODEParameterEstimation")
BENCH_ROOT = Path("/home/orebas/ParameterEstimationBenchmark-local")
FINAL_ROOT = BENCH_ROOT / "benchmark_final_v2_2026-06-12"
SOURCE_RUN = FINAL_ROOT / "filetree" / "odepe_v2_polish_run"
BENCH_SRC = BENCH_ROOT / "src"
ARTIFACT_ROOT = PACKAGE_ROOT / "artifacts" / "trfn_multipoint_fix_ab_2026_06_17"
LOCAL_RUN = ARTIFACT_ROOT / "odepe_v2_polish_trfn_fix"

DEFAULT_CELLS = [
    "quadrotor_0_0",
    "aircraft_pitch_0_0",
    "bicycle_model_0_0",
]

INPUT_FILES = ["script.jl", "data.csv", "data.csv.sha256", "cell_seed.txt"]


def read_json(path: Path) -> dict[str, Any] | None:
    try:
        return json.loads(path.read_text())
    except Exception:
        return None


def read_float(path: Path) -> float | None:
    try:
        return float(path.read_text().strip())
    except Exception:
        return None


def patch_script(text: str) -> str:
    text = text.replace(
        'using Pkg; Pkg.activate(raw"/opt/peb/environments/julia_odepe")',
        f'using Pkg; Pkg.activate(raw"{PACKAGE_ROOT}")',
    )
    text = text.replace(
        'raw"/opt/peb/src/dump_pool.jl"',
        f'raw"{BENCH_SRC / "dump_pool.jl"}"',
    )
    return text


def prepare_cell(cell_id: str) -> Path:
    src = SOURCE_RUN / cell_id
    if not src.exists():
        raise FileNotFoundError(f"missing source cell: {src}")

    dst = LOCAL_RUN / cell_id
    dst.mkdir(parents=True, exist_ok=True)
    for name in INPUT_FILES:
        src_file = src / name
        if src_file.exists():
            shutil.copy2(src_file, dst / name)

    script = dst / "script.jl"
    script.write_text(patch_script(script.read_text()))
    return dst


def run_cell(cell_id: str, timeout: int) -> dict[str, Any]:
    dst = prepare_cell(cell_id)
    stdout_path = dst / "pilot_stdout.txt"
    stderr_path = dst / "pilot_stderr.txt"
    env = os.environ.copy()
    env.update(
        {
            "JULIA_NUM_THREADS": "2",
            "MKL_NUM_THREADS": "1",
            "OPENBLAS_NUM_THREADS": "1",
        }
    )
    cmd = ["julia", "--startup-file=no", "--project=" + str(PACKAGE_ROOT), str(dst / "script.jl")]
    t0 = time.time()
    status = "ok"
    returncode: int | None = None
    try:
        with stdout_path.open("w") as out, stderr_path.open("w") as err:
            proc = subprocess.run(cmd, cwd=dst, env=env, stdout=out, stderr=err, timeout=timeout)
        returncode = proc.returncode
        if proc.returncode != 0:
            status = "error"
    except subprocess.TimeoutExpired:
        status = "timeout"
    elapsed = time.time() - t0
    return {"cell": cell_id, "pilot_status": status, "returncode": returncode, "pilot_elapsed": elapsed}


def flatten_meta(meta: dict[str, Any] | None) -> dict[str, Any]:
    if not meta:
        return {}
    best = meta.get("best") or {}
    timing = meta.get("timing") or {}
    details = timing.get("details") or {}

    def sum_detail(name: str) -> float | None:
        val = details.get(name)
        if isinstance(val, dict):
            nums = [float(x) for x in val.values() if isinstance(x, (int, float))]
            return sum(nums) if nums else None
        return float(val) if isinstance(val, (int, float)) else None

    return {
        "status": meta.get("status"),
        "raw_count": meta.get("raw_count"),
        "best_count": meta.get("best_count"),
        "best_max_error": meta.get("best_max_error"),
        "best_median_error": meta.get("best_median_error"),
        "best_rms_error": meta.get("best_rms_error"),
        "primary_method": best.get("primary_method"),
        "source_type": best.get("source_type"),
        "interpolator_source": best.get("interpolator_source"),
        "multipoint_time_indices": best.get("multipoint_time_indices"),
        "multipoint_combo_index": best.get("multipoint_combo_index"),
        "timing_total": timing.get("total"),
        "used_multipoint": details.get("used_multipoint"),
        "multipoint_template_seconds": sum_detail("multipoint_template_seconds_by_source"),
        "multipoint_eval_seconds": sum_detail("multipoint_eval_seconds_by_source"),
        "multipoint_solve_seconds": sum_detail("multipoint_solve_seconds_by_source"),
    }


def flat_from_stdout(cell_dir: Path) -> dict[str, Any]:
    stdout = cell_dir / "stdout.txt"
    if not stdout.exists():
        return {}
    text = stdout.read_text(errors="replace")

    def metric(label: str) -> float | None:
        pattern = rf"{re.escape(label)}:\s*([-+0-9.eE]+)"
        match = re.search(pattern, text)
        return float(match.group(1)) if match else None

    status = "ok" if "Parameter Estimation Complete!" in text and "===END===" in text else None
    return {
        "status": status,
        "best_max_error": metric("Best maximum relative error"),
        "best_median_error": metric("Best median relative error"),
        "best_rms_error": metric("Best RMS relative error"),
    }


def load_flat(cell_dir: Path) -> dict[str, Any]:
    flat = flatten_meta(read_json(cell_dir / "odepe_metadata.json"))
    if flat:
        return flat
    return flat_from_stdout(cell_dir)


def pool_counts(path: Path) -> dict[str, int]:
    out: dict[str, int] = {}
    if not path.exists():
        return out
    try:
        with path.open(newline="") as io:
            reader = csv.DictReader(io)
            for row in reader:
                key = row.get("source_type") or "unknown"
                out[key] = out.get(key, 0) + 1
    except Exception:
        return out
    return out


def summarize(cells: list[str], run_records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_cell = {row["cell"]: row for row in run_records}
    rows: list[dict[str, Any]] = []
    for cell in cells:
        base_dir = SOURCE_RUN / cell
        pilot_dir = LOCAL_RUN / cell
        base = load_flat(base_dir)
        fixed = load_flat(pilot_dir)
        row: dict[str, Any] = {"cell": cell}
        row.update({f"base_{k}": v for k, v in base.items()})
        row.update({f"fixed_{k}": v for k, v in fixed.items()})
        row["base_wall_seconds"] = read_float(base_dir / "wall_time_seconds.txt")
        row["fixed_wall_seconds"] = read_float(pilot_dir / "wall_time_seconds.txt")
        row["base_pool_source_counts"] = json.dumps(pool_counts(base_dir / "pool.csv"), sort_keys=True)
        row["fixed_pool_source_counts"] = json.dumps(pool_counts(pilot_dir / "pool.csv"), sort_keys=True)
        row.update(by_cell.get(cell, {}))
        rows.append(row)
    return rows


def write_summary(rows: list[dict[str, Any]]) -> None:
    ARTIFACT_ROOT.mkdir(parents=True, exist_ok=True)
    keys: list[str] = []
    for row in rows:
        for key in row:
            if key not in keys:
                keys.append(key)

    csv_path = ARTIFACT_ROOT / "pilot_summary.csv"
    with csv_path.open("w", newline="") as io:
        writer = csv.DictWriter(io, fieldnames=keys)
        writer.writeheader()
        writer.writerows(rows)

    md_path = ARTIFACT_ROOT / "pilot_summary.md"
    keep = [
        "cell",
        "pilot_status",
        "base_status",
        "fixed_status",
        "base_best_max_error",
        "fixed_best_max_error",
        "base_source_type",
        "fixed_source_type",
        "base_raw_count",
        "fixed_raw_count",
        "base_pool_source_counts",
        "fixed_pool_source_counts",
        "fixed_used_multipoint",
        "fixed_multipoint_template_seconds",
        "fixed_multipoint_eval_seconds",
        "fixed_multipoint_solve_seconds",
        "base_multipoint_time_indices",
        "fixed_multipoint_time_indices",
        "base_wall_seconds",
        "fixed_wall_seconds",
    ]
    with md_path.open("w") as io:
        print("# `_trfn_` Multipoint Fix Pilot Summary", file=io)
        print("", file=io)
        print(f"Artifact root: `{ARTIFACT_ROOT}`", file=io)
        print("", file=io)
        print("| " + " | ".join(keep) + " |", file=io)
        print("| " + " | ".join(["---"] * len(keep)) + " |", file=io)
        for row in rows:
            vals = [str(row.get(k, "")) for k in keep]
            print("| " + " | ".join(vals) + " |", file=io)

    print(csv_path)
    print(md_path)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cells", nargs="+", default=DEFAULT_CELLS)
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args(argv)

    ARTIFACT_ROOT.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, Any]] = []
    for cell in args.cells:
        prepare_cell(cell)
        if not args.prepare_only:
            print(f"RUN {cell}", flush=True)
            rec = run_cell(cell, args.timeout)
            print(json.dumps(rec, sort_keys=True), flush=True)
            records.append(rec)

    rows = summarize(args.cells, records)
    write_summary(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
