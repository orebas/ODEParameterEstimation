#!/bin/bash
#SBATCH --job-name=amigo2
#SBATCH --partition=partnsf
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8GB
#SBATCH --time=08:00:00
#SBATCH --array=0-47
#SBATCH --output=/scratch/%u/output/amigo2_%A_%a.out
#SBATCH --error=/scratch/%u/output/amigo2_%A_%a.err

# CUNY HPC — AMIGO2 (MATLAB) benchmark (batched: 25 instances per array task)
#
# Usage:
#   sbatch hpc/cuny/array_job_amigo2_cuny.s <benchmark_name> <run_name>
#   sbatch --array=0 hpc/cuny/array_job_amigo2_cuny.s benchmark_2026_02 amigo2_run  # test 1 batch
#   sbatch --array=0-47 hpc/cuny/array_job_amigo2_cuny.s benchmark_2026_02 amigo2_run  # full run

set -euo pipefail

BENCHMARK_NAME=${1:?Usage: sbatch array_job_amigo2_cuny.s <benchmark_name> <run_name>}
RUN_NAME=${2:?Usage: sbatch array_job_amigo2_cuny.s <benchmark_name> <run_name>}

# --- Environment ---
module purge
module load Utils/Matlab/R2024b

# --- GCC wrapper for AMIGO2 ---
# AMIGO2 calls gcc internally. If the cluster gcc is incompatible,
# place a wrapper script at bin/gcc in the repo that forwards to the
# correct compiler. Uncomment and adjust if needed:
# export PATH="$REPO_DIR/bin:$PATH"

# --- Paths ---
REPO_DIR="/scratch/$USER/ParameterEstimationBenchmarking"
cd "$REPO_DIR"

# Activate Python venv (pandas, chevron, etc.)
source environments/venv/bin/activate

# Ensure output directory exists
mkdir -p "/scratch/$USER/output"

# --- Batching ---
BATCH_SIZE=25
TOTAL_INSTANCES=1200
START=$((SLURM_ARRAY_TASK_ID * BATCH_SIZE))
END=$((START + BATCH_SIZE - 1))

echo "=== AMIGO2 batch start ==="
echo "Job: $SLURM_JOB_ID, Array task: $SLURM_ARRAY_TASK_ID"
echo "Instances: $START to $END (batch size $BATCH_SIZE)"
echo "Benchmark: $BENCHMARK_NAME, Run: $RUN_NAME"
echo "Node: $(hostname), Date: $(date)"
echo "MATLAB: $(matlab -batch 'disp(version)' 2>/dev/null || echo 'version check skipped')"
echo ""

FAILED=0
for IDX in $(seq "$START" "$END"); do
    if [ "$IDX" -ge "$TOTAL_INSTANCES" ]; then
        break
    fi
    echo "--- Instance $IDX ($(date)) ---"
    if ! python src/estimate.py "$BENCHMARK_NAME" "$RUN_NAME" amigo2 "$IDX"; then
        echo "FAILED: instance $IDX"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== AMIGO2 batch complete ==="
echo "Date: $(date)"
echo "Failed: $FAILED / $BATCH_SIZE"
