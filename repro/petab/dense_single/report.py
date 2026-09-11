"""Promote compact evidence from completed local runs; leave original attempts intact."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("runs", nargs="+", type=Path)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent / "evidence")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    repo = Path(__file__).resolve().parents[3]
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--", "src", "ext"], cwd=repo, check=True)
    for run in args.runs:
        original = json.loads((run / "result.json").read_text())
        report = copy.deepcopy(original)
        destination_report = args.output / f"{run.name}.json"
        prior = json.loads(destination_report.read_text()) if destination_report.exists() else {}
        supervisor = run / "supervisor.json"
        if supervisor.exists():
            report["supervisor"] = json.loads(supervisor.read_text())
        terminal = original["status"] in ("complete", "no_candidates", "failed", "interrupted")
        if not terminal and report.get("supervisor", {}).get("status") != "timeout":
            raise SystemExit(f"Run is still active or lacks a supervisor result: {run}")
        details = report.get("timing", {}).get("details", {})
        for key in ("detailed_timing_records", "resolve_states_with_fixed_params_records"):
            details.pop(key, None)
        report["estimator_revision"] = original.get("estimator_revision", prior.get("estimator_revision", revision))
        report["revision_note"] = "Revision recorded at first evidence promotion; preserved on subsequent report refreshes."
        report["artifact_sha256"] = {
            str(p.relative_to(run)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(run.rglob("*")) if p.is_file()
        }
        report["profile_excerpts"] = {}
        domains = ("@ODEParameterEstimation/src/core/", "@SymbolicUtils/src/polyform.jl",
                   "@MultivariatePolynomials/src/gcd.jl", "@Groebner/", "@StructuralIdentifiability/",
                   "@RationalFunctionFields/", "@HomotopyContinuation/", "@MixedSubdivisions/")
        for path in sorted(run.glob("*profile*.txt")):
            lines = path.read_text(errors="replace").splitlines()
            matches = []
            for line in lines:
                count = re.match(r"\s*(\d+)\s+(\d+)\s+", line)
                if count and any(domain in line for domain in domains):
                    matches.append((int(count[1]), line.strip()))
            report["profile_excerpts"][path.name] = {
                "note": "Inclusive stack counts overlap; these are not disjoint time percentages.",
                "summary": next((line for line in lines if line.startswith("Total snapshots:")), None),
                "frames": [line for _,line in sorted(matches, key=lambda item:item[0], reverse=True)[:25]],
            }
        # Keep the exact executed source when a snapshot is available. The first
        # trials preceded small improvements to interrupt/provenance recording.
        source = run / "source"
        if source.exists():
            destination = args.output / "sources" / run.name
            destination.mkdir(parents=True, exist_ok=True)
            for path in source.glob("*.jl"):
                shutil.copyfile(path, destination / path.name)
            if "harness_sha256" in original:
                fingerprint = hashlib.sha256((source / "run.jl").read_bytes() + (source / "common.jl").read_bytes()).hexdigest()
                assert fingerprint == original["harness_sha256"]
                report["executed_source_snapshot"] = str(destination.relative_to(args.output))
        log_path = run / "worker.log"
        if log_path.exists():
            log = log_path.read_text(errors="replace")
            systems = []
            pattern = r"\[NOISE-FRONTIER\] Selected candidate\s+│\s+n_points = (\d+)\s+│\s+max_observed_order = (\d+)\s+│\s+mixed_volume = (\d+)\s+│\s+support_score = [^\n]+\s+│\s+solve_vars = (\d+)\s+└\s+data_vars = (\d+)"
            for values in re.findall(pattern, log):
                row = dict(zip(("points", "max_observed_order", "mixed_volume", "solve_variables", "data_coefficients"), map(int, values)))
                if row not in systems:
                    systems.append(row)
            report["selected_systems_from_log"] = systems
            report["heartbeats"] = [line for line in log.splitlines() if "[HB " in line]
            lines = log.splitlines()
            markers = ("[SI-TEMPLATE] Polynomial construction summary", "[SI-MAP] Extending DerivativeData",
                       "[SI-STRUCTURAL] SIAN/SI template summary", "[STRUCTURAL-FIX]",
                       "[SI-TEMPLATE] algebraic_multiplicity", "[TEMPLATE-STRUCTURE] System status:",
                       "Built polynomial system with", "[DEBUG-ALG-INDEP] Jacobian rank:",
                       "One of the Wronskians has corank greater than one")
            report["construction_messages"] = []
            for index,line in enumerate(lines):
                if any(marker in line for marker in markers):
                    chunk = [line]
                    for following in lines[index+1:index+9]:
                        if not following.startswith(("│", "└")):
                            break
                        chunk.append(following)
                    report["construction_messages"].append("\n".join(chunk))
        destination_report.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
        # Data are small, and retaining them makes subsequent interpolation-only
        # checks possible without SBML import or a second simulation.
        data = run / "data.json"
        if data.exists():
            (args.output / f"{run.name}.data.json").write_bytes(data.read_bytes())
        print(run.name, report["status"], flush=True)


if __name__ == "__main__":
    main()
