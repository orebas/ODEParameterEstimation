# Public benchmark and PEtab triage

Refreshed source assessment, 2026-09-10. The subsequent
[PEtab pilot implementation and results](2026-09-10_petab_pilot.md) supersede
the importer status and proposed work below. The inventory remains the source
assessment for the full collection.

All 35 canonical problems have now
been inventoried from their YAML, SBML, condition, parameter, observable, and
measurement files. This expands the earlier four-model inspection. No public
benchmark estimation runs were performed during this assessment; it changed
neither estimator code nor dependency environments. RS/RUR restoration remains
deferred.

The most useful initial investigations are **Perelson**, **Bertozzi as two
independent fits**, and **Okuonghae**. **Crauste** is a useful sparse-data
challenge. A faithful adapter and objective are prerequisites for each. The
largest broadly useful estimator addition would be joint fitting of multiple
experiments with shared parameters.

## Importer state before the pilot

The PEtab work was an unfinished experiment, not a working public benchmark
importer. Much of [`src/examples/petab/`](../src/examples/petab/README.md)
exports ODEPE's own example models through TOML to PEtab. Those generated
datasets are distinct from the published experiments in the public collection.

The extension's original [entry point](../ext/ODEParameterEstimationPEtabExt.jl)
included missing paths and exported names that its nested loader/converter did
not define. The actual
[converter](../ext/ODEParameterEstimationPEtabExt/src/petab/convert_petab.jl)
also merges measurement rows without selecting their simulation condition,
averages replicates, inserts NaNs for missing time/observable pairs, maps
parameters positionally, defaults missing initial conditions to zero, and
calls an obsolete problem constructor. It does not preserve a general PEtab
estimation problem. Repairing include paths alone would not repair these
semantics.

The PEtab section of the May comparison document describes entry points and
a source-plan document that are absent from this checkout. Its claims of a
working narrow importer are not current evidence.

## Refresh and reproducibility

Inspected the Benchmarking Initiative's
[Benchmark-Models-PEtab collection](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562),
revision `ddaa86d13f708926c57ec8918ce75a6b50e2e562`, from a fresh full
checkout. This is the same revision as the earlier quick screen. Its latest
commit corrects 32 Alkan measurements by a factor of 1000; benchmark comparisons
should record the exact data revision.

The [machine-readable inventory](2026-09-10_petab_inventory.csv) is generated
by [repro/petab_inventory.py](../repro/petab_inventory.py):

```sh
python3 repro/petab_inventory.py /path/to/Benchmark-Models-PEtab /tmp/petab_inventory.csv
```

The script needs PyYAML and reads an existing checkout. It uses the collection's
canonical YAML selection (`<problem>.yaml`, otherwise `problem.yaml`), so test
datasets, reformulations, PEtab Select subproblems, and optional variants are
excluded. It does not fit models or classify them as supported. All 35 rows
were cross-checked against the collection's overview for condition, estimated
parameter, event, measurement, measured observable, and species counts.

For sampling statistics, a signal is identified by pre-equilibration condition,
simulation condition, observable, and observable-parameter overrides. Distinct
times exclude infinity. Replicate counts count additional rows with the same
signal and time; noise overrides remain individual rows in the original data.
Unequal grids compare the observed signals within each condition pair. These
counts do not assert that every declared observable was measured everywhere.

## Requirements across the collection

These counts overlap and must not be added as independent exclusions.

| Requirement or property | Problems out of 35 | Implication |
|---|---:|---|
| Multiple simulation condition pairs | 23 | Usually needs shared and condition-specific parameter mappings and a joint objective. Bertozzi is a separable exception. |
| Different finite time grids within a condition | 10 | Each signal needs its own sampling times; filling gaps with NaNs is insufficient. |
| Replicate measurement rows | 9 | Preserve row-level likelihood contributions and noise information. |
| At least one signal with only one or two distinct finite times | 13 | More rows do not necessarily provide enough information to estimate derivatives. |
| Log or log10 observation transformation | 8 | Score in the specified space while preserving the raw observation model. |
| Observable-parameter overrides | 15 | Preserve scaling, offsets, and batch-specific mappings. |
| Noise-parameter overrides | 30 | These include both known numbers and estimated parameter references. |
| Pre-equilibration | 5 | Map the selected steady state into the subsequent experiment's initial state. |
| Infinite-time measurements | 2 | Blasi and Froehlich contain only steady-state measurements. |
| SBML events | 2 | Liu and Smith; event semantics differ from ordinary ODEs. |
| Piecewise expressions in model math | 11 | A review flag: some disappear after fixing the experimental inputs. |
| Objective priors | 5 | Include their contribution in the benchmark objective. |

All observable tables use Gaussian noise (with linear, log, or log10
transformations). Laplace entries in this collection are **objective priors**,
not Laplace measurement noise. Several problems estimate observation-dependent
noise, so replacing the likelihood with weighted SSE alone is insufficient:
the noise normalization terms matter too.

At the level of the continuous equations, 18 models have rational expressions
without the flagged events, piecewise terms, unknown Hill powers, or unknown
exponentials. Two more admit rational equations for the canonical experiments:

- **Alkan:** the piecewise condition is `SN38_level > 0`, and every experiment
  supplies a fixed dose. There is no time-dependent switch to infer.
- **Fujita:** the canonical YAML selects only step-input data. Its six measured
  conditions set `EGF_rate = 0`, `EGF_end = 3600`, and have all observations in
  `[0, 3600]`. The input is constant on this interval. The separate pulse/ramp
  test variants should not be conflated with the canonical fitting problem.

Thus **20/35 have a plausible rational-dynamics representation after the
relevant substitutions**. This is an equation-level assessment, not 20
supported or tractable estimation problems: it includes large systems,
steady-state-only data, parameter-dependent initial assignments, and sparse
experiments. The current PEtab extension still provides no validated public
benchmark path.

## Model-by-model assessment

Names identify directories in the pinned collection above. `Species` is the
SBML count, not a count after symbolic reduction. Estimated parameters include
noise, observation, and initial-state parameters. Times are the minimum and
maximum number of distinct finite times per observed signal. `Steady` means
there are no finite-time observations. All rows require a faithful adapter and
benchmark objective; the final column lists additional issues or opportunities.

| Problem | Species | Conditions | Estimated | Times/signal | Additional assessment |
|---|---:|---:|---:|---|---|
| Alkan_SciSignal2018 | 36 | 73 | 56 | 1–13 | Rational after fixed-dose substitution; many sparse conditions, replicates, output scales. |
| Armistead_CellDeathDis2024 | 4 | 2 | 14 | 1–2 | Rational dynamics, but only 14 distinct signal/time pairs among 58 rows; relative noise and fixed ICs. Poor first derivative-based case. |
| Bachmann_MSB2011 | 25 | 36 | 113 | 1–29 | Rational; joint experiments, sparse signals, many output scales, mixed observation transforms, priors. |
| Beer_MolBioSystems2014 | 4 | 19 | 72 | 714 | Dense data, but condition-specific **estimated switching times** and shared kinetic parameters. |
| Bertozzi_PNAS2020 | 3 | 2 | 8 | 11 | Rational SIR; two disjoint estimated parameter sets permit independent fits. |
| Blasi_CellSystems2016 | 16 | 1 | 9 | Steady | Rational equations; all 252 observations at infinity, with replicates and log noise. Needs an equilibrium estimation route. |
| Boehm_JProteomeRes2014 | 8 | 1 | 9 | 16 | Unknown-rate exponential input; otherwise rational, including observation ratios. |
| Borghans_BiophysChem1997 | 3 | 1 | 23 | 111 | Estimated continuous Hill exponent, estimated ICs, output scale/offset, log10 noise. |
| Brannmark_JBC2010 | 9 | 8 | 22 | 1–12 | Pre-equilibration, timed inputs, joint experiments, sparse signals. |
| Bruno_JExpBot2016 | 7 | 6 | 13 | 7 | Rational; promising joint-experiment case with six kinetic rates, six IC parameters, and a shared multiplier. Measurements start after time zero. |
| Chen_MSB2009 | 500 | 4 | 155 | 10 | Timed input with piecewise/sinusoidal components; very large symbolic problem. |
| Crauste_CellSystems2017 | 5 | 1 | 12 | 2–7 | Rational; four unequal grids, known per-datum noise, fixed IC epoch before measurements. |
| Elowitz_Nature2000 | 8 | 1 | 21 | 58 | Estimated continuous Hill exponent; estimated ICs, fluorescence scale/offset, log10 noise. `ln(2)` is just a constant. |
| Fiedler_BMCSystBiol2016 | 6 | 3 | 22 | 5–7 | Two unknown exponential time constants, parameter-derived ICs containing square roots, batch scales. |
| Froehlich_CellSystems2018 | 1396 | 9169 | 4231 | Steady | Rational but entirely steady-state data; size is far beyond a sensible first algebraic campaign. |
| Fujita_SciSignal2010 | 9 | 6 | 19 | 8 | Rational under canonical constant-input conditions; joint fitting and output scales. |
| Giordano_Nature2020 | 13 | 1 | 50 | 43–46 | Many piecewise rate changes; must fit smooth segments with shared states and appropriate matching. |
| Isensee_JCB2018 | 25 | 123 | 46 | 1–7 | Pre-equilibration, timed inputs, many endpoint measurements, replicates, priors. |
| Lang_PLOSComputBiol2024 | 124 | 1 | 294 | 600 | Rational and dense, but large; observation-dependent noise and priors. |
| Laske_PLOSComputBiol2019 | 41 | 3 | 13 | 1–10 | Rational; mixed time-course/endpoint information, derived ICs, output mappings, mixed noise transforms. |
| Liu_IFACPapersOnLine2025 | 0* | 2 | 9 | 5 | Seven rate-rule states; state-triggered reset, exponential IC formula, replicates, observation-dependent noise. |
| Lucarelli_CellSystems2018 | 33 | 16 | 84 | 1–7 | Rational; joint experiments, many sparse signals and replicates, mixed transforms. |
| Okuonghae_ChaosSolitonsFractals2020 | 9* | 1 | 16 | 46 | Rational; two observables, 11 kinetic parameters, three estimated ICs, two noise parameters. Useful larger initial candidate. |
| Oliveira_NatCommun2021 | 9* | 1 | 12 | 60 | Estimated switching times; cumulative-case rate rule and parameter-derived ICs. |
| Perelson_Science1996 | 4 | 1 | 3 | 16 | Rational; two kinetic unknowns, fixed ICs, one log10-noise parameter. Best small first case. |
| Rahman_MBS2016 | 7 | 1 | 9 | 23 | Exponential of states and an estimated parameter; requires a model-preserving reformulation. |
| Raia_CancerResearch2011 | 14 | 4 | 39 | 4–22 | Rational; joint fitting, unequal grids, observation-dependent noise and output scales. |
| Raimundez_PCB2020 | 22 | 170 | 136 | 1–9 | Pre-equilibration, piecewise input, parameter exponentials, many sparse signals and priors. |
| SalazarCavazos_MBoC2020 | 75 | 4 | 6 | 1–3 | Rational but 18 measurements across a large system; small parameter count does not make derivative elimination easy. |
| Schwen_PONE2014 | 11 | 19 | 30 | 1–16 | Rational; joint experiments, sparse signals, replicates, log10 noise and priors. |
| Smith_BMCSystBiol2013 | 133 | 35 | 25 | 1–10 | Three events and state-dependent piecewise rule; large and mostly sparse. |
| Sneyd_PNAS2002 | 6 | 9 | 15 | 15 | Rational; promising joint-experiment case. Fourth-power observable is polynomial, although it raises elimination degree. |
| Weber_BMC2015 | 7 | 2 | 36 | 1–9 | Pre-equilibration, timed inputs, sparse unequal grids and replicates. |
| Zhao_QuantBiol2020 | 5* | 7 | 28 | 7–15 | Rational after fixed condition flags; joint experiment mappings and a shared parameter. |
| Zheng_PNAS2012 | 15 | 1 | 46 | 4 | Rational; pre-equilibration and only four observation times. |

`*` Liu's seven states are SBML parameters with rate rules, despite zero
species. Oliveira has an additional cumulative-case rate-rule variable.
Okuonghae's `total_pop` and Zhao's `Cumulative_Infected` are assignment-defined
species. Species counts alone are therefore an unreliable measure of ODE size.

The earlier seven-model single-condition screen now resolves into three
rational cases (Perelson, Okuonghae, Crauste), two unknown-exponential cases
(Boehm, Rahman), and two estimated-Hill-exponent cases (Borghans, Elowitz).
It should not be reported as seven supported cases.

## Where the contracts differ

ODEPE's [`ParameterEstimationProblem`](../src/types/core_types.jl) holds one
trajectory and a shared time vector. Its
[interpolation interface](../src/core/parameter_estimation.jl) uses that vector
for every observable. Ordinary nonuniform sampling times are not the same
issue as different time grids per observable, missing measurements, or
replicates. The current converter does not handle these distinctions safely.

The [residual polish](../src/core/polish_residual.jl) optimizes raw observation
residuals and state initial conditions as well as model parameters. Supplying
`pep.ic` does not encode the full PEtab contract for fixed or parameter-derived
initial states. Internal structural parameter fixing is also not an importer
for PEtab's `estimate=0` declarations. Constants can be substituted when
building a model, but estimated parameters, constraints, and returned values
need an explicit mapping.

PEtab specifies observable transformations, noise formulas, estimated noise
parameters, and priors as part of its objective. A log10 observation
transformation applies when scoring; the stored measurements remain in linear
space. Thus a logarithmic noise model need not prevent ODEPE from interpolating
the raw observable, but ODEPE's raw least-squares score is not the published
likelihood. See the
[PEtab v1 specification](https://petab.readthedocs.io/en/latest/v1/documentation_data_format.html).

ODEPE's [transcendental input handling](../src/core/transcendental_utils.jl)
covers particular known functions of time. It does not generally support
exponentials of unknown parameters or states. Reformulation may be possible
for individual models, but any auxiliary initial conditions and constraints
must preserve the original model.

## Features worth adding, in order

### 1. Faithful PEtab mapping and scoring

This is the prerequisite with the clearest near-term value. Rebuild the thin
integration around maintained PEtab.jl import and objective interfaces. Map
parameters by ID, preserve fixed constants, distinguish estimated ICs from
fixed/derived ICs, respect the initial time, and translate bounds and parameter
scales. Preserve observation/noise parameters separately from kinetic ones.
The existing extension scripts are not an adequate starting runtime contract.

Use PEtab.jl as the reference simulator and likelihood evaluator. It already
imports SBML and constructs observation, noise, and initial-state functions;
its objective can be used with an external optimizer. This avoids making a
second general SBML/likelihood implementation part of ODEPE. See the maintained
[import tutorial](https://sebapersson.github.io/PEtab.jl/stable/tutorials/define_problem/standard_format)
and [optimizer interface](https://sebapersson.github.io/PEtab.jl/stable/tutorials/parameter_estimation/wrap).

Candidate generation and final fitting need explicit contracts. A first
prototype could let ODEPE generate candidates with relaxed IC constraints,
then enforce the published ICs when evaluating/refining them through PEtab.
That is a legitimate candidate-generation strategy, but the relaxed algebraic
problem must be disclosed. A fully native constrained estimator would need
deeper work in candidate construction, backsolving, and polishing. `pep.ic`
currently supplies values rather than an estimate/fix mask.

Initial targets:

- [Perelson](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562/Benchmark-Models/Perelson_Science1996):
  `c` and `delta`, fixed ICs/constants, one estimated noise parameter, 16 times.
  The log10 likelihood changes the scoring contract, not the rational ODE.
- [Bertozzi](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562/Benchmark-Models/Bertozzi_PNAS2020):
  California and New York each have their own reproduction-number parameter,
  removal rate, initial infected population, and noise scale. Their objectives
  separate. Fit each 11-point series independently and combine the results;
  preserve `S(0) = N - I(0)` and fixed `R(0) = 0`.
- [Okuonghae](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562/Benchmark-Models/Okuonghae_ChaosSolitonsFractals2020):
  two observables on the same 46-point grid and rational dynamics. This is a
  larger feasibility test, with 11 kinetic unknowns, three estimated ICs, and
  two noise parameters. Preserve the remaining fixed initial states and the
  assignment-defined population denominator. Identifiability is untested.

These are candidate investigations, not guaranteed passing benchmarks.

### 2. Multiple experiments with shared parameters

This addresses a requirement present in 23 problems, although it does not
independently unlock all 23. Each experiment needs its own states, IC mapping,
inputs, observations, and interpolants; shared parameters must remain the same
symbol across experiments. Algebraically, one prototype could stack model
copies with shared parameter symbols. A practical implementation should reuse
templates and exploit independent blocks to avoid excessive growth.

ODEPE's existing multipoint method uses multiple times from one trajectory;
it is not this feature. Independent fitting followed by averaging parameters
also does not reproduce a joint benchmark objective.

**Bruno** and **Sneyd** are good feature probes: rational models, six and nine
conditions, with seven and fifteen distinct times per signal respectively.
Sneyd's fourth-power observable is already polynomial; it poses a degree and
conditioning issue rather than a new expression class. **Fujita** and **Zhao**
are additional rational candidates once fixed input/condition flags are applied.
Multiple experiments may improve identifiability, but that requires analysis
of the actual shared parameter mappings.

### 3. Per-signal sampling grids, replicates, and sparse-data behavior

Generalize the data representation and interpolation interface to retain each
signal's own times and measurement rows. Preserve weights/noise information
for the scoring stage, and allow interpolation to account for replicate
precision where appropriate. Ten problems have unequal grids; nine contain
replicates. Ordinary nonuniform sampling is already supported and is a
different issue.

**Crauste** is the small, informative stress case: its four observables have
2, 7, 7, and 5 times, for 21 measurements total. Measurements begin at time 4,
while the fixed ICs apply at zero. Its noise overrides specify a different
known standard deviation for every row.

Thirteen problems contain at least one signal with only one or two distinct
finite times. Supporting their file layout will not create enough data for
high-order derivatives. **Armistead** illustrates this despite only four
species. These cases may require model-assisted trajectory fitting or using
ODEPE as an initializer for a conventional optimizer. New dense simulated
data would answer a different benchmark question.

### 4. Unknown exponential inputs through auxiliary states

**Boehm** provides a bounded mathematical extension: replace
`exp(-k*t)` by `z`, with `z' = -k*z` and `z(0) = 1`. The augmented dynamics are
rational, with the original unknown rate retained. This needs a way to enforce
the auxiliary initial condition and map results back to the original model;
simply making `z(0)` a free parameter changes the problem.

**Fiedler** has two such time constants, but also joint experiments, batch
scales, and parameter-dependent square-root IC expressions. Exponential
lifting alone would not finish its support.

**Rahman** suggests a more substantial extension: if `z = exp(-b*S(x))`, then
`z' = -b*z*S'(x)`. Its augmented dynamics can be rational, but the initial
constraint `z(0) = exp(-b*S(x(0)))` is still nonrational in unknowns. The same
distinction matters for **Borghans/Elowitz**: `z = x^n` gives
`z' = n*z*x'/x` where `x` is nonzero, but preserving the unknown-power initial
and parameter relations is additional work. Fixing or rounding the estimated
Hill exponent would change the published problem. These belong after the
simpler Boehm experiment.

### 5. Equilibria and piecewise experiments

Pre-equilibration occurs in five models; two others have only steady-state
observations. For rational systems, equations `f(x_ss, p) = 0` are a natural
algebraic entry point. But arbitrary stationary roots are insufficient: the
intended steady state, conservation constraints, and mapping into the next
experiment must be preserved. **Blasi** is a modest equilibrium-only research
case; **Froehlich** is much too large as a first implementation target.

For timed inputs, fit smooth segments and enforce continuity or specified
resets between them. Do not interpolate derivatives through a discontinuity.
Known intervention times, estimated switch times (**Beer/Oliveira**), and
state-triggered events (**Liu/Smith**) have different implementation costs.
Liu also has a parameter-dependent exponential IC and relative/absolute noise.
These should be separate extensions, with explicit exclusion reasons until
implemented and checked.

### 6. Size and practical identifiability

Large rational models still need tractable elimination, root solving, and
enough informative observations. **Lang** has 124 species and 294 estimated
parameters; **Chen** has 500 species; **Froehlich** has 1,396 species and 4,231
estimated parameters. Conversely, SalazarCavazos has only six estimated
parameters but 75 species and 18 measurements. Supporting these cannot be
promised from expression compatibility or small parameter counts alone.

Use supported small problems to measure symbolic construction cost, candidate
quality, and runtime before deciding which reductions or alternate estimators
are justified. There is no current evidence that the entire collection should
become an ODEPE acceptance gate.

## Initial roadmap

The approved pilot subsequently implemented a broader target set, including
joint Bertozzi experiments and the explicit Boehm input lift. See its
[record](2026-09-10_petab_pilot.md) for the final scope and measured outcomes.

Start with a bounded Perelson experiment using the original public data. This
is a feasibility investigation, not a claim that it will fit well.

1. Build an explicit mapping for the two kinetic unknowns, fixed constants,
   initial states, observation formula, parameter bounds, and noise parameter.
   Check imported trajectories and the likelihood against PEtab.jl at several
   parameter vectors before attempting an estimation comparison.
2. Generate ODEPE candidates from the public measurements. Evaluate admissible
   kinetic parameter candidates using the original fixed initial conditions
   and PEtab likelihood, handling the noise parameter consistently. Record
   any difference between ODEPE's candidate construction and the published
   constrained problem. Nominal parameter values are reference values, not
   experimental ground truth.
3. Compare fit quality, runtime, and failure rate under a stated budget. If
   PEtab likelihood optimization refines ODEPE candidates, report that as an
   ODEPE-initialized optimization method and compare it with the same optimizer
   using its ordinary starts. Include candidate-generation time.
4. Extend the same mapping/scoring checks to independent Bertozzi fits and
   Okuonghae. Use Crauste to measure the sparse-data limitation. Only then
   choose between joint-experiment support (Bruno/Sneyd/Fujita) and a bounded
   unknown-input extension (Boehm), based on measured benefit and effort.
   Retain exclusion reasons and numerical failures in the benchmark results.

Keep two benchmark questions separate in reporting: fitting the original
published data, and recovering known parameters from newly simulated data
using published models. Both are useful; regenerated dense data do not
establish performance on the original sparse experiments.

For the second question, [ODEbase](https://odebase.org/) is another useful
source: it provides symbolic ODE models and labels rational/polynomial
systems. Observation choices, initial conditions, sampling, and noise would
need a declared synthetic benchmark protocol. For original experimental
problems, the PEtab collection is the better initial target.
