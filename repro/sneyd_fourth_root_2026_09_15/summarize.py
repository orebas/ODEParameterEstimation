"""Summarize completed fourth-root workers without conflating timeout and failure."""
import argparse
from collections import Counter
import gzip
import hashlib
import json
from pathlib import Path
import re


def read_json(path):
    data = path.read_bytes()
    return json.loads(gzip.decompress(data) if path.suffix == ".gz" else data)


def shape(capture):
    unknowns = len(capture["unknowns"])
    degrees = [max(sum(term["exponents"][:unknowns]) for term in row)
               for row in capture["polynomials"]]
    data_rows = [i for i, row in enumerate(capture["polynomials"])
                 if any(any(term["exponents"][unknowns:]) for term in row)]
    return {"equations": len(degrees), "unknowns": unknowns,
            "data_parameters": len(capture["data_variables"]),
            "monomials": sum(map(len, capture["polynomials"])),
            "degree_histogram": dict(sorted(Counter(degrees).items())),
            "observation_rows": len(data_rows),
            "observation_terms": sum(len(capture["polynomials"][i]) for i in data_rows),
            "unknown_names": capture["original_unknowns"],
            "data_names": capture["original_data_variables"]}


def progress(body):
    latest = lambda pattern: re.findall(pattern, body)[-1:]
    return {
        "tracking_path_count": latest(r"Tracking (\d+) paths"),
        "paths_tracked": latest(r"# paths tracked: ([^\x1b\n]+)"),
        "nonsingular_solutions": latest(r"# non-singular solutions \(real\): ([^\x1b\n]+)"),
        "total_solutions": latest(r"# total solutions \(real\): ([^\x1b\n]+)"),
        "last_partial_mixed_volume_counter": latest(r"mixed_volume: ([^\x1b\n]+)")}


def summarize(path):
    result = read_json(path / "result.json")
    supervisor = read_json(path / "supervisor.json")
    keys = ("model_kind", "observation_kind", "phase", "seed", "status",
            "preparation_seconds", "estimation_seconds", "generic_start_seconds",
            "generic_start_count", "probe_seconds", "probe_compile_seconds",
            "multiplicity_input", "multiplicity", "dimension", "basis_length",
            "derivative_steps", "cleared_text_length", "probe_bytes",
            "generating_validation", "scale_info", "error", "raw_count", "ranked_results")
    summary = {key: result[key] for key in keys if key in result}
    summary.update(output_directory=str(path), supervisor_status=supervisor["status"],
                   source_revision=supervisor["source_revision"],
                   julia_version=result.get("julia_version"),
                   returncode=supervisor["returncode"],
                   stage_cap=supervisor["estimation_seconds_cap"],
                   loading_and_preparation_cap=supervisor["loading_and_preparation_seconds_cap"],
                   supervisor_elapsed_seconds=supervisor["elapsed_seconds"],
                   supervisor_measured_stage_seconds=supervisor.get("measured_stage_seconds"),
                   worker_finalization_complete="estimation_seconds" in result,
                   result_sha256=hashlib.sha256((path / "result.json").read_bytes()).hexdigest())
    summary["hc_systems"] = [dict(file=p.name, **shape(read_json(p)))
                             for p in sorted(path.glob("generic_system_*.json"))]
    log = (path/"worker.log").read_text().replace("\r","\n")
    first_generic = re.search(r"CAPTURED_GENERIC_SYSTEM.*?(?=\[HC-PARAM\] Generic-start \(hoisted\):|\Z)",log,re.S)
    if first_generic:
        summary["first_generic_progress"] = progress(first_generic.group(0))
    summary["parameter_homotopy_events"] = [line for line in log.splitlines()
                                               if "[HC-PARAM]" in line]
    # Keep downstream fresh solves separate from the successfully completed
    # generic solve. The last progress display in a log need not belong to p0.
    summary["fresh_data_solves"] = []
    for match in re.finditer(r"(\[HC-PARAM\] Point \d+: fan-out [^\n]* → fresh solve)\n"
                             r"(.*?)(?=\[HC-PARAM\] Point \d+: generic-start fan-out|\Z)",
                             log, re.S):
        summary["fresh_data_solves"].append({"trigger": match.group(1),
                                             **progress(match.group(2))})
    summary["generic_error_messages"] = [line for line in log.splitlines() if "generic solve threw" in line]
    for label,key in (("probe_active_seconds","probe_started_ns"),
                      ("groebner_active_seconds","groebner_started_ns"),
                      ("clear_denoms_active_seconds","clear_denoms_started_ns")):
        if key in result and "estimation_seconds" in result:
            summary[label] = result["estimation_seconds"]-(result[key]-result["estimation_started_ns"])/1e9
    if (path/"original_budget_checkpoint.json").exists():
        summary["original_budget_checkpoint"] = {k:v for k,v in read_json(path/"original_budget_checkpoint.json").items()
                                                  if k != "worker_checkpoint"}
    if (path/"budget_extension.json").exists():
        extension = read_json(path/"budget_extension.json")
        summary["budget_extension"] = {key: extension[key] for key in
            ("status", "reason", "original_estimation_seconds_cap", "estimation_seconds_cap", "measured_stage_seconds")}
    return summary, result


def compare(quartic, root):
    assert quartic["model_kind"] == root["model_kind"]
    assert quartic["phase"] == root["phase"]
    assert quartic["observation_kind"] == "quartic"
    assert root["observation_kind"] == "root"
    for key in ("seed", "manifest_sha256", "spec_sha256", "versions"):
        assert quartic[key] == root[key], key
    # Absolute output paths differ but carry no numerical settings.
    differences = {key: [quartic["options"][key], root["options"][key]]
                   for key in quartic["options"]
                   if quartic["options"][key] != root["options"][key]}
    allowed = {"dump_raw_candidates_path", "dump_polished_path"}
    assert set(differences) <= allowed, differences
    for key in quartic["model_definition"]:
        if key == "observations":
            continue
        assert quartic["model_definition"][key] == root["model_definition"][key], key
    assert quartic["transformation"]["original_data"] == root["transformation"]["original_data"]
    return {"model": root["model_kind"], "phase": root["phase"],
            "same_model_except_observation": True, "same_original_data": True,
            "same_options_except_output_paths": True,
            "same_harness_sources": quartic["source_sha256"] == root["source_sha256"],
            "effective_interpolators_before_rescaling": {
                "quartic": quartic["effective_interpolators"], "root": root["effective_interpolators"]},
            "same_state_and_parameter_scales": all(quartic["scale_info"][key] == root["scale_info"][key]
                for key in ("state_scales", "param_scales")),
            "quartic_roundtrip_error": quartic["transformation"]["fourth_power_roundtrip_max_error"],
            "root_roundtrip_error": root["transformation"]["fourth_power_roundtrip_max_error"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("runs", nargs="+", type=Path)
    args = parser.parse_args()
    assert not args.output.exists(), "Use a fresh output path"
    summaries, results = zip(*(summarize(p) for p in args.runs))
    indexed = {(r["model_kind"], r["phase"], r["observation_kind"]): r for r in results}
    assert len(indexed) == len(results), "Choose one final attempt per arm"
    pairs = [compare(indexed[(m, p, "quartic")], indexed[(m, p, "root")])
             for m, p in sorted({(m, p) for m, p, _ in indexed})
             if (m, p, "quartic") in indexed and (m, p, "root") in indexed]
    args.output.write_text(json.dumps({"runs": summaries, "pair_checks": pairs,
        "summary_source_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}, indent=2) + "\n")
    print(json.dumps({"runs": len(summaries), "verified_pairs": len(pairs)}, indent=2))


if __name__ == "__main__":
    main()
