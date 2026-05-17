#!/bin/bash -e
#
# Local-slurm runner for a single recheck cell. Replicates the cluster's
# probe_one_cell.s but adapted for the Bassik-Main local node and the global
# Julia environment used by this dev setup.
#
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=2:00:00
#SBATCH --mem=6GB
#SBATCH --job-name=06_lost_recheck
#SBATCH --partition=local
#SBATCH --output=%j_%x.out
#SBATCH --error=%j_%x.err

export JULIA_NUM_THREADS=${SLURM_CPUS_PER_TASK:-4}

PROBE_DIR="$1"
if [ -z "$PROBE_DIR" ] || [ ! -d "$PROBE_DIR" ]; then
  echo "Usage: sbatch run_one_cell.s <probe_dir>" >&2
  exit 1
fi

cd "$PROBE_DIR"
{
  echo "### Probe start: $(date)"
  echo "### probe_dir: $(pwd)"
  echo "### SLURM_JOB_ID: $SLURM_JOB_ID"
  echo "### JULIA_NUM_THREADS: $JULIA_NUM_THREADS"
} > stdout.txt

julia --startup-file=no script.jl >> stdout.txt 2> stderr.txt || true

echo "### Probe end: $(date) (exit $?)" >> stdout.txt
