# CUNY HPC Benchmark Handoff

This document is written for the Claude Code instance running on the CUNY HPC
cluster (Arrow). It contains everything needed to set up and run the
`ParameterEstimationBenchmarking` benchmark suite. All values are verified from
an SSH session on 2026-02-19.

## 1. Cluster Facts

| Property | Value |
|----------|-------|
| Cluster name | Arrow |
| Scheduler | SLURM |
| Login node | MHN (via bastion `chizen.csi.cuny.edu`) |
| Architecture | x86_64, AMD EPYC |
| Module system | Lmod (`module avail`, `module spider`) |
| Account | `gbassikqc` |
| Default QOS | `qosnsf` |
| Default partition | `partnsf` (marked with `*`) |
| User ID format | `oren-qc-13` (example) |

### Partitions (from `sinfo`)

```
PARTITION  AVAIL  TIMELIMIT   NODES(A/I/O/T) NODELIST
debug        up   infinite       10/23/3/36  karle,n[1-3,5-15,17-19,21-24,27-29,99-101,130-134,136,138-139]
partnsf*     up 5-00:00:00        5/19/0/24  n[1-3,5-15,17-19,21-24,99,130-131]
partcfd      up   infinite          0/3/0/3  n[100-101,132]
partphys     up   infinite          2/0/0/2  n[138-139]
partchem     up   infinite          3/0/0/3  n[133-134,136]
partsym      up   infinite          1/0/0/1  n133
partasrc     up   infinite          1/0/0/1  n136
```

**Important:** There are NO dedicated MATLAB partitions (`partmatlabD` / `partmatlabN`
do not exist). All jobs use `partnsf`.

### Storage

| Path | Quota | Purge |
|------|-------|-------|
| `/global/u/<userid>` (home, `$HOME`) | 50 GB | Never (backed up) |
| `/scratch/<userid>` | No quota | 2 weeks idle or 70% full |

### QOS Levels Available

`normal`, `qosnsf` (your default), `qosmath`, `qoschem`, `high`, `qossymhigh`,
`qosasrchi+`, `qoseng`, `qoscfd`

### `partnsf` Resources

- 24 nodes, 1896 CPUs total
- ~8 TB RAM total (8,018,094 MB)
- 26 GPUs
- Max wall time: 5 days (120 hours)

## 2. Software Available

### Module Highlights (from `module avail`)

**Module search paths:**
- `/pfssfs1/t/share/modules/Linux`
- `/pfssfs1/t/share/modules/EPYC`
- `/pfssfs1/t/share/sys/lmod/lmod/modulefiles/Core`

**Key modules:**

| Category | Module | Notes |
|----------|--------|-------|
| MATLAB | `Utils/Matlab/R2024b` | Only version available |
| Python | `Python/3.13.7_gnu` (D) | Also: 3.10.12, 3.11.4, 3.11.5 |
| GNU compiler | `GNU/15.2.0` (D) | Also: 9.3.0, 11.3.0, 13.1.0, 13.3.0, 14.2.0 |
| AOCC | `AOCC/4.1.0` (D) | AMD optimized |
| Intel | `INTEL/1API_2023.2` | |
| Julia (module) | `DevEnv/Julia/1.9.1` | **Too old — do NOT use** |
| Conda | `DevEnv/Anaconda/25.12` | Alternative Python |
| CUDA | `Sys/CUDA/12.1.1` | |
| MPI | `OpenMPI/5.0.0_gnu` (D) | Also: 4.1.1, 4.1.5 variants |
| CMake | `Utils/Cmake/3.30.3` (D) | |
| Git | `Utils/git/2.51.1` | |
| Singularity | `Utils/Singularity/4.3.4` | |

(D) = default version

### Julia — Manual Install Required

The cluster has `DevEnv/Julia/1.9.1` which is far too old. Julia 1.12.5 must
be installed manually:

```bash
cd ~
curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.5-linux-x86_64.tar.gz | tar xz
```

This creates `~/julia-1.12.5/bin/julia`. All job scripts add it to PATH:
```bash
export PATH="$HOME/julia-1.12.5/bin:$PATH"
```

**Why `$HOME`?** Home directory persists across sessions and won't be purged.
`/scratch` is for data, not persistent software installs.

## 3. The Benchmark Pipeline

The benchmark repo is `orebas/ParameterEstimationBenchmarking` (forked from
`sumiya11/no-matlab-no-worry`), default branch: `master`.

### Pipeline Overview

```
generate_data.py → generate_scripts.py → estimate.py → collect_results.py
```

1. **`generate_data.py`** — Creates synthetic ODE data for all systems in
   `config/systems.json`. Generates instance files under `data/`.

2. **`generate_scripts.py`** — Uses Chevron/Mustache templates to generate
   Julia/MATLAB estimation scripts from templates in `templates/`.

3. **`estimate.py`** — The main entry point called by SLURM jobs:
   ```bash
   python src/estimate.py <benchmark_name> <run_name> <estimator> <instance_idx>
   ```
   Estimators: `odepe`, `sciml`, `amigo2`

4. **`collect_results.py`** — Aggregates results from individual instance runs
   into summary CSV files.

### Configuration Files

- **`config/config.json`** — Master config: paths, timeouts, estimator settings.
  Must set `PATH_TO_AMIGO2` here for AMIGO2 runs.
- **`config/systems.json`** — ODE systems to benchmark (models, parameters,
  initial conditions, observables).

### Julia Environments

The repo has three separate Julia environments under `environments/`:

| Directory | Purpose | Key Packages |
|-----------|---------|-------------|
| `julia_pe/` | Shared PE utilities | ParameterEstimation.jl |
| `julia_odepe/` | ODEPE estimator | ODEParameterEstimation.jl |
| `julia_sciml/` | SciML estimator | DiffEqFlux, Optimization |

Each has its own `Project.toml` and `Manifest.toml`.

### Environment Setup Scripts

Under `environments/`:
- **`setup_julia.s`** — SLURM job that clones Julia deps, patches them if
  needed, and precompiles all three environments. This handles
  `JULIA_DEPOT_PATH` setup.
- **`setup_python.s`** — SLURM job that creates the Python venv at
  `environments/venv/` and installs deps (pandas, chevron, etc.).

### How `estimate.py` Calls Julia

`estimate.py` generates a Julia script from a Mustache template, then runs:
```bash
julia --project=environments/julia_odepe script.jl
```
Julia must be in `$PATH` — the script calls bare `julia`, not an absolute path.

### Python venv

The benchmark expects `environments/venv/` to exist with pandas, chevron, etc.
Job scripts activate it with:
```bash
source environments/venv/bin/activate
```

## 4. NYU → CUNY Differences

The benchmark was originally designed for NYU's Greene HPC. Key adaptations:

| Feature | NYU (Greene) | CUNY (Arrow) |
|---------|-------------|-------------|
| Partition | `--partition=XXX` varies | `--partition=partnsf` (all jobs) |
| Julia | `module load julia/X.Y.Z` | `export PATH="$HOME/julia-1.12.5/bin:$PATH"` |
| MATLAB | `module load matlab/XXXX` | `module load Utils/Matlab/R2024b` |
| Python | `module load python/X.Y` | System python3 or venv |
| Scratch | `/scratch/$USER/` | `/scratch/$USER/` (same) |
| Max wall time | Varies by partition | 5 days (`partnsf`) |
| Test partition | Varies | `debug` (infinite time) |
| Login | Direct SSH | Two-hop via `chizen.csi.cuny.edu` |
| Repo path | `/scratch/$USER/ParameterEstimationBenchmarking` | Same |

## 5. Step-by-Step Setup

Follow these steps IN ORDER. Each depends on the previous.

### Step 1: Install Julia

```bash
cd ~
curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.5-linux-x86_64.tar.gz | tar xz
export PATH="$HOME/julia-1.12.5/bin:$PATH"
julia --version   # Should show 1.12.5
```

### Step 2: Clone Repos

```bash
cd /scratch/$USER

# The benchmark repo (where jobs run FROM)
git clone https://github.com/orebas/ParameterEstimationBenchmarking.git
cd ParameterEstimationBenchmarking

# The ODEPE repo (contains job scripts in hpc/cuny/)
cd /scratch/$USER
git clone https://github.com/orebas/ODEParameterEstimation.git
```

### Step 3: Create Output Directory

```bash
mkdir -p /scratch/$USER/output
```

### Step 4: Set Up Python Environment

```bash
cd /scratch/$USER/ParameterEstimationBenchmarking

# Create venv
python3 -m venv environments/venv
source environments/venv/bin/activate

# Install deps
pip install pandas chevron numpy scipy
```

### Step 5: Set Up Julia Environments

```bash
export PATH="$HOME/julia-1.12.5/bin:$PATH"
cd /scratch/$USER/ParameterEstimationBenchmarking

# Set JULIA_DEPOT_PATH to scratch (packages are large)
export JULIA_DEPOT_PATH="/scratch/$USER/.julia"

# Instantiate each Julia environment
for env in julia_pe julia_odepe julia_sciml; do
    echo "=== Setting up $env ==="
    julia --project=environments/$env -e '
        using Pkg
        Pkg.instantiate()
        Pkg.precompile()
    '
done
```

**Important:** This step downloads and compiles many packages. It can take
30-60 minutes. Consider running it as a SLURM job on a compute node rather
than the login node, or use the provided `environments/setup_julia.s` if
available (may need partition/module edits).

### Step 6: Configure AMIGO2 (if running MATLAB benchmarks)

Edit `config/config.json` and set `PATH_TO_AMIGO2` to the AMIGO2 installation
path on scratch.

### Step 7: Generate Benchmark Data

```bash
cd /scratch/$USER/ParameterEstimationBenchmarking
source environments/venv/bin/activate
python src/generate_data.py
python src/generate_scripts.py
```

### Step 8: Run Connectivity Test

```bash
cd /scratch/$USER/ParameterEstimationBenchmarking
sbatch /scratch/$USER/ODEParameterEstimation/hpc/cuny/test_connectivity.sh
# Wait for completion:
squeue -u $USER
# Check results:
cat /scratch/$USER/cuny_test_*.out
```

### Step 9: Single-Batch Test

```bash
cd /scratch/$USER/ParameterEstimationBenchmarking
sbatch --array=0 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_test
# Wait and check:
cat /scratch/$USER/output/odepe_*.out
```

### Step 10: Full Benchmark

```bash
cd /scratch/$USER/ParameterEstimationBenchmarking

sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_nopolish
sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_polish
sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_sciml_cuny.s benchmark_2026_02 sciml_run
sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_amigo2_cuny.s benchmark_2026_02 amigo2_run
```

### Step 11: Collect Results

```bash
cd /scratch/$USER/ParameterEstimationBenchmarking
source environments/venv/bin/activate
python src/collect_results.py benchmark_2026_02
```

## 6. Key Gotchas

### JULIA_DEPOT_PATH
Julia's package cache (`~/.julia/`) can grow to 10+ GB. With a 50 GB home
quota, set:
```bash
export JULIA_DEPOT_PATH="/scratch/$USER/.julia"
```
Put this in your `~/.bashrc` to make it persistent. **Risk:** scratch gets
purged — if packages disappear, re-run Step 5.

### Scratch Purge
Files on `/scratch` idle for 2 weeks get purged (or sooner at 70% full).
- Keep jobs running regularly to refresh timestamps
- Back up results to `$HOME` or off-cluster
- Julia depot on scratch will need re-instantiation after purge

### Python in venv vs System
Job scripts use `python` (not `python3`) after activating the venv. The venv's
`bin/python` is a symlink to the Python that created it. If the system Python
changes or gets removed, recreate the venv.

### MKL
Some Julia templates may `using MKL`. The CUNY cluster has BLAS/LAPACK/MKL
modules available. If Julia MKL.jl fails to load, ensure:
```bash
module load Libs/MKL/2024.2
```
Or remove `using MKL` from the templates if it's not needed.

### estimate.py Calling Convention
The benchmark's `estimate.py` expects exactly 4 positional arguments:
```bash
python src/estimate.py <benchmark_name> <run_name> <estimator> <instance_idx>
```
The CUNY scripts `cd` into the repo first, so all paths in `estimate.py` are
relative to the repo root.

### Job Script Location
The SLURM job scripts live in the **ODEParameterEstimation** repo, not the
benchmark repo. When submitting, use full paths:
```bash
sbatch /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_odepe_cuny.s ...
```
Or copy them into the benchmark repo if preferred.

### Pre-existing `environments/setup_*.s` Scripts
The benchmark repo may include its own `setup_julia.s` and `setup_python.s`
SLURM scripts. These were written for NYU and will need the same partition/module
fixes applied to them:
- `--partition=partnsf` (not whatever NYU used)
- `export PATH="$HOME/julia-1.12.5/bin:$PATH"` (not `module load julia`)

## 7. Monitoring and Troubleshooting

```bash
# Check job status
squeue -u $USER

# Detailed job info
sacct -j <JOBID> --format=JobID,JobName,State,Elapsed,MaxRSS,ExitCode

# Job output
cat /scratch/$USER/output/<jobname>_<jobid>_<taskid>.out

# Cancel jobs
scancel <JOBID>           # cancel one job
scancel -u $USER          # cancel all your jobs

# Partition status
sinfo -p partnsf

# Account balance / limits
sacctmgr show assoc where user=$USER
```

## 8. Files in This Directory

| File | Purpose |
|------|---------|
| `array_job_odepe_cuny.s` | SLURM array job for ODEPE benchmarks (4 CPU, 16 GB) |
| `array_job_sciml_cuny.s` | SLURM array job for SciML benchmarks (1 CPU, 8 GB) |
| `array_job_amigo2_cuny.s` | SLURM array job for AMIGO2/MATLAB benchmarks (1 CPU, 8 GB) |
| `test_connectivity.sh` | Connectivity test (debug partition, 30 min) |
| `setup_cuny.sh` | Environment discovery script (run on login node) |
| `rerun_failed.sh` | Regenerate SLURM scripts for failed instances |
| `README.md` | Quick-reference documentation |
| `HANDOFF.md` | This file — comprehensive setup guide |
