#!/usr/bin/env bash
# drive.sh — watchdog driver for hunt.jl / attempt.jl.
#
# Runs ROUNDS Julia processes, each doing NSOLVES threaded HC solves. A per-round
# watchdog polls the round's log mtime; if the process is alive but the log has
# been frozen for > STALL seconds AND its last heartbeat is a "START" with no
# matching "DONE", it is declared DEADLOCKED: backtraces are dumped (SIGQUIT +
# gdb) into hangs/, then the process is killed and the loop continues.
#
# A deadlock hangs forever, so STALL only needs to exceed the slowest *healthy*
# solve (incl. first-call compile and any CPU oversubscription). 150s is safe
# here (healthy solves observed <=28s single-lane).
#
# Usage: drive.sh <threads> <rounds> <nsolves> <stall_secs> <label> [shape] [script]
set -uo pipefail
cd "$(dirname "$0")"
THREADS=${1:?threads}; ROUNDS=${2:?rounds}; NSOLVES=${3:?nsolves}
STALL=${4:?stall_secs}; LABEL=${5:?label}; SHAPE=${6:-mix}; SCRIPT=${7:-hunt.jl}
mkdir -p logs hangs
SUMMARY="logs/${LABEL}_summary.txt"
echo "== drive start $(date) threads=$THREADS rounds=$ROUNDS nsolves=$NSOLVES stall=$STALL shape=$SHAPE script=$SCRIPT ==" | tee -a "$SUMMARY"
total_done=0; total_hang=0
for r in $(seq 1 "$ROUNDS"); do
  seedbase=$(( (r * 100003 + RANDOM) % 2000000 ))
  log="logs/${LABEL}_t${THREADS}_r${r}.log"
  : > "$log"
  julia --startup-file=no -t "$THREADS" "$SCRIPT" "$NSOLVES" "$seedbase" "$SHAPE" > "$log" 2>&1 &
  pid=$!
  hang=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 10
    now=$(date +%s)
    mt=$(stat -c %Y "$log" 2>/dev/null || echo "$now")
    age=$(( now - mt ))
    if [ "$age" -gt "$STALL" ]; then
      last=$(grep -E '^(ATTEMPT|HUNT)' "$log" 2>/dev/null | tail -1)
      if echo "$last" | grep -q 'START'; then
        hang=1
        ts=$(date +%Y%m%dT%H%M%S)
        hd="hangs/${LABEL}_t${THREADS}_r${r}_${ts}"
        mkdir -p "$hd"
        cp "$log" "$hd/run.log"
        {
          echo "HANG DETECTED $(date)"
          echo "pid=$pid threads=$THREADS shape=$SHAPE seedbase=$seedbase round=$r"
          echo "log_frozen_age=${age}s stall_threshold=${STALL}s"
          echo "last_heartbeat=[$last]"
        } | tee -a "$hd/HANG.txt" | tee -a "$SUMMARY"
        # native backtraces first (most reliable for a hung, possibly-uninterruptible proc)
        if command -v gdb >/dev/null 2>&1; then
          timeout 60 gdb -p "$pid" -batch -ex 'set pagination off' -ex 'thread apply all bt' > "$hd/gdb_bt.txt" 2>&1 || true
        fi
        cat "/proc/$pid/status" > "$hd/proc_status.txt" 2>/dev/null || true
        ls -l "/proc/$pid/task" > "$hd/proc_tasks.txt" 2>/dev/null || true
        # then Julia's own SIGQUIT all-task dump
        kill -QUIT "$pid" 2>/dev/null || true
        sleep 5
        cp "$log" "$hd/run_after_sigquit.log"
        kill -9 "$pid" 2>/dev/null || true
        break
      fi
    fi
  done
  wait "$pid" 2>/dev/null
  rc=$?
  done_ct=$(grep -c 'DONE' "$log" 2>/dev/null || echo 0)
  total_done=$(( total_done + done_ct ))
  [ "$hang" -eq 1 ] && total_hang=$(( total_hang + 1 ))
  echo "round $r: rc=$rc solves_done=$done_ct hang=$hang seedbase=$seedbase (cum done=$total_done hangs=$total_hang)" | tee -a "$SUMMARY"
done
echo "== drive DONE $(date) total_solves=$total_done total_hangs=$total_hang ==" | tee -a "$SUMMARY"
