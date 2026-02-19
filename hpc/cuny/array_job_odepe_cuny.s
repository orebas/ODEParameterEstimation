#!/bin/bash
#SBATCH --job-name=odepe
#SBATCH --partition=partnsf
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16GB
#SBATCH --time=08:00:00
#SBATCH --array=0-47
#SBATCH --output=/scratch/%u/output/odepe_%A_%a.out
#SBATCH --error=/scratch/%u/output/odepe_%A_%a.err

# CUNY HPC — ODEPE benchmark (batched: 25 instances per array task)
#
# Usage:
#   sbatch hpc/cuny/array_job_odepe_cuny.s <benchmark_name> <run_name>
#   sbatch --array=0 hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_nopolish  # test 1 batch
#   sbatch --array=0-47 hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_nopolish  # full run

set -euo pipefail

BENCHMARK_NAME=${1:?Usage: sbatch array_job_odepe_cuny.s <benchmark_name> <run_name>}
RUN_NAME=${2:?Usage: sbatch array_job_odepe_cuny.s <benchmark_name> <run_name>}

# --- Environment ---
module purge
export PATH="$HOME/julia-1.12.5/bin:$PATH"

export JULIA_NUM_THREADS=4

# --- Paths ---
REPO_DIR="/scratch/$USER/ParameterEstimationBenchmarking"
cd "$REPO_DIR"

# Activate Python venv (pandas, chevron, etc.)
source environments/venv/bin/activate

# Ensure output directory exists
mkdir -p "/scratch/$USER/output"

# --- Batching ---
# 25 instances per array task: task 0 -> instances 0-24, task 1 -> 25-49, etc.
BATCH_SIZE=25
TOTAL_INSTANCES=1200
START=$((SLURM_ARRAY_TASK_ID * BATCH_SIZE))
END=$((START + BATCH_SIZE - 1))

echo "=== ODEPE batch start ==="
echo "Job: $SLURM_JOB_ID, Array task: $SLURM_ARRAY_TASK_ID"
echo "Instances: $START to $END (batch size $BATCH_SIZE)"
echo "Benchmark: $BENCHMARK_NAME, Run: $RUN_NAME"
echo "Node: $(hostname), Date: $(date)"
echo "Julia: $(julia --version)"
echo ""

FAILED=0
for IDX in $(seq "$START" "$END"); do
    if [ "$IDX" -ge "$TOTAL_INSTANCES" ]; then
        break
    fi
    echo "--- Instance $IDX ($(date)) ---"
    if ! python src/estimate.py "$BENCHMARK_NAME" "$RUN_NAME" odepe "$IDX"; then
        echo "FAILED: instance $IDX"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== ODEPE batch complete ==="
echo "Date: $(date)"
echo "Failed: $FAILED / $BATCH_SIZE"
