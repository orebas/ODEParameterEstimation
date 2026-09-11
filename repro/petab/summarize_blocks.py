"""Summarize bounded experiment trials separately from the original pilot."""
import argparse
import csv
import json
from pathlib import Path


def summarize(directory, reference, require_complete=False):
    rows = []
    implementations = set()
    for path in sorted(directory.glob("*.odepe_blocks*.json")):
        record = json.loads(path.read_text())
        name = record["problem"]
        if require_complete and record["status"] in ("prepared", "algebraic_complete"):
            raise ValueError(f"Unfinished trial: {path}")
        start = json.loads((reference / f"{name}.start.json").read_text())
        expected = dict(zip(start["parameter_ids"], start["x"]))
        actual = dict(zip(record["parameter_ids"], record["x0"]))
        if actual != expected:
            raise ValueError(f"Changed pilot start: {path}")
        implementations.add(record["implementation_sha256"])
        result = record.get("result", {})
        construction = result.get("construction", [])
        trace = (construction[-1].get("trace", []) if construction else
                 result.get("construction_progress", {}).get("trace", []))
        last = trace[-1] if trace else {}
        candidates = result.get("candidates", [])
        refined = result.get("refined") or {}
        baselines = []
        for method in ("petab_julia", "pypesto_amici"):
            baseline = json.loads((reference / f"{name}.{method}.json").read_text())
            baselines.append(baseline.get("result", {}).get("nllh"))
        rows.append(dict(
            problem=name, method=record["method"], status=record["status"],
            derivative_cap=record.get("experiment_construction", {}).get("max_derivative_order"),
            derivative_order=last.get("derivative_order"), pool_equations=last.get("equation_count"),
            unknowns=last.get("variable_count"), rank=last.get("rank"),
            selected_equations=last.get("selected_equation_count"),
            raw_candidates=result.get("raw_candidate_count"), valid_candidates=len(candidates),
            raw_nllh=min((c["nllh"] for c in candidates), default=None),
            refined_nllh=refined.get("nllh"), refinement_status=refined.get("status"),
            julia_baseline_nllh=baselines[0], amici_baseline_nllh=baselines[1],
            total_seconds=record.get("total_seconds")))
    if not rows:
        raise ValueError("No experiment-block records found")
    if len(implementations) != 1:
        raise ValueError("Trial implementations differ; disclose and summarize them separately")
    with (directory / "summary.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    lines = ["# Bounded PEtab experiment trials", "",
             "Same canonical problems and recorded starts as the original pilot. "
             "All scores and refinement use the full original PEtab objective. "
             "Workers overlapped; these are feasibility results, not speed rankings.", "",
             "| Model | Conditions | Status | Rank / unknowns | Cap | Order reached | Valid seeds | Raw NLLH | Refined NLLH |",
             "|---|---:|---|---:|---:|---:|---:|---:|---:|"]
    def fmt(value):
        return "—" if value is None else f"{value:.8g}"
    for row in rows:
        lines.append(f"| {row['problem']} | {row['method'].removeprefix('odepe_blocks')} | "
                     f"{row['status']} | {row['rank']}/{row['unknowns']} | "
                     f"{row['derivative_cap']} | {row['derivative_order']} | {row['valid_candidates']} | "
                     f"{fmt(row['raw_nllh'])} | {fmt(row['refined_nllh'])} |")
    lines += ["", "A deficient capped pool is not a structural-identifiability verdict. "
              "A successful refinement is not proof of global optimality. "
              "Full precision, original baseline objectives, and timings are in `summary.csv`.", "",
              f"Implementation SHA-256: `{next(iter(implementations))}`.", ""]
    (directory / "summary.md").write_text("\n".join(lines))
    return rows


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--reference", type=Path, default=Path("repro/petab/pilot_results"))
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    summarize(args.directory, args.reference, args.require_complete)
