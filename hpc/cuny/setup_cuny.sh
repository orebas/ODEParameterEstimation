#!/bin/bash
# First-time setup for CUNY HPC benchmark
# Run from the login node after SSH'ing in.
#
# Usage: bash hpc/cuny/setup_cuny.sh
#
# This script discovers available modules, partitions, and filesystem layout.
# Use its output to verify the environment before running benchmarks.

set -euo pipefail

SCRATCH_DIR="/scratch/$USER"
REPO_DIR="$SCRATCH_DIR/ParameterEstimationBenchmarking"

echo "============================================"
echo "  CUNY HPC Environment Discovery"
echo "============================================"
echo "User:    $USER"
echo "Home:    $HOME"
echo "Scratch: $SCRATCH_DIR"
echo "Date:    $(date)"
echo ""

# --- Julia ---
echo "=== Julia check ==="
if [ -x "$HOME/julia-1.12.5/bin/julia" ]; then
    echo "Julia found: $HOME/julia-1.12.5/bin/julia"
    "$HOME/julia-1.12.5/bin/julia" --version
else
    echo "Julia NOT found at $HOME/julia-1.12.5/"
    echo "Install with:"
    echo "  cd ~"
    echo "  curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.5-linux-x86_64.tar.gz | tar xz"
    echo "  # This creates ~/julia-1.12.5/"
fi
echo ""

# --- Julia module (legacy, for reference) ---
echo "=== Available Julia modules ==="
module spider julia 2>&1 || echo "Julia not found as module (expected — use manual install)"
echo ""

# --- MATLAB ---
echo "=== MATLAB module ==="
module spider Utils/Matlab 2>&1 || echo "MATLAB not found"
echo "Expected: module load Utils/Matlab/R2024b"
echo ""

# --- Python ---
echo "=== Available Python modules ==="
module spider python 2>&1 || echo "Python not found as module"
echo ""
echo "System Python3:"
python3 --version 2>&1 || echo "python3 not in PATH"
echo ""

# --- GCC ---
echo "=== Available GCC modules ==="
module spider gcc 2>&1 || echo "GCC not found as module (try: module spider GNU)"
echo ""
echo "System GCC:"
gcc --version 2>&1 | head -1 || echo "gcc not in PATH"
echo ""

# --- Filesystem ---
echo "=== Scratch filesystem ==="
df -h "$SCRATCH_DIR" 2>/dev/null || echo "Scratch not mounted (are you on the right node?)"
echo ""
echo "=== Home filesystem ==="
df -h "$HOME" 2>/dev/null || echo "Cannot stat home directory"
echo ""

# --- SLURM ---
echo "=== SLURM partitions ==="
sinfo -s 2>&1 || echo "SLURM not available on this node"
echo ""

echo "=== SLURM detailed partition info ==="
sinfo -o "%P %l %D %C %m %G" 2>&1 || echo "Cannot query partition details"
echo ""

echo "=== SLURM MaxArraySize ==="
scontrol show config 2>&1 | grep -i maxarray || echo "Cannot query SLURM config"
echo ""

echo "=== SLURM account/QOS ==="
sacctmgr show assoc where user=$USER format=User,Account,QOS,DefaultQOS 2>&1 | head -10 || echo "Cannot query associations"
echo ""

# --- Summary ---
echo "============================================"
echo "  Next Steps"
echo "============================================"
echo "1. Install Julia 1.12.5 (if not already done):"
echo "     cd ~ && curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.5-linux-x86_64.tar.gz | tar xz"
echo ""
echo "2. Clone benchmark repo to scratch:"
echo "     cd /scratch/$USER"
echo "     git clone https://github.com/orebas/ParameterEstimationBenchmarking.git"
echo ""
echo "3. Set up Python venv and Julia environments:"
echo "     cd $REPO_DIR"
echo "     # Follow instructions in HANDOFF.md or environments/setup_*.s"
echo ""
echo "4. Set PATH_TO_AMIGO2 in config/config.json"
echo ""
echo "5. Submit connectivity test:"
echo "     cd $REPO_DIR"
echo "     sbatch hpc/cuny/test_connectivity.sh"
echo ""
echo "6. Check output:"
echo "     cat /scratch/$USER/cuny_test_*.out"
echo ""
echo "7. Submit single-batch test:"
echo "     sbatch --array=0 hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_nopolish"
echo ""
