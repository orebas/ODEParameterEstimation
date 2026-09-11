"""Retain estimates, options, timing summaries, and hashes from a rational worker."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import tomllib


def json_safe(value):
    if isinstance(value, float) and not math.isfinite(value):
        return str(value)
    if isinstance(value, dict):
        return {key: json_safe(item) for key, item in value.items()}
    if isinstance(value, list):
        return [json_safe(item) for item in value]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("worker_output", type=Path)
    parser.add_argument("evidence_file", type=Path)
    args = parser.parse_args()
    root = args.worker_output.resolve()
    record = tomllib.loads((root / "result.toml").read_text())
    omitted = []
    renamed = {}
    if "raw_count" in record:
        # The first estimator return is already processed and may have been
        # replaced by branch completion. It is not the original HC root pool.
        record["preclustering_candidate_count"] = record.pop("raw_count")
        renamed["raw_count"] = "preclustering_candidate_count"
    # The full timing records repeat thousands of individual calls. Retain the
    # estimator's own summaries, including stage and interpolator breakdowns.
    details = record.get("timing", {}).get("details", {})
    for key in ("detailed_timing_records", "resolve_states_with_fixed_params_records"):
        if key in details:
            omitted.append(f"timing.details.{key} ({len(details[key])} records)")
            del details[key]
    # This string embeds every observation index and the full estimator system.
    # Keep the remaining provenance fields and all numerical recovery results.
    for index, result in enumerate(record.get("ranked_results", [])):
        if "estimator_identity" in result.get("provenance", {}):
            del result["provenance"]["estimator_identity"]
            omitted.append(f"ranked_results[{index}].provenance.estimator_identity")
    source_files = {}
    for name in ("result.toml", "supervisor.json", "worker.log", "detailed_timing.toml", "resolve_timing.toml"):
        path = root / name
        if path.exists():
            source_files[name] = {"bytes": path.stat().st_size,
                                  "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    record["retained_evidence"] = {"worker_output": str(root), "source_files": source_files,
                                   "omitted_fields": omitted, "renamed_fields": renamed}
    record["supervisor"] = json.loads((root / "supervisor.json").read_text())
    log = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", (root / "worker.log").read_text())
    record["progress_log"] = [line for line in log.splitlines()
                              if line.startswith(("[HB ", "FINISHED "))
                              or re.match(r"Detected \d+/\d+ blown backsolves", line)
                              or "[SI-TEMPLATE] algebraic_multiplicity M =" in line]
    args.evidence_file.write_text(json.dumps(json_safe(record), indent=2, allow_nan=False) + "\n")


if __name__ == "__main__":
    main()
