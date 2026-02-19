#!/bin/bash
#SBATCH --job-name=cuny_test
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4GB
#SBATCH --time=00:30:00
#SBATCH --output=/scratch/%u/cuny_test_%j.out
#SBATCH --error=/scratch/%u/cuny_test_%j.err

# Connectivity test for CUNY HPC benchmark environment.
# Submit with: sbatch hpc/cuny/test_connectivity.sh
# Check output: cat /scratch/$USER/cuny_test_*.out

echo "============================================"
echo "  CUNY HPC Connectivity Test"
echo "============================================"
echo "Node:       $(hostname)"
echo "Date:       $(date)"
echo "User:       $USER"
echo "Scratch:    /scratch/$USER"
echo "Working dir: $(pwd)"
echo "Job ID:     $SLURM_JOB_ID"
echo ""

# --- Julia ---
echo "=== Julia test ==="
export PATH="$HOME/julia-1.12.5/bin:$PATH"
julia --version 2>&1 || echo "Julia not available — install to ~/julia-1.12.5/"
julia -e 'println("Julia works! Threads: ", Threads.nthreads())' 2>&1 || echo "Julia execution failed"
echo ""

# --- MATLAB ---
echo "=== MATLAB test ==="
module load Utils/Matlab/R2024b 2>/dev/null || echo "(module load Utils/Matlab/R2024b failed)"
matlab -batch "disp('MATLAB works!')" 2>&1 || echo "MATLAB not available"
echo ""

# --- Python ---
echo "=== Python test ==="
python3 --version 2>&1 || echo "Python3 not available"
# Test venv if it exists
REPO_DIR="/scratch/$USER/ParameterEstimationBenchmarking"
if [ -f "$REPO_DIR/environments/venv/bin/activate" ]; then
    source "$REPO_DIR/environments/venv/bin/activate"
    echo "Activated venv: $(which python)"
fi
python -c "import json, subprocess; print('Python works!')" 2>&1 || echo "Python execution failed"
python -c "import pandas; print('pandas version:', pandas.__version__)" 2>&1 || echo "pandas not installed"
python -c "import chevron; print('chevron available')" 2>&1 || echo "chevron not installed"
echo ""

# --- Filesystem ---
echo "=== Filesystem test ==="
echo "Scratch writable: $(touch /scratch/$USER/.test_write && echo YES && rm /scratch/$USER/.test_write || echo NO)"
echo "Scratch free space:"
df -h /scratch/$USER 2>/dev/null || echo "Cannot stat scratch"
echo ""

# --- Julia environments ---
echo "=== Julia environments ==="
if [ -d "$REPO_DIR/environments" ]; then
    for env in julia_pe julia_odepe julia_sciml; do
        if [ -f "$REPO_DIR/environments/$env/Project.toml" ]; then
            echo "$env: found"
        else
            echo "$env: MISSING"
        fi
    done
else
    echo "Benchmark repo not found at $REPO_DIR"
fi
echo ""

echo "============================================"
echo "  All tests complete"
echo "============================================"
