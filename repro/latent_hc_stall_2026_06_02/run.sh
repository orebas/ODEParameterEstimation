#!/usr/bin/env bash
# Run ONLY when the broad-benchmark slow tier has drained off this box.
# Heavy julia + a deliberately-hanging solve; an OOM here crashes the WSL VM.
# Apply the export hook from README.md first (this script verifies it's present).
set -uo pipefail

REPRO="$HOME/.julia/dev/ODEParameterEstimation/repro/latent_hc_stall_2026_06_02"
FT="$HOME/ParameterEstimationBenchmark-local/benchmark_quoll_broad_2026-05-29/filetree/odepe_v2_nopolish_run"
HC_SRC="$HOME/.julia/dev/ODEParameterEstimation/src/core/homotopy_continuation.jl"
JL="julia --startup-file=no"

# --- guards: box must be free + memory headroom ---
workers=$(pgrep -fc 'estimate.py.*odepe' || true)
[ "${workers:-0}" -gt 0 ] && { echo "ABORT: $workers slow-tier worker(s) still running — wait for the run to finish."; exit 1; }
freeg=$(free -g | awk '/Mem/{print $7}')
echo "available mem: ${freeg}G"
[ "${freeg:-0}" -lt 8 ] && { echo "ABORT: <8G available — wait for the box to free up."; exit 1; }

# --- export hook must be applied (README) + ODEPE must still load with it ---
grep -q "latent_hc_stall repro" "$HC_SRC" || { echo "ABORT: export hook not applied — see README.md."; exit 1; }
echo "verifying ODEPE loads with the hook present..."
$JL -e 'using ODEParameterEstimation' || { echo "ABORT: hook broke ODEPE load — revert from .bak."; exit 1; }

# --- export: symmetric (noise 0) + generic (noise 1e-2), SAME idx-0 params ---
echo "=== export SYMMETRIC (noise 0 — expected to stall; timeout bounds it, dump precedes solve) ==="
( cd "$FT/latent_subpopulation_branch_0_0"    && ODEPE_DUMP="$REPRO/sym" timeout 300 $JL script.jl ) \
  || echo "(noise-0 timed out — expected; the system was dumped before the solve)"
echo "=== export GENERIC (noise 1e-2) ==="
( cd "$FT/latent_subpopulation_branch_0_1em2" && ODEPE_DUMP="$REPRO/gen" timeout 600 $JL script.jl ) \
  || echo "(noise-1em2 finished or timed out)"

echo; echo "dumped systems:"; ls -la "$REPRO"/sym_n*.jl "$REPRO"/gen_n*.jl 2>/dev/null

# --- MWE-solve each dumped system, verbose, under timeout ---
for f in "$REPRO"/sym_n*.jl "$REPRO"/gen_n*.jl; do
  [ -f "$f" ] || continue
  echo; echo "############ MWE solve: $(basename "$f") ############"
  timeout 300 $JL "$REPRO/mwe_hc_solve.jl" "$f" || echo "(STALLED — no RESULT before the 300s timeout)"
done

echo; echo "DONE.  REVERT the export hook now:  cp \"$HC_SRC.bak\" \"$HC_SRC\""
