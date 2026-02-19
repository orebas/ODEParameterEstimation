# CUNY HPC Benchmark Setup

Reference for running the `ParameterEstimationBenchmarking` benchmark suite on
CUNY HPC (Arrow cluster, wiki.csi.cuny.edu/cunyhpc).

## Login Procedure (Two-Hop SSH)

From off-campus, SSH requires a bastion hop through `chizen.csi.cuny.edu`:

```bash
# One-step login (add to ~/.ssh/config):
Host cuny-hpc
    HostName MHN              # master head node
    User <your-userid>
    ProxyJump chizen.csi.cuny.edu

# Then: ssh cuny-hpc
```

Or manually:
```bash
ssh <userid>@chizen.csi.cuny.edu    # bastion
ssh MHN                               # login/head node
```

File transfer uses `cea.csi.cuny.edu` (SFTP) or SCP with proxy jump:
```bash
scp -J chizen.csi.cuny.edu localfile <userid>@MHN:/scratch/<userid>/
```

## Storage Layout

| Path | Quota | Backup | Purge Policy |
|------|-------|--------|-------------|
| `/global/u/<userid>` (home) | 50 GB | Yes | None |
| `/scratch/<userid>` | No quota | No | **2 weeks idle or 70% filesystem full** |

**All jobs must run from `/scratch`**. Never run compute on the head node.

## SLURM Partitions (verified via `sinfo`)

| Partition | Default | Time Limit | Nodes (A/I/O/T) | Notes |
|-----------|---------|------------|------------------|-------|
| `debug` | | infinite | 10/23/3/36 | Development/testing |
| `partnsf` | **\*** | 5-00:00:00 (5 days) | 5/19/0/24 | **Default — use for all benchmarks** |
| `partcfd` | | infinite | 0/3/0/3 | CFD research group |
| `partphys` | | infinite | 2/0/0/2 | Physics research group |
| `partchem` | | infinite | 3/0/0/3 | Chemistry research group |
| `partsym` | | infinite | 1/0/0/1 | Symbolic math group |
| `partasrc` | | infinite | 1/0/0/1 | ASRC group |

**Account:** `gbassikqc`, **QOS:** `qosnsf` (default), **Cluster:** `arrow`

`partnsf` has: 1896 CPUs, ~8 TB RAM, 26 GPUs across 24 nodes.

## Software Environment

### Julia
**Not available as a module.** Install manually to `$HOME`:
```bash
cd ~
curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.5-linux-x86_64.tar.gz | tar xz
# Creates ~/julia-1.12.5/bin/julia
```
All job scripts use `export PATH="$HOME/julia-1.12.5/bin:$PATH"`.

### MATLAB
```bash
module load Utils/Matlab/R2024b
```

### Python
System Python 3 is available. The benchmark uses a venv at `environments/venv/`.

### Key Modules
- Compilers: `GNU/15.2.0` (default), `AOCC/4.1.0`, `INTEL/1API_2023.2`
- MPI: `OpenMPI/5.0.0_gnu` (default)
- CUDA: `Sys/CUDA/12.1.1`
- Python: `Python/3.13.7_gnu` (default)

## Batching Strategy

48 array tasks x 25 instances = 1200 total instances per benchmark run.
4 runs x 48 tasks = 192 total SLURM jobs.

- Array range: `--array=0-47`
- All runs use `--partition=partnsf`
- Max wall time: 5 days (benchmark jobs request 8 hours)

## First-Time Setup

1. SSH to CUNY HPC (two-hop)
2. Install Julia 1.12.5:
   ```bash
   cd ~ && curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.5-linux-x86_64.tar.gz | tar xz
   ```
3. Clone benchmark repo:
   ```bash
   cd /scratch/$USER
   git clone https://github.com/orebas/ParameterEstimationBenchmarking.git
   cd ParameterEstimationBenchmarking
   ```
4. Also clone this repo (for the CUNY job scripts):
   ```bash
   cd /scratch/$USER
   git clone https://github.com/orebas/ODEParameterEstimation.git
   ```
5. Set up environments (Python venv + Julia environments):
   ```bash
   # See HANDOFF.md for detailed instructions
   ```
6. Submit connectivity test:
   ```bash
   cd /scratch/$USER/ParameterEstimationBenchmarking
   sbatch /scratch/$USER/ODEParameterEstimation/hpc/cuny/test_connectivity.sh
   cat /scratch/$USER/cuny_test_*.out
   ```
7. Single-batch test:
   ```bash
   sbatch --array=0 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_nopolish
   ```
8. Once tests pass, submit full benchmark (see below)

## Full Benchmark Submission

```bash
cd /scratch/$USER/ParameterEstimationBenchmarking

# 4 runs x 48 array tasks = 192 total SLURM jobs
sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_nopolish
sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_odepe_cuny.s benchmark_2026_02 odepe_polish
sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_sciml_cuny.s benchmark_2026_02 sciml_run
sbatch --array=0-47 /scratch/$USER/ODEParameterEstimation/hpc/cuny/array_job_amigo2_cuny.s benchmark_2026_02 amigo2_run
```

## Monitoring

```bash
squeue -u $USER                    # check running jobs
sacct -j <JOBID> --format=JobID,State,Elapsed,MaxRSS  # job details
cat /scratch/$USER/output/*.out    # job output
```
