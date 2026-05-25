# Quoll Benchmark Handoff Spec

Date: 2026-05-25

Audience: Claude-on-the-cluster / whoever is managing the large PEB runs.

Purpose: define the next benchmark family, **Quoll**, with enough detail that
the cluster-side agent can implement and run it without re-litigating the
experiment design.

## Executive Summary

Quoll should not be "run everything and filter later." It should be a small set
of named benchmark subexperiments with different purposes:

1. **Quoll Smoke**: local or cluster-tiny validation that the new branch-stress
   systems run through PEB at all.
2. **Quoll Branch Suite**: focused test of finite branch handling, including
   aggregate-observation branch systems and observed-output controls.
3. **Quoll Low-Data Suite**: focused test of sparse-data behavior, separate from
   branch stress.
4. **Quoll Main / Paper Suite**: final, larger run that combines the stable
   wallaby/numbat model set with tagged branch systems and selected comparator
   methods.

The main new scientific claim being isolated is:

> ODEPE can use structural identifiability and algebraic degree information to
> calibrate the returned solution set, so finite non-identifiability is handled
> as a first-class object rather than as an accidental byproduct of multistart
> optimization.

This claim is different from the broader noisy-recovery claim. Keep the branch
results stratified in analysis and reporting.

## Wallaby Estimator Set and Terminology

Quoll should start from the actual Wallaby estimator set, not from the full list
of estimators that PEB happens to support.

Wallaby (`benchmark_wallaby_2026-05-17`) ran:

```text
odepe_v2_polish
odepe_v2_nopolish
odepe_shade
amigo2
```

This is recorded in Wallaby's `MANIFEST.toml`:

```text
software_list = ["odepe_v2_polish", "odepe_v2_nopolish", "odepe_shade", "amigo2"]
estimators = ["odepe_v2_polish", "odepe_v2_nopolish", "odepe_shade", "amigo2"]
```

The Wallaby filetree also contains:

```text
filetree/odepe_v2_polish_run
filetree/odepe_v2_nopolish_run
filetree/odepe_shade_run
filetree/amigo2_run
```

It does **not** contain a `sciml_run`.

`sciml` and `odepe_shade` are distinct PEB runners, but `sciml` was not part of
Wallaby:

- `sciml` is the generic SciML/Optimization.jl reference estimator. It lives in
  the `julia_sciml` environment and renders from
  `templates/julia_template_for_estimation_sciml.jl`.
- `odepe_shade` is an ODEPE-family estimator that uses the SHADE + local
  least-squares/hybrid path. It lives in the `julia_odepe` environment and
  renders from `templates/julia_template_for_estimation_odepe_shade.jl`.
- `odepe_v2_polish` and `odepe_v2_nopolish` are the main ODEPE variants from
  the recent numbat/wallaby work. They share the ODEPE v2 template and differ by
  the `ODEPE_POLISH` toggle.

So: SciML is a comparator stack. SHADE is an ODEPE variant / optimizer path.
Do not call SHADE "SciML" in run names, tables, or analysis.

Relevant software keys in PEB include:

```text
odepe_v2_polish
odepe_v2_nopolish
odepe_shade
amigo2
sciml
pe
```

For Quoll, the Wallaby-faithful set is:

```text
odepe_v2_polish
odepe_v2_nopolish
odepe_shade
amigo2
```

`sciml` should not be included by default just because PEB supports it. Add it
only as a separate optional add-on if there is a specific reason to compare
against the generic SciML/Optimization.jl stack.

If that add-on is run, keep it clearly labeled:

```text
sciml
```

Do not include `pe` unless the goal is explicitly historical comparison with
ParameterEstimation.jl; it will usually distract from the Quoll branch question.

## Repositories and Paths

Local working copies seen from this machine:

```text
/home/orebas/.julia/dev/ODEParameterEstimation
/home/orebas/ParameterEstimationBenchmark-local
/home/orebas/parameter_estimation_workspace/ParameterEstimationBenchmarking
/home/orebas/rsync-readonly-PEB
```

Cluster-side paths used by the existing CUNY scripts:

```text
/scratch/oren-qc-13/ParameterEstimationBenchmarking
/scratch/oren-qc-13/julia-1.12.5/bin
/scratch/oren-qc-13/.julia
```

The new ODEPE branch-stress models were added in:

```text
src/examples/models/branch_stress_systems.jl
src/examples/load_examples.jl
test/branch_stress_multiplicity.jl
docs/2026-05-24_branch_hunt_results.md
```

Before running Quoll on the cluster, ensure the cluster copy of ODEPE includes
these changes, and ensure the PEB `julia_odepe` environment points at that copy.

## New Branch-Stress Systems

There are two new model families. Each family has a branch-producing aggregate
case and an observed-output control case.

### 1. Latent Subpopulation Branch, Expected M = 6

Name:

```text
latent_subpopulation_branch
```

States:

```text
S, I1, I2, I3, R
```

Parameters:

```text
a1, a2, a3, b1, b2, b3
```

ODEs:

```text
D(S)  = -b1*S*I1 - b2*S*I2 - b3*S*I3
D(I1) =  b1*S*I1 - a1*I1
D(I2) =  b2*S*I2 - a2*I2
D(I3) =  b3*S*I3 - a3*I3
D(R)  =  a1*I1 + a2*I2 + a3*I3
```

Measurements:

```text
y1 = S
y2 = I1 + I2 + I3
y3 = R
```

Time interval:

```text
[0.0, 12.0]
```

Representative true values in ODEPE:

```text
parameters = [a1=0.15, a2=0.35, a3=0.65, b1=0.20, b2=0.45, b3=0.90]
states     = [S=0.82, I1=0.08, I2=0.05, I3=0.03, R=0.02]
```

Structural result from the ODEPE-side multiplicity test:

```text
M = 6
```

Branch orbit:

The six equivalent branches are the six permutations of the three latent
subpopulation labels. A candidate should be considered branch-correct if it
matches any permutation of the triples:

```text
(a1, b1, I1(0)), (a2, b2, I2(0)), (a3, b3, I3(0))
```

with `S(0)` and `R(0)` unchanged.

### 2. Latent Subpopulation Observed Control, Expected M = 1

Name:

```text
latent_subpopulation_observed_control
```

Same states, parameters, ODEs, time interval, and nominal values as
`latent_subpopulation_branch`.

Measurements:

```text
y1 = S
y2 = I1
y3 = I2
y4 = I3
y5 = R
```

Structural result:

```text
M = 1
```

Purpose:

This is a control case. The hidden label symmetry is removed by measuring the
subpopulations separately. It should be substantially easier than the aggregate
case. If this control fails, the problem is probably numerical/plumbing/model
awkwardness rather than finite-branch handling.

### 3. Receptor Subtype Binding Branch, Expected M = 2

Name:

```text
receptor_subtype_binding_branch
```

States:

```text
L, Ca, Cb
```

Parameters:

```text
R1tot, R2tot, kon1, kon2, koff1, koff2
```

ODEs:

```text
D(L)  = -kon1*L*(R1tot - Ca) + koff1*Ca
        -kon2*L*(R2tot - Cb) + koff2*Cb
D(Ca) =  kon1*L*(R1tot - Ca) - koff1*Ca
D(Cb) =  kon2*L*(R2tot - Cb) - koff2*Cb
```

Measurements:

```text
y1 = L
y2 = Ca + Cb
```

Time interval:

```text
[0.0, 8.0]
```

Representative true values in ODEPE:

```text
parameters = [R1tot=1.10, R2tot=0.70, kon1=0.80, kon2=1.30,
              koff1=0.40, koff2=0.60]
states     = [L=2.00, Ca=0.10, Cb=0.20]
```

Structural result:

```text
M = 2
```

Branch orbit:

The two equivalent branches are the two receptor-subtype labelings. A candidate
should be considered branch-correct if it matches either the original values or
the subtype swap:

```text
R1tot <-> R2tot
kon1  <-> kon2
koff1 <-> koff2
Ca(0) <-> Cb(0)
```

with `L(0)` unchanged.

### 4. Receptor Subtype Binding Observed Control, Expected M = 1

Name:

```text
receptor_subtype_binding_observed_control
```

Same states, parameters, ODEs, time interval, and nominal values as
`receptor_subtype_binding_branch`.

Measurements:

```text
y1 = L
y2 = Ca
y3 = Cb
```

Structural result:

```text
M = 1
```

Purpose:

This removes the aggregate measurement and therefore removes the subtype-label
ambiguity.

## PEB Integration Requirements

PEB does not automatically consume ODEPE example constructors. The four systems
above must be represented in PEB's `systems.json` format before PEB can generate
data and scripts.

Use names exactly as above.

Each system entry needs:

```json
{
  "name": "...",
  "ode_system": {},
  "measurements": {},
  "non_identifiable": [],
  "state_variables": [],
  "measurement_variables": [],
  "parameter_variables": [],
  "time_interval": [0.0, 1.0]
}
```

The branch metadata (`expected_M`, branch orbit definition, control pairing)
does not currently have a standard PEB field. Recommended options:

1. Add a sidecar analysis file, e.g.
   `config/quoll_branch_metadata.json`.
2. If PEB tolerates extra fields in `systems.json`, add:

```json
{
  "quoll_expected_multiplicity": 6,
  "quoll_suite": "branch",
  "quoll_control_for": null
}
```

Do this only after checking that `generate_data.py`, `generate_scripts.py`, and
downstream analysis ignore unknown fields. If uncertain, use the sidecar file.

## Recommended Quoll Subexperiments

### A. Quoll Smoke

Goal:

Validate that the new systems are correctly represented in PEB and runnable
through generated scripts.

Suggested benchmark directory:

```text
benchmark_quoll_smoke_2026-05-25
```

Systems:

```text
latent_subpopulation_branch
latent_subpopulation_observed_control
receptor_subtype_binding_branch
receptor_subtype_binding_observed_control
```

Config:

```json
{
  "NUM_TESTS": 2,
  "NUM_PTS": 101,
  "NOISE_LEVEL": {"0": 0, "1em6": 1e-6},
  "NOISE_TYPE": "ADDITIVE",
  "SEARCH_BOUNDS": [1e-5, 10.0],
  "ODEPE_POLISH": "true",
  "POLISH_MAXTIME": 1200.0,
  "POLISH_DIVERGENCE_FACTOR": 10.0,
  "POLISH_STAGNATION_WINDOW": 50,
  "POLISH_ODE_MAXITERS": 20000
}
```

Software:

```text
odepe_v2_polish
odepe_v2_nopolish
```

Optional:

```text
odepe_shade
amigo2
```

Expected cell count:

```text
4 systems * 2 tests * 2 noise levels = 16 cells per software
```

Pass criteria:

- Data generation succeeds.
- Script generation succeeds.
- At least the observed controls finish for ODEPE polish.
- Branch cases produce parseable ODEPE metadata and candidate/result CSVs.
- No obvious crash caused by unsupported measurement expressions or variable
  naming.

Do not interpret smoke hit rates as science.

### B. Quoll Branch Suite

Goal:

Measure whether ODEPE returns calibrated, distinct finite branches under noise.

Suggested benchmark directory:

```text
benchmark_quoll_branch_2026-05-25
```

Core systems:

```text
latent_subpopulation_branch
latent_subpopulation_observed_control
receptor_subtype_binding_branch
receptor_subtype_binding_observed_control
```

Optional branch-relevant legacy systems:

```text
seir
daisy_mamil4
```

Only include legacy systems if their branch/multiplicity story is currently
verified. Do not include them merely because they feel plausible.

Config:

```json
{
  "NUM_TESTS": 10,
  "NUM_PTS": 750,
  "NOISE_LEVEL": {"0": 0, "1em8": 1e-8, "1em6": 1e-6, "1em4": 1e-4, "1em2": 1e-2},
  "NOISE_TYPE": "ADDITIVE",
  "SEARCH_BOUNDS": [1e-5, 10.0],
  "ODEPE_POLISH": "true",
  "POLISH_MAXTIME": 3600.0,
  "POLISH_DIVERGENCE_FACTOR": 10.0,
  "POLISH_STAGNATION_WINDOW": 50,
  "POLISH_ODE_MAXITERS": 20000
}
```

Minimum software:

```text
odepe_v2_polish
odepe_v2_nopolish
odepe_shade
amigo2
```

Optional software:

```text
sciml
```

Expected cell count for four core systems:

```text
4 systems * 10 tests * 5 noise levels = 200 cells per software
```

Expected cell count if adding `seir` and `daisy_mamil4`:

```text
6 systems * 10 tests * 5 noise levels = 300 cells per software
```

Primary analysis questions:

- Does ODEPE polish return at least one accurate candidate for each cell?
- Does ODEPE return the expected number of distinct branches when `M > 1`?
- Does the observed control collapse to one branch and remain easier?
- Does nopolish produce branch structure but worse numeric accuracy?
- Does SHADE help or hurt branch diversity?
- Does AMIGO2 find one good equivalent solution while not representing the full
  branch set?
- If the optional `sciml` add-on is run, does it behave similarly to AMIGO2 as a
  one-solution optimizer-style comparator?

### C. Quoll Low-Data Suite

Goal:

Study sparse-data behavior separately from branch multiplicity.

Suggested benchmark directory:

```text
benchmark_quoll_lowdata_2026-05-25
```

Systems:

Use a representative subset of existing wallaby/numbat systems. Suggested set:

```text
simple
lotka_volterra
seir
fitzhugh_nagumo
crauste
biohydrogenation
daisy_mamil3
daisy_mamil4
aircraft_pitch
cstr
```

This should be finalized against the actual available `systems.json`. Avoid
turning the low-data suite into another full benchmark unless the preliminary
results are very stable.

Design:

PEB config has one `NUM_PTS`, so either create separate benchmark directories
or separate frozen configs:

```text
benchmark_quoll_lowdata_31_2026-05-25
benchmark_quoll_lowdata_61_2026-05-25
benchmark_quoll_lowdata_101_2026-05-25
benchmark_quoll_lowdata_251_2026-05-25
```

Suggested grid:

```text
NUM_PTS: 31, 61, 101, 251
noise:   0, 1e-6, 1e-4, 1e-2
tests:   10
```

Minimum software:

```text
odepe_v2_polish
odepe_v2_nopolish
amigo2
```

Optional:

```text
odepe_shade
sciml
```

Primary analysis questions:

- Where is the practical data threshold for ODEPE polish?
- Does polish rescue sparse-data cases, or does it overfit bad interpolants?
- Which systems have a sharp noise/data cliff?
- Are failures concentrated in derivative estimation, algebraic solve, or
  polishing?

### D. Quoll Main / Paper Suite

Goal:

One clean, stable, reportable benchmark that combines broad noisy recovery and
tagged branch-stress evidence.

Do this only after Quoll Smoke and Quoll Branch Suite are understood.

Suggested systems:

- Start from wallaby's system set.
- Add the two branch systems:
  - `latent_subpopulation_branch`
  - `receptor_subtype_binding_branch`
- Add observed controls only if reporting a branch-specific table/appendix.
  They should not inflate the main headline hit rate.

Suggested software:

```text
odepe_v2_polish
odepe_v2_nopolish
amigo2
```

Optional:

```text
odepe_shade
sciml
```

Use the wallaby noise grid and `NUM_PTS = 750` unless the branch or low-data
experiments justify changing it.

## Metrics to Add or Verify

The current PEB metrics are mostly candidate-level numeric recovery metrics.
Quoll needs explicit branch-aware metrics, at least for the branch suite.

### Existing metric to preserve

The current "50%" hit-rate style metric is still useful:

```text
candidate is successful if parameter/state relative error <= 0.5
```

But for branch systems, this should be computed against the **nearest true
branch**, not just the nominal parameter ordering.

### Branch-aware metrics

For each cell and run:

1. `best_error_any_branch`
   - Minimum error over candidates and over true branch orbit.

2. `hit_any_branch_50`
   - Boolean: some candidate is within 50% of some true branch.

3. `expected_M`
   - 6 for `latent_subpopulation_branch`.
   - 2 for `receptor_subtype_binding_branch`.
   - 1 for both observed controls.

4. `distinct_branch_hits_50`
   - Number of distinct true branches with at least one matching candidate
     within 50%.

5. `branch_coverage_fraction_50`
   - `distinct_branch_hits_50 / expected_M`.

6. `duplicate_branch_fraction`
   - Among accepted candidates, fraction assigned to an already-hit branch.
   - This directly addresses the concern that the method may return multiple
     copies of the same algebraic root/branch.

7. `returned_candidate_count`
   - Existing ODEPE fields may already expose raw and best counts:
     `odepe_raw_count`, `odepe_best_count`.

8. `calibrated_return_success`
   - Boolean: the returned best set contains approximately `expected_M`
     distinct branches when `expected_M > 1`, and approximately one branch for
     controls.

This does not need to be perfect on day one. Start with a post-processing
script that reads the result CSVs and computes branch assignment for the four
new systems.

### Branch assignment details

For `latent_subpopulation_branch`, enumerate the six permutations of labels
`1,2,3`. For each returned candidate, compute relative error against each
permuted truth:

```text
permute (a1, a2, a3)
permute (b1, b2, b3)
permute (I1(0), I2(0), I3(0))
leave S(0), R(0) fixed
```

Assign the candidate to the nearest branch if the error is under threshold.

For `receptor_subtype_binding_branch`, enumerate identity and swap:

```text
R1tot <-> R2tot
kon1  <-> kon2
koff1 <-> koff2
Ca(0) <-> Cb(0)
leave L(0) fixed
```

For controls, `expected_M = 1` and there is only the nominal branch.

## Concrete Implementation Tasks for Cluster Claude

### Task 1: Sync and verify ODEPE

On the cluster, make sure ODEPE contains the new branch-stress code.

Run:

```bash
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'
```

Expected from the local run:

```text
Fast Core Contracts | 309/309 passing
```

Run:

```bash
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/branch_stress_multiplicity.jl")'
```

Expected:

```text
Branch-stress multiplicity regressions | 4/4 passing
```

If this fails because SIAN or StructuralIdentifiability is unavailable, do not
block the whole benchmark. Record it and continue after verifying constructors
load. The multiplicity facts were already confirmed locally.

### Task 2: Add PEB systems

Add the four Quoll branch-stress systems to a frozen Quoll systems file, not
necessarily to the global master file at first.

Recommended file:

```text
config/systems_quoll_branch.json
```

or inside a benchmark snapshot:

```text
benchmark_quoll_smoke_2026-05-25/config/systems.json
```

Use exact names and exact equation strings from this spec.

### Task 3: Create Quoll smoke config

Create:

```text
config/config_quoll_smoke.json
```

or directly freeze:

```text
benchmark_quoll_smoke_2026-05-25/config/config.json
```

Use the smoke settings above.

### Task 4: Generate data and scripts

From PEB repo root:

```bash
python3 src/init_benchmark.py \
  --name quoll_smoke \
  --date 2026-05-25 \
  --phase smoke \
  --software odepe_v2_polish odepe_v2_nopolish odepe_shade amigo2 \
  --config config/config_quoll_smoke.json \
  --systems config/systems_quoll_branch.json \
  --expected-cells 64
```

Then:

```bash
python3 src/generate_data.py \
  benchmark_quoll_smoke_2026-05-25/config/config.json \
  benchmark_quoll_smoke_2026-05-25/config/systems.json \
  -d benchmark_quoll_smoke_2026-05-25
```

Then:

```bash
python3 src/generate_scripts.py benchmark_quoll_smoke_2026-05-25 \
  -s odepe_v2_polish -r odepe_v2_polish_run

python3 src/generate_scripts.py benchmark_quoll_smoke_2026-05-25 \
  -s odepe_v2_nopolish -r odepe_v2_nopolish_run

python3 src/generate_scripts.py benchmark_quoll_smoke_2026-05-25 \
  -s odepe_shade -r odepe_shade_run

python3 src/generate_scripts.py benchmark_quoll_smoke_2026-05-25 \
  -s amigo2 -r amigo2_run
```

### Task 5: Run smoke

Local/sequential option:

```bash
python3 src/estimate.py benchmark_quoll_smoke_2026-05-25 \
  odepe_v2_polish_run odepe_v2_polish all
```

Cluster array option:

The convenience wrapper `hpc/cuny/submit_benchmark.sh` currently accepts only
`odepe`, `sciml`, and `amigo2`, so for `odepe_v2_polish`,
`odepe_v2_nopolish`, and `odepe_shade`, use the explicit CUNY scripts:

```bash
sbatch --array=0-15%16 \
  ParameterEstimationBenchmarking/hpc/cuny/array_job_odepe_v2_polish_cuny.s \
  benchmark_quoll_smoke_2026-05-25 odepe_v2_polish_run

sbatch --array=0-15%16 \
  ParameterEstimationBenchmarking/hpc/cuny/array_job_odepe_v2_nopolish_cuny.s \
  benchmark_quoll_smoke_2026-05-25 odepe_v2_nopolish_run

sbatch --array=0-15%16 \
  ParameterEstimationBenchmarking/hpc/cuny/array_job_odepe_shade_cuny.s \
  benchmark_quoll_smoke_2026-05-25 odepe_shade_run

sbatch --array=0-15%16 \
  ParameterEstimationBenchmarking/hpc/cuny/array_job_amigo2_cuny.s \
  benchmark_quoll_smoke_2026-05-25 amigo2_run
```

If using `hpc/submit.sh`, the shape is:

```bash
./hpc/submit.sh --array=0-15%16 hpc/cuny/array_job_odepe_v2_polish_cuny.s \
  benchmark_quoll_smoke_2026-05-25 odepe_v2_polish_run
```

Adjust paths to match cluster working directory.

### Task 6: Collect and sanity-check smoke

Run:

```bash
python3 src/collect_results.py benchmark_quoll_smoke_2026-05-25
```

Then inspect:

```text
benchmark_quoll_smoke_2026-05-25/result_*.csv
benchmark_quoll_smoke_2026-05-25/filetree/*/*/stdout.txt
benchmark_quoll_smoke_2026-05-25/filetree/*/*/stderr.txt
benchmark_quoll_smoke_2026-05-25/filetree/*/*/failure_reason.txt
```

Known PEB caveat:

`collect_results.py` historically uses `run.split("_")[0]` for the software
field, so ODEPE-family variants may collapse to `software = odepe`. Prefer the
`run` column and ODEPE metadata fields when separating `odepe_v2_polish`,
`odepe_v2_nopolish`, and `odepe_shade`.

### Task 7: Implement branch-aware post-processing

Add a script, probably under:

```text
results/quoll_analysis/
```

Suggested output:

```text
results/quoll_analysis/quoll_branch_metrics.csv
```

Minimum columns:

```text
benchmark_dir
run
software_or_run
id
name
noise
seed_or_instance
expected_M
has_result
odepe_raw_count
odepe_best_count
best_error_any_branch
hit_any_branch_50
distinct_branch_hits_50
branch_coverage_fraction_50
duplicate_branch_fraction
calibrated_return_success
failure_reason
```

This script should be deterministic and should explicitly encode the two branch
orbits described above.

### Task 8: Scale to Quoll Branch Suite

After smoke passes, create:

```text
benchmark_quoll_branch_2026-05-25
```

Use the branch-suite settings above.

Submit arrays based on actual cell count:

```text
array range = 0-(num_cells - 1)
```

For four core systems:

```text
0-199
```

For six systems:

```text
0-299
```

Use throttling conservatively for ODEPE polish:

```text
%25 or %50
```

The v2 polish CUNY script requests 8 CPUs, 16GB, and 36 hours. SHADE requests
1 CPU, 4GB, and 6 hours. If SHADE has unexplained timeouts, increase the SHADE
script time before interpreting failures.

### Task 9: Decide whether to run optional SciML

For the focused branch suite, Wallaby already gives us one external
optimizer-style comparator: AMIGO2. Keep AMIGO2 in the default Quoll plan.

Recommended priority:

1. `odepe_v2_polish`
2. `odepe_v2_nopolish`
3. `odepe_shade`
4. `amigo2`

Only add `sciml` if there is a specific reason to run a generic
SciML/Optimization.jl comparator in addition to AMIGO2. If it is run, label it
as optional and do not mix it into Wallaby-faithful headline comparisons.

AMIGO2, and optional SciML if present, should be judged mainly on whether they
find **a** good equivalent branch, not whether they return all branches. Their
lack of branch calibration is part of the comparison, but do not make the table
look like they "failed" at a task they were not designed to expose.

## Reporting Plan

### Tables

1. Branch-suite overview:

```text
system | expected_M | observation type | ODEPE polish hit_any_branch_50 |
distinct_branch_hits_50 | branch_coverage_fraction_50
```

2. Control comparison:

```text
branch system | control system | M_branch | M_control | branch hit rate |
control hit rate | branch coverage
```

3. Method comparison:

```text
system | noise | odepe_v2_polish | odepe_v2_nopolish | odepe_shade |
amigo2
```

But keep branch coverage fields ODEPE-centered; optimizers may not return
multiple branches.

### Figures

Useful plots:

- Branch coverage vs noise.
- Hit-any-branch vs noise.
- Candidate count vs expected multiplicity.
- Duplicate-branch fraction vs noise.
- Branch vs observed-control recovery error.

### Paper language

Frame these systems as:

```text
symmetry-induced finite-identifiability stress tests
```

or:

```text
aggregate-observation branch stress tests
```

Avoid overselling them as a broad biological benchmark. They are deliberately
constructed but physically interpretable.

The honest claim is:

> These examples isolate a failure mode where generic optimizers may find one
> good equivalent solution while failing to expose the finite set of structurally
> equivalent solutions. ODEPE's algebraic workflow can estimate the finite
> multiplicity and calibrate its returned candidate set accordingly.

## Known Risks

1. The branch-stress systems may be too easy numerically.
   - That is acceptable for controls and smoke.
   - For the branch suite, the point is multiplicity/coverage, not raw hardness.

2. The aggregate examples are constructed.
   - Mitigation: describe them as branch-stress tests, not as the main
     application benchmark.
   - Use physical language: latent subpopulations, receptor subtypes, aggregate
     observations.

3. PEB may not preserve extra metadata fields.
   - Use sidecar metadata if uncertain.

4. Existing result collection may collapse ODEPE variants under `software`.
   - Use `run` and ODEPE metadata fields.

5. AMIGO2, and optional SciML if run, can be misleading on branch coverage.
   - Compare them on best-equivalent-branch accuracy.
   - Separately state that they do not aim to return calibrated branch sets.

6. Large runs can hide failures.
   - Always do Quoll Smoke first.
   - Collect `failure_reason.txt` and inspect a few stdout/stderr files before
     scaling.

## Go / No-Go Criteria

Proceed from smoke to branch suite if:

- All four systems generate data.
- ODEPE scripts render.
- Observed controls run successfully for `odepe_v2_polish`.
- At least one aggregate branch case produces nonempty results.
- Result collection does not completely break on new names.

Proceed from branch suite to main/paper suite if:

- Branch-aware post-processing is implemented.
- The `M = 1` controls behave like controls.
- At least one of the `M > 1` branch systems shows meaningful branch coverage
  above noise-free or low-noise levels.
- Failure modes are understood enough to explain, not merely filtered away.

Do not proceed to a huge all-method run if smoke already shows that branch
assignment or result parsing is broken.

## Immediate Next Actions

1. Sync ODEPE branch-stress changes to the cluster.
2. Add the four systems to a Quoll PEB systems file.
3. Create and freeze `benchmark_quoll_smoke_2026-05-25`.
4. Run ODEPE polish/nopolish smoke.
5. Add SHADE smoke if polish/nopolish are parseable.
6. Implement branch-aware metrics script.
7. Run `benchmark_quoll_branch_2026-05-25`.
8. Decide whether the Quoll Main / Paper Suite should include branch controls
   in the main table, appendix, or only the focused branch section.

## Pre-Flight Design Review Addendum

This section was added after reviewing the old IEEE/GPR paper tree, the
publication-planning notes, Wallaby/Numbat analysis, the derivative-estimation
study notes, and PEB benchmark recommendations.

The key change is procedural: **do not launch a large Quoll run until the
ranking, multiplicity, metadata, and analysis contracts are explicit.** The
cluster cost is high enough that hidden defaults are not acceptable.

### Wallaby Lessons That Must Carry Forward

Wallaby is the right reference benchmark for Quoll, not the old IEEE paper
dataset.

Wallaby facts:

- 23 systems.
- 10 instances per system.
- 5 noise levels: `0`, `1em8`, `1em6`, `1em4`, `1em2`.
- 4 estimator runs:
  - `odepe_v2_polish`
  - `odepe_v2_nopolish`
  - `odepe_shade`
  - `amigo2`
- 4600 expected cells.
- 4597 result files landed according to the manifest closeout.

The old IEEE paper is useful for background/method prose and for historical
motivation, but its benchmark results are stale:

- 11 systems, not 23.
- 550 datasets, not Wallaby-scale.
- older ODEPE and benchmark harness.
- older SciML comparison included there, but not in Wallaby.
- paper language overclaims "GP switch solves noise" relative to what later
  benchmarks revealed.

Use the old paper for:

- differential-algebraic background;
- GP derivative motivation;
- method exposition;
- related-work seed text;
- examples of figures/tables.

Do not use the old paper for:

- final performance claims;
- final comparator set;
- final benchmark protocol;
- branch-aware claims.

### Hard Blockers Before a Large Cluster Run

These are not optional. Quoll should not scale past smoke/pilot until these are
done.

1. **Explicit ranking defaults in generated scripts.**

   The current PEB ODEPE v2 templates do not set `rank_strategy`,
   `branch_top_k`, `branch_diversity_selection`, or
   `branch_diversity_eps` explicitly.

   Current ODEPE source shows:

   ```text
   rank_strategy = :sat_neg1_err
   branch_top_k = 20
   branch_diversity_selection = true
   branch_diversity_eps = 0.01
   ```

   But Wallaby analysis documents a serious `:sat_neg1_err` / S2 ranking
   issue: truth-near rows with synthesized or aggregate provenance
   (`polish_source_hc_idx = -1`) were demoted behind worse HC-tagged rows.

   For Quoll, do not let this depend on package defaults. Put the chosen values
   in the PEB templates or in a Quoll-specific template. Also write them to the
   manifest and per-cell metadata.

   Minimum ranking variants worth testing in a small ablation:

   ```text
   rank_strategy = :err_only
   rank_strategy = :sat_err
   rank_strategy = :sat_neg1_err
   ```

   Recommended default for Quoll branch/paper runs:

   ```text
   rank_strategy = :err_only
   ```

   If `:sat_neg1_err` is retained for continuity with Wallaby, it should be
   treated as a deliberate ablation, not as an implicit default.

2. **Explicit multiplicity source.**

   Wallaby prose and flat metrics use algebraic multiplicity, but the frozen
   Wallaby `config/systems.json` snapshot available in readonly does not expose
   `algebraic_multiplicity` fields. The M values came from later analysis /
   ODEPE repro artifacts.

   For Quoll, store multiplicity in one canonical machine-readable place:

   ```text
   config/quoll_branch_metadata.json
   ```

   or, if the PEB pipeline is verified to ignore unknown fields safely:

   ```json
   {
     "algebraic_multiplicity": 6,
     "physical_multiplicity_positive_bounds": 6,
     "quoll_suite": "branch_stress",
     "quoll_branch_map": "latent_subpopulation_permutation"
   }
   ```

   The analysis script must not silently default missing M to 1 for Quoll
   branch systems.

3. **Branch-aware postprocessor before paper-scale run.**

   The current M-bounded metric is not enough. It answers:

   ```text
   Is there a good candidate in the first M rows?
   ```

   It does not answer:

   ```text
   Are those M rows representatives of M distinct branches?
   ```

   Before the Branch Suite is scaled, implement the postprocessor that assigns
   returned rows to known branch orbits for:

   - `latent_subpopulation_branch`
   - `receptor_subtype_binding_branch`
   - `latent_subpopulation_observed_control`
   - `receptor_subtype_binding_observed_control`

   Then run it on smoke output. If it cannot classify rows reliably, do not
   launch the full branch run.

4. **Manifest and per-cell metadata capture.**

   Every Quoll benchmark directory should save:

   ```text
   ODEPE git SHA
   PEB git SHA
   dirty status / diff summary
   Julia version
   Julia project and manifest hashes
   Python environment hash
   AMIGO2 path/version if used
   generated template hash per estimator
   rank_strategy
   branch_top_k
   branch_diversity_selection
   branch_diversity_eps
   algebraic_multiplicity source
   interpolator list and order
   auto_filter_interpolators
   polish_solutions
   polish_solver_solutions
   polish method and limits
   shooting_points
   shooting_warp
   use_multipoint
   multipoint_n_points
   multipoint_max_pairs
   use_parameter_homotopy
   opt bounds
   SLURM script path/hash
   array throttle
   CPU/memory/time request
   ```

   The old benchmark recommendation file is right: without this, performance
   changes cannot be attributed to algorithm changes rather than environment or
   template drift.

5. **Smoke must include AMIGO2 if AMIGO2 is in the paper table.**

   The previous spec allowed ODEPE-only smoke. That is acceptable for
   constructor plumbing, but not for final preflight. Since Wallaby included
   AMIGO2 and Quoll likely will too, at least one AMIGO2 smoke should be run
   before the full branch suite. This catches MATLAB/AMIGO2 path problems
   cheaply.

### Strongly Recommended Code/PEB Features

These are not all blockers, but they are high leverage.

1. **Quoll-specific PEB system file generator.**

   Create a small script that converts the ODEPE branch-stress constructors or
   a checked JSON source into PEB `systems.json`. Avoid hand-editing the four
   systems in two places.

   Required output files:

   ```text
   config/systems_quoll_branch.json
   config/quoll_branch_metadata.json
   ```

2. **Quoll branch metrics script.**

   Suggested location:

   ```text
   results/quoll_analysis/build_quoll_branch_metrics.py
   ```

   It should read a benchmark directory and produce:

   ```text
   results/quoll_analysis/quoll_branch_metrics.csv
   ```

   It should compute, at minimum:

   ```text
   expected_algebraic_M
   expected_physical_M
   returned_rows
   distinct_returned_branches
   branch_coverage_fraction_50
   duplicate_topM
   canonical_truth_hit_50
   any_branch_hit_50
   all_physical_branches_hit_50
   oob_branch_count
   best_rank_per_branch
   ```

3. **Score-component logging for ODEPE selections.**

   Wallaby's ranking regression showed that candidate ranking is a major source
   of benchmark outcome changes. For Quoll, each returned row should expose
   enough metadata to explain why it was selected:

   ```text
   err
   saturation_count
   psh / polish_source_hc_idx
   branch cluster id
   provenance tag
   interpolator source
   rescue path
   post-polish residual
   bounds violation / OOB status
   ```

   If this is too much for `result.csv`, write it to `odepe_metadata.json` or a
   sidecar CSV.

4. **Explicit ranking ablation, not just final ranking.**

   Since re-ranking existing candidate pools is often possible offline, add a
   small analysis that replays ranking strategies on smoke/pilot output:

   ```text
   :err_only
   :sat_err
   :sat_neg1_err
   branch-diverse M selection on/off
   ```

   This is cheaper than rerunning solvers and directly answers whether a
   ranking change is improving generic behavior or only helping a target cell.

5. **PEB collect-results variant handling.**

   Older PEB collection logic may collapse ODEPE variants into `software =
   odepe` by splitting run names at `_`. Quoll analysis must key by the full
   `run` column, not only `software`.

   Before a full run, confirm that result collection distinguishes:

   ```text
   odepe_v2_polish_run
   odepe_v2_nopolish_run
   odepe_shade_run
   amigo2_run
   ```

### Subexperiments: Keep, Add, Defer

#### Keep as P0

1. **Quoll Smoke.**

   Must run before anything large.

2. **Quoll Branch Suite.**

   This is the main new experiment for the branch-aware claim.

3. **Wallaby offline finalization.**

   No cluster cost. Rebuild final tables from existing Wallaby data with clear
   metric families:

   ```text
   top1
   M-bounded
   best-of-K oracle
   branch-aware occupancy where applicable
   ```

4. **Baseline fairness memo.**

   Needed for paper defense. It should document bounds, budgets, stopping
   criteria, restarts, software versions, and tuning effort for ODEPE, SHADE,
   and AMIGO2. If SciML is omitted from Quoll, say why.

5. **AAA noisy-derivative diagnostic.**

   Do not run AAA as a normal competitor in the main chart if it mostly fails.
   Use it as a focused diagnostic showing why the old noiseless-style algebraic
   workflow is brittle under noise.

#### Add as P0/P1 Before Full Paper Claims

1. **Branch classifier sensitivity sweep.**

   For branch metrics, report whether conclusions are stable at thresholds like:

   ```text
   10%, 50% truth hit
   1%, 5%, 10% branch-distinct threshold
   ```

   Wallaby multiplicity notes already warn that loose distinct-row tolerances
   produce spurious branches. Quoll should not repeat that ambiguity.

2. **Physical-vs-algebraic M table.**

   Every branch table should separate:

   ```text
   algebraic M
   physical/bound-admissible M
   returned distinct branches
   ```

   This avoids overclaiming on `slow_fast` and `biohydrogenation`, whose second
   algebraic branches are usually out-of-bounds under Wallaby positivity.

3. **Small rank-strategy ablation on existing or smoke candidate pools.**

   This is especially important because current source defaults and historical
   root-cause notes disagree about the best ranking strategy.

4. **Branch-aware ODEPE output contract test.**

   Add a local test or analysis fixture that checks:

   - M=6 latent system returns no more than 6 rows when auto-M is active.
   - M=2 receptor system returns no more than 2 rows when auto-M is active.
   - controls return 1 row under auto-M.
   - top-M rows are not duplicates under a simple branch classifier when the
     data are noiseless or low-noise.

   This can live outside the default fast test if it is expensive.

#### Defer Unless Cheap

1. **Large low-data suite.**

   Low-data behavior is a reviewer-risk probe, not the central Quoll claim. Do
   not run a 10-system x 5-data-density x 4-method matrix until branch metrics
   are stable.

   Cheaper version:

   ```text
   4 systems x 3 NUM_PTS values x 3 noise levels x 3 seeds x 2 methods
   ```

   Systems:

   ```text
   lotka_volterra
   daisy_mamil4 or latent_subpopulation_branch
   biohydrogenation
   aircraft_pitch or cstr
   ```

2. **SciML.**

   SciML appeared in older paper/Quokka-era comparisons, but not Wallaby. Add it
   only if the paper needs a modern Julia optimizer baseline beyond AMIGO2 and
   SHADE. If added, run it as a clearly labeled add-on, not part of the
   Wallaby-faithful core.

3. **CSTR rejection-sampling redesign.**

   The prior benchmark recommendations make a good case that CSTR instances can
   be weak experiments. But changing CSTR data generation creates a new
   benchmark family. Do this only for a later main-suite refresh, not for the
   branch-stress run.

4. **Column scaling / conditioning experiment.**

   Important for future robustness, especially biohydrogenation/daisy_mamil4,
   but it is not needed to validate branch metrics. Do not let it block Quoll
   unless smoke shows the new branch systems are failing for conditioning
   reasons.

### Cost-Aware Run Order

Recommended order:

1. **Local metadata/code smoke**

   No cluster. Confirm:

   - ODEPE branch constructors load.
   - PEB systems JSON validates.
   - branch metadata JSON validates.
   - generated scripts include explicit ranking/multiplicity knobs.

2. **Quoll Smoke, ODEPE polish/nopolish only**

   16 cells per software with the smoke design.

3. **Quoll Smoke, SHADE + AMIGO2**

   Same 16 cells per software. This catches MATLAB/SHADE-specific issues before
   full branch run.

4. **Branch metrics dry run**

   Run `build_quoll_branch_metrics.py` on smoke output. Do not proceed unless
   branch labels and controls make sense.

5. **Quoll Branch Pilot**

   Suggested:

   ```text
   4 systems x 3 seeds x 3 noise levels x 4 estimators = 144 cells
   ```

   Noise:

   ```text
   0, 1e-8, 1e-4
   ```

6. **Quoll Branch Full**

   Core:

   ```text
   4 systems x 10 seeds x 5 noise levels x 4 estimators = 800 cells
   ```

   With `daisy_mamil4` and `seir` added:

   ```text
   6 systems x 10 seeds x 5 noise levels x 4 estimators = 1200 cells
   ```

   The six-system version is recommended if the pilot is healthy, because it
   connects constructed branch-stress systems to Wallaby's real M=2 cases.

7. **Only then decide on Quoll Main**

   A Wallaby-sized Quoll Main with 25 systems and 4 estimators would be roughly:

   ```text
   25 systems x 10 seeds x 5 noise levels x 4 estimators = 5000 cells
   ```

   With controls included:

   ```text
   27 systems x 10 seeds x 5 noise levels x 4 estimators = 5400 cells
   ```

   Do not run this until the smaller branch suite has answered whether the new
   branch metrics are publication-worthy.

### Paper Evidence Checklist

Before writing final performance claims, make sure the following artifacts
exist:

- Wallaby final table regenerated from existing data.
- Quoll branch metrics CSV.
- Quoll branch pilot/full manifest.
- Branch metadata JSON with explicit M and branch maps.
- Baseline fairness memo.
- AAA noisy-derivative diagnostic figure/table.
- Identifiable-variable metric audit:
  - variables excluded;
  - source of exclusion;
  - same exclusions applied to every method;
  - naive all-variable supplemental metric.
- Failure taxonomy table for:
  - `biohydrogenation`;
  - `daisy_mamil4`;
  - `seir`;
  - any Quoll branch-stress failures;
  - CSTR if included in broad tables.
- Related-work map covering:
  - structural identifiability;
  - algebraic parameter estimation;
  - GP gradient matching/collocation;
  - direct optimization/multistart;
  - practical identifiability/profile likelihood;
  - derivative-estimation literature.

### Bottom Line

The biggest risk is not that Quoll lacks enough systems. The biggest risk is
spending a full cluster run and still not being able to answer:

```text
Did ODEPE return distinct algebraic branches, or did it return duplicate
variants of one branch?
```

So the priority is:

1. Freeze run knobs.
2. Save multiplicity/branch metadata.
3. Implement branch-aware metrics.
4. Smoke and pilot.
5. Only then scale.
