#!/usr/bin/env bash
# driver2.sh — watchdog driver for attempt.jl (multi-arm hunter).
#
# Runs ROUNDS julia processes, each doing NSOLVES attempts (attempt.jl prints a
# flushed heartbeat around every phase). Watchdog: if the process is alive but
# its log mtime has been frozen > STALL seconds, and any ATTEMPT has a
# START/SOLVE heartbeat without a matching DONE/ERROR, declare DEADLOCK:
#   1. gdb thread-apply-all-bt (native stacks — works even if runtime is wedged)
#   2. /proc status + per-task wchan/stat
#   3. kill -USR1 (Julia >=1.8 "profile peek": prints all-task backtraces)
#   4. save log, kill -9, continue with next round.
# If the log stalls with NO pending attempt (e.g. wedged between attempts or in
# a print), it is captured too (classified NOPENDING).
#
# A hard `timeout` around julia guarantees no orphan can outlive HARDCAP even
# if this script dies.
#
# Usage: [SCRIPT=x.jl] driver3.sh <label> <threads> <mode> <hcthr> <nworkers> <rounds> <nsolves> <stall_secs> <shape>
set -uo pipefail
cd "$(dirname "$0")"
LABEL=${1:?label}; THREADS=${2:?threads}; MODE=${3:?mode}; HCTHR=${4:?hcthr}
NW=${5:?nworkers}; ROUNDS=${6:?rounds}; NSOLVES=${7:?nsolves}
STALL=${8:?stall}; SHAPE=${9:?shape}
mkdir -p logs hangs
SUMMARY="logs/${LABEL}_summary.txt"
HARDCAP=$(( STALL * 3 + NSOLVES * 90 + 600 ))
echo "== driver2 start $(date) label=$LABEL threads=$THREADS mode=$MODE hcthr=$HCTHR nw=$NW rounds=$ROUNDS nsolves=$NSOLVES stall=$STALL shape=$SHAPE hardcap=${HARDCAP}s ==" | tee -a "$SUMMARY"
total_done=0; total_hang=0
for r in $(seq 1 "$ROUNDS"); do
  seedbase=$(( (r * 100003 + RANDOM) % 2000000 ))
  log="logs/${LABEL}_r${r}.log"
  : > "$log"
  timeout -k 30 "$HARDCAP" julia --startup-file=no -t "$THREADS" "${SCRIPT:-attempt.jl}" \
      "$MODE" "$HCTHR" "$NW" "$NSOLVES" "$seedbase" "$SHAPE" > "$log" 2>&1 &
  pid=$!
  hang=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 15
    now=$(date +%s)
    mt=$(stat -c %Y "$log" 2>/dev/null || echo "$now")
    age=$(( now - mt ))
    if [ "$age" -gt "$STALL" ] && kill -0 "$pid" 2>/dev/null; then
      # ids with START but no DONE/ERROR
      pending=$(awk '$1=="ATTEMPT"{if($3=="START")s[$2]=1; if($3=="DONE"||$3=="ERROR")delete s[$2]} END{for(k in s)printf "%s ",k}' "$log")
      # find the julia grandchild (timeout -> julia)
      jpid=$(pgrep -P "$pid" -f 'julia' | head -1); [ -z "$jpid" ] && jpid=$pid
      hang=1
      ts=$(date +%Y%m%dT%H%M%S)
      hd="hangs/${LABEL}_r${r}_${ts}"
      mkdir -p "$hd"
      cp "$log" "$hd/run.log"
      {
        echo "HANG DETECTED $(date)"
        echo "label=$LABEL threads=$THREADS mode=$MODE hcthr=$HCTHR nw=$NW shape=$SHAPE seedbase=$seedbase round=$r"
        echo "watchdog_pid=$pid julia_pid=$jpid log_frozen_age=${age}s stall_threshold=${STALL}s"
        echo "pending_attempts=[${pending:-NOPENDING}]"
        echo "loadavg=$(cat /proc/loadavg)"
      } | tee "$hd/HANG.txt" | tee -a "$SUMMARY"
      if command -v gdb >/dev/null 2>&1; then
        timeout 120 gdb -p "$jpid" -batch -ex 'set pagination off' \
            -ex 'thread apply all bt' > "$hd/gdb_bt.txt" 2>&1 || true
      fi
      cat "/proc/$jpid/status" > "$hd/proc_status.txt" 2>/dev/null || true
      for t in /proc/$jpid/task/*; do
        echo "== task $(basename "$t") wchan=$(cat "$t/wchan" 2>/dev/null) stat=$(awk '{print $3}' "$t/stat" 2>/dev/null)"
      done > "$hd/proc_tasks.txt" 2>/dev/null || true
      kill -USR1 "$jpid" 2>/dev/null || true
      sleep 10
      cp "$log" "$hd/run_after_usr1.log"
      kill -9 "$jpid" "$pid" 2>/dev/null || true
      break
    fi
  done
  wait "$pid" 2>/dev/null
  rc=$?
  done_ct=$(grep -c ' DONE ' "$log" 2>/dev/null || echo 0)
  total_done=$(( total_done + done_ct ))
  [ "$hang" -eq 1 ] && total_hang=$(( total_hang + 1 ))
  echo "round $r: rc=$rc solves_done=$done_ct hang=$hang seedbase=$seedbase (cum done=$total_done hangs=$total_hang)" | tee -a "$SUMMARY"
done
echo "== driver2 DONE $(date) label=$LABEL total_solves=$total_done total_hangs=$total_hang ==" | tee -a "$SUMMARY"
