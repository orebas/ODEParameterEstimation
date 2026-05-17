#!/usr/bin/env python3
"""Extract maxtime impact metrics from a compare_maxtime.jl log even if the
script crashed at the end on a Julia scope bug."""
import re, sys, json
from pathlib import Path

if len(sys.argv) < 2:
    print("usage: extract_compare.py <logfile> [maxtime_label]")
    sys.exit(1)

path = Path(sys.argv[1])
maxtime_label = sys.argv[2] if len(sys.argv) > 2 else path.stem
log = path.read_text()

# Pull out final analyze_parameter_estimation_problem summary
m = {}
for label, pat in [
    ("best_approx_error",   r"Best approximation error for sirt_treatment:\s+([0-9eE.+\-]+)"),
    ("best_max_relerr",     r"Best maximum relative error for sirt_treatment \(excluding ALL unidentifiable parameters\):\s+([0-9eE.+\-]+)"),
    ("best_min_relerr",     r"Best minimum relative error:\s+([0-9eE.+\-]+)"),
    ("best_mean_relerr",    r"Best mean relative error:\s+([0-9eE.+\-]+)"),
    ("best_median_relerr",  r"Best median relative error:\s+([0-9eE.+\-]+)"),
    ("best_rms_relerr",     r"Best RMS relative error:\s+([0-9eE.+\-]+)"),
]:
    mm = re.search(pat, log)
    m[label] = float(mm.group(1)) if mm else None

# Cluster count from "Cluster N:" lines (max N is the number of clusters)
clusters = [int(c) for c in re.findall(r"^Cluster (\d+):", log, re.M)]
m["n_clusters"] = max(clusters) if clusters else None

# Polish lines from `_polish_batch_from_context`: "Polish K/N (candidate I): T s, M iters, err A → B"
polish_lines = re.findall(r"Polish (\d+)/(\d+) \(candidate (\d+)\):\s+([0-9.eE+-]+)s,\s+(-?\d+) iters,\s+err ([0-9.eE+-]+) → ([0-9.eE+-]+)", log)
m["n_polish_runs"] = len(polish_lines)
if polish_lines:
    times = [float(t) for *_,_, t, _, _, _, _ in [(None, None, None, *l) for l in polish_lines]]  # workaround
    times = [float(l[3]) for l in polish_lines]
    iters = [int(l[4]) for l in polish_lines]
    err_after = [float(l[6]) for l in polish_lines]
    err_before = [float(l[5]) for l in polish_lines]
    m["polish_time_min"] = min(times)
    m["polish_time_max"] = max(times)
    m["polish_time_p50"] = sorted(times)[len(times)//2]
    m["polish_time_p90"] = sorted(times)[int(len(times)*0.9)]
    m["polish_iters_max"] = max(iters)
    m["polish_iters_p50"] = sorted(iters)[len(iters)//2]

# Total polish phase
mm = re.search(r"Polish total:\s+([0-9.eE+-]+)s for (\d+) unique solutions \(from (\d+) candidates\)", log)
if mm:
    m["polish_phase_seconds"] = float(mm.group(1))
    m["polish_unique"] = int(mm.group(2))
    m["polish_candidates"] = int(mm.group(3))

# Total time (look for our @printf line)
mm = re.search(r"MAXTIME=([0-9.]+)\s+ELAPSED=([0-9.]+)s\s+N_SOL=(\d+)\s+BEST_ERR=([0-9.eE+-]+)\s+BEST_RELERR=([0-9.]+)%", log)
if mm:
    m["script_total_seconds"] = float(mm.group(2))
    m["script_n_sol"] = int(mm.group(3))
    m["script_best_relerr_pct"] = float(mm.group(5))

# Found-solutions phase
mm_total = re.findall(r"Found (\d+) solutions total", log)
if mm_total:
    m["solutions_total_after_solve"] = int(mm_total[-1])

# After resolve / synth / polish
for label, pat in [
    ("after_resolve",        r"After re-solve:\s+(\d+) total candidates"),
    ("polished_after_dedup", r"Deduplicated (\d+) candidates → (\d+) unique starting points for polish"),
]:
    mm = re.search(pat, log)
    if mm:
        m[label] = mm.groups()

# polish_maxtime_exceeded count from notes
n_timeout = log.count("polish_maxtime_exceeded")
m["n_polish_timed_out_notes"] = n_timeout

# Print + emit JSON
print(json.dumps(m, indent=2))
out = path.with_suffix(".extracted.json")
out.write_text(json.dumps(m, indent=2))
print(f"# wrote {out}")
