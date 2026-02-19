#!/bin/bash
# Rerun failed instances from a batched CUNY HPC benchmark run.
#
# With batched jobs (25 instances per array task), a failed batch means
# up to 25 instances may need rerunning. This script:
# 1. Scans output files for the benchmark/run to find which instances succeeded
# 2. Identifies missing instance results
# 3. Generates sbatch commands to rerun only the failed instances
#
# Usage:
#   bash hpc/cuny/rerun_failed.sh <benchmark_name> <run_name> <estimator>
#
# Example:
#   bash hpc/cuny/rerun_failed.sh benchmark_2026_02 odepe_nopolish odepe

set -euo pipefail

BENCHMARK_NAME=${1:?Usage: rerun_failed.sh <benchmark_name> <run_name> <estimator>}
RUN_NAME=${2:?Usage: rerun_failed.sh <benchmark_name> <run_name> <estimator>}
ESTIMATOR=${3:?Usage: rerun_failed.sh <benchmark_name> <run_name> <estimator>}

REPO_DIR="/scratch/$USER/ParameterEstimationBenchmarking"
RESULTS_DIR="$REPO_DIR/results/$BENCHMARK_NAME/$RUN_NAME"
TOTAL_INSTANCES=1200
BATCH_SIZE=25

echo "Scanning results for: $BENCHMARK_NAME / $RUN_NAME ($ESTIMATOR)"
echo "Results dir: $RESULTS_DIR"
echo ""

if [ ! -d "$RESULTS_DIR" ]; then
    echo "ERROR: Results directory does not exist: $RESULTS_DIR"
    echo "Has the benchmark been run at least once?"
    exit 1
fi

# Find which instances have result files.
# The benchmark writes one result file per instance — the exact naming
# convention depends on the benchmark harness. Adjust the pattern below
# to match your output format.
#
# Common patterns:
#   results/<benchmark>/<run>/instance_<IDX>.csv
#   results/<benchmark>/<run>/<model>_<IDX>.json
#
# We look for any file containing the instance index.
MISSING=()
for IDX in $(seq 0 $((TOTAL_INSTANCES - 1))); do
    # Check if a result file exists for this instance.
    # Adjust this glob pattern to match your benchmark's output format.
    if ! ls "$RESULTS_DIR"/*"_${IDX}."* >/dev/null 2>&1 && \
       ! ls "$RESULTS_DIR"/*"_${IDX}_"* >/dev/null 2>&1; then
        MISSING+=("$IDX")
    fi
done

NUM_MISSING=${#MISSING[@]}
echo "Found $NUM_MISSING missing instances out of $TOTAL_INSTANCES"

if [ "$NUM_MISSING" -eq 0 ]; then
    echo "All instances have results. Nothing to rerun."
    exit 0
fi

echo ""
echo "Missing instances: ${MISSING[*]:0:20}$([ "$NUM_MISSING" -gt 20 ] && echo " ... and $((NUM_MISSING - 20)) more")"
echo ""

# Group missing instances into batches and generate rerun commands.
# For small numbers of failures, we generate individual python commands
# wrapped in a single SLURM job. For large numbers, we generate array jobs.

RERUN_SCRIPT="/scratch/$USER/rerun_${BENCHMARK_NAME}_${RUN_NAME}.sh"

if [ "$NUM_MISSING" -le "$BATCH_SIZE" ]; then
    # Few enough to run in a single job
    echo "Generating single-job rerun script: $RERUN_SCRIPT"
    {
        echo "#!/bin/bash"
        echo "#SBATCH --job-name=rerun_${ESTIMATOR}"
        echo "#SBATCH --partition=partnsf"
        echo "#SBATCH --nodes=1"
        echo "#SBATCH --ntasks=1"
        if [ "$ESTIMATOR" = "odepe" ]; then
            echo "#SBATCH --cpus-per-task=4"
            echo "#SBATCH --mem=16GB"
        else
            echo "#SBATCH --cpus-per-task=1"
            echo "#SBATCH --mem=8GB"
        fi
        echo "#SBATCH --time=08:00:00"
        echo "#SBATCH --output=/scratch/%u/output/rerun_${ESTIMATOR}_%j.out"
        echo "#SBATCH --error=/scratch/%u/output/rerun_${ESTIMATOR}_%j.err"
        echo ""
        echo "set -euo pipefail"
        echo "module purge"
        if [ "$ESTIMATOR" = "amigo2" ]; then
            echo "module load Utils/Matlab/R2024b"
        else
            echo "export PATH=\"\$HOME/julia-1.12.5/bin:\$PATH\""
        fi
        if [ "$ESTIMATOR" = "odepe" ]; then
            echo "export JULIA_NUM_THREADS=4"
        fi
        echo "cd $REPO_DIR"
        echo "source environments/venv/bin/activate"
        echo ""
        echo "FAILED=0"
        for IDX in "${MISSING[@]}"; do
            echo "echo '--- Instance $IDX ---'"
            echo "python src/estimate.py $BENCHMARK_NAME $RUN_NAME $ESTIMATOR $IDX || FAILED=\$((FAILED + 1))"
        done
        echo ""
        echo "echo \"Rerun complete. Failed: \$FAILED / $NUM_MISSING\""
    } > "$RERUN_SCRIPT"
    chmod +x "$RERUN_SCRIPT"
    echo ""
    echo "Submit with:"
    echo "  sbatch $RERUN_SCRIPT"
else
    # Too many for one job — compute how many array tasks we need
    NUM_BATCHES=$(( (NUM_MISSING + BATCH_SIZE - 1) / BATCH_SIZE ))
    MAX_ARRAY_IDX=$((NUM_BATCHES - 1))

    echo "Generating array rerun script: $RERUN_SCRIPT"
    echo "  $NUM_MISSING instances -> $NUM_BATCHES array tasks"

    # Write the missing instance list to a file for the array job to read
    MISSING_LIST="/scratch/$USER/missing_${BENCHMARK_NAME}_${RUN_NAME}.txt"
    printf '%s\n' "${MISSING[@]}" > "$MISSING_LIST"

    {
        echo "#!/bin/bash"
        echo "#SBATCH --job-name=rerun_${ESTIMATOR}"
        echo "#SBATCH --partition=partnsf"
        echo "#SBATCH --nodes=1"
        echo "#SBATCH --ntasks=1"
        if [ "$ESTIMATOR" = "odepe" ]; then
            echo "#SBATCH --cpus-per-task=4"
            echo "#SBATCH --mem=16GB"
        else
            echo "#SBATCH --cpus-per-task=1"
            echo "#SBATCH --mem=8GB"
        fi
        echo "#SBATCH --time=08:00:00"
        echo "#SBATCH --array=0-${MAX_ARRAY_IDX}"
        echo "#SBATCH --output=/scratch/%u/output/rerun_${ESTIMATOR}_%A_%a.out"
        echo "#SBATCH --error=/scratch/%u/output/rerun_${ESTIMATOR}_%A_%a.err"
        echo ""
        echo "set -euo pipefail"
        echo "module purge"
        if [ "$ESTIMATOR" = "amigo2" ]; then
            echo "module load Utils/Matlab/R2024b"
        else
            echo "export PATH=\"\$HOME/julia-1.12.5/bin:\$PATH\""
        fi
        if [ "$ESTIMATOR" = "odepe" ]; then
            echo "export JULIA_NUM_THREADS=4"
        fi
        echo "cd $REPO_DIR"
        echo "source environments/venv/bin/activate"
        echo ""
        echo "# Read missing instance list"
        echo "mapfile -t ALL_MISSING < $MISSING_LIST"
        echo "BATCH_SIZE=$BATCH_SIZE"
        echo "START=\$((SLURM_ARRAY_TASK_ID * BATCH_SIZE))"
        echo "END=\$((START + BATCH_SIZE - 1))"
        echo ""
        echo "FAILED=0"
        echo "for I in \$(seq \$START \$END); do"
        echo "    [ \$I -ge \${#ALL_MISSING[@]} ] && break"
        echo "    IDX=\${ALL_MISSING[\$I]}"
        echo "    echo \"--- Instance \$IDX (rerun) ---\""
        echo "    python src/estimate.py $BENCHMARK_NAME $RUN_NAME $ESTIMATOR \$IDX || FAILED=\$((FAILED + 1))"
        echo "done"
        echo ""
        echo "echo \"Rerun batch complete. Failed: \$FAILED\""
    } > "$RERUN_SCRIPT"
    chmod +x "$RERUN_SCRIPT"
    echo ""
    echo "Missing instance list: $MISSING_LIST"
    echo "Submit with:"
    echo "  sbatch $RERUN_SCRIPT"
fi
