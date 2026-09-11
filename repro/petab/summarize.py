"""Summarize every planned attempt, including missing cells and failures."""
import argparse
import csv
import json
import math
from pathlib import Path
import tomllib


METHODS = ("odepe", "petab_julia", "pypesto_amici")
INCOMPLETE = {"not_run", "prepared", "algebraic_complete"}


def finite(value):
    try:
        number = float(value)
        return number if math.isfinite(number) else None
    except (TypeError, ValueError):
        return None


def summarize(directory, config):
    rows = []
    for model in config["main"] + config["challenge"]:
        start_path = directory / f"{model}.start.json"
        start = json.loads(start_path.read_text()) if start_path.exists() else None
        for method in METHODS:
            path = directory / f"{model}.{method}.json"
            record = json.loads(path.read_text()) if path.exists() else {}
            result = record.get("result", {})
            candidates = result.get("candidates", [])
            candidate_scores = [finite(candidate.get("nllh")) for candidate in candidates]
            candidate_scores = [value for value in candidate_scores if value is not None]
            refined = result.get("refined") or {}
            status = record.get("status", "not_run")
            termination = refined.get("status", result.get("status", ""))
            # Early workers called every finite returned vector "success".
            # Distinguish local convergence from a stopped optimizer in reports.
            converged = result.get("converged", str(termination).rsplit(".", 1)[-1] in ("FTOL", "XTOL", "GTOL", "1", "2", "3"))
            if method != "odepe" and status == "success" and not converged:
                status = "optimizer_stopped"
            if "x0" in record:
                if start is None:
                    raise ValueError(f"Missing shared starting vector for {model}")
                expected = dict(zip(start["parameter_ids"], start["x"]))
                actual = dict(zip(record["parameter_ids"], record["x0"]))
                if expected != actual:
                    raise ValueError(f"Starting vectors disagree by parameter ID: {path}")
            reason = str(record.get("error") or result.get("polish_error") or "")
            if status == "timeout":
                reason = "Time budget exhausted; completed candidate checkpoint retained" if candidates else "Time budget exhausted before a scored candidate was returned"
            if status == "no_valid_candidates":
                reason = "No algebraic vector passed the original PEtab bounds and objective checks"
            if status == "optimizer_stopped":
                reason = f"Finite objective returned without optimizer convergence ({termination})"
            if status == "optimization_failed" and finite(record.get("initial_nllh")) is None:
                reason = "Original objective was nonfinite at the shared starting vector; no alternative start was sampled"
            reason = reason.split("Stacktrace:", 1)[0].strip().replace("\n", " ")[:1200]
            rows.append(dict(problem=model, cohort="main" if model in config["main"] else "challenge",
                method=method, status=status, initial_nllh=finite(record.get("initial_nllh")),
                raw_candidate_count=result.get("raw_candidate_count"),
                unscored_candidate_count=result.get("unscored_candidate_count"),
                valid_candidate_count=len(candidates) if method == "odepe" and result else None,
                algebraic_nllh=min(candidate_scores) if candidate_scores else None,
                refined_nllh=finite(refined.get("nllh")),
                baseline_nllh=finite(result.get("nllh")),
                termination=termination,
                preparation_seconds=record.get("preparation_seconds"),
                total_seconds=record.get("total_seconds"), reason=reason))
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    config = tomllib.loads(Path(__file__).with_name("targets.toml").read_text())
    rows = summarize(args.directory, config)
    with (args.directory / "summary.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    by_cell = {(row["problem"], row["method"]): row for row in rows}
    lines = ["# Single-start PEtab feasibility pilot", "",
        f"Canonical benchmark revision: `{config['benchmark_revision']}`. Seed: `{config['seed']}`. Budget: {config['seconds_per_method']} seconds per method/problem, excluding package load.", "",
        "Lower NLLH is better **within the same problem**. Values retain the original likelihood and preparation. These attempts do not establish speed, reliability or global optimality. Separate development retries are recorded in `../development_attempts.json`.", "",
        "| Problem | ODEPE algebraic NLLH | ODEPE refined NLLH | Julia/Fides NLLH | AMICI/Fides NLLH |",
        "|---|---:|---:|---:|---:|"]
    def cell(row, key):
        value = row[key]
        if value is not None:
            suffix = f" ({row['status']})" if row["status"] in ("timeout", "optimizer_stopped") else ""
            return f"{value:.9g}{suffix}"
        return row["status"] if row["status"] != "success" else "not returned"
    for model in config["main"] + config["challenge"]:
        odepe = by_cell[model, "odepe"]
        lines.append("| " + " | ".join((model, cell(odepe, "algebraic_nllh"),
            cell(odepe, "refined_nllh"), cell(by_cell[model, "petab_julia"], "baseline_nllh"),
            cell(by_cell[model, "pypesto_amici"], "baseline_nllh"))) + " |")
    lines += ["", "## Failures and limits", ""]
    for row in rows:
        if row["status"] != "success" or row["reason"]:
            lines.append(f"- **{row['problem']} / {row['method']}**: {row['status']}. {row['reason']}")
    lines += ["", "The CSV retains stage counts, termination codes and measured times. Several workers overlapped, and the early attempts predate source/thread instrumentation; those timings are not a performance comparison.", ""]
    (args.directory / "summary.md").write_text("\n".join(lines))
    incomplete = [row for row in rows if row["status"] in INCOMPLETE]
    print(f"{len(rows) - len(incomplete)}/{len(rows)} planned cells complete; starting vectors agree by parameter ID")
    if incomplete and args.require_complete:
        raise SystemExit("Some planned attempts are incomplete")


if __name__ == "__main__":
    main()
