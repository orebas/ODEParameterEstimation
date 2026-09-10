# Public benchmark and PEtab triage

Read-only source assessment, 2026-09-10. No public benchmark estimation runs
were performed, and no package code or dependency environments were changed
in this assessment. RS/RUR restoration is deferred at the user's request.

## What exists in this checkout

The PEtab work is an unfinished experiment, not a working public benchmark
importer. Much of [`src/examples/petab/`](../src/examples/petab/README.md)
exports ODEPE's own example models through TOML to PEtab. Those generated
datasets are distinct from the published experiments in the public collection.

The extension's [entry point](../ext/ODEParameterEstimationPEtabExt.jl)
includes missing paths and exports names that its nested loader/converter do
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

## Public collection screen

Inspected the Benchmarking Initiative's
[Benchmark-Models-PEtab collection](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562),
revision `ddaa86d13f708926c57ec8918ce75a6b50e2e562`. Its README lists 35
problems. Twelve have one condition. Seven remain after additionally excluding
listed events, possible discontinuities, pre/post-equilibration, and objective
priors:

- Boehm_JProteomeRes2014
- Borghans_BiophysChem1997
- Crauste_CellSystems2017
- Elowitz_Nature2000
- Okuonghae_ChaosSolitonsFractals2020
- Perelson_Science1996
- Rahman_MBS2016

This is a metadata screen, not seven supported problems. It does not establish
rational dynamics, adequate observations, identifiability, or computational
tractability. YAML, SBML, condition, parameter, observable, and measurement
files were inspected for four of these problems:

| Problem | Actual data and parameters | Main implications for ODEPE |
|---|---|---|
| [Perelson](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562/Benchmark-Models/Perelson_Science1996) | Four species; one observable at 16 times; two estimated kinetic parameters and one estimated noise parameter. | Smallest first candidate among those inspected. Rational dynamics, but fixed initial conditions and other fixed parameters must be preserved. The likelihood uses log10-transformed residuals. Recovery has not been tested. |
| [Boehm](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562/Benchmark-Models/Boehm_JProteomeRes2014) | Eight species; three observables on the same 16-point grid; six estimated kinetic parameters and three estimated noise parameters. | Rational observation formulas are not themselves a blocker. An exponential input contains an unknown degradation rate; current known-coefficient input handling does not cover it. Fixed/derived initial conditions and noise parameters also require explicit treatment. |
| [Crauste](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562/Benchmark-Models/Crauste_CellSystems2017) | Five species; twelve estimated parameters; only 21 observations. The four observables have 2, 7, 7, and 5 distinct times. | Rational equations, but sparse, unequal observation grids and a different supplied standard deviation for each measurement. Fixed initial conditions apply at time zero; measurements begin at time 4. The native Crauste examples are not evidence of recovery on this dataset. |
| [Rahman](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab/tree/ddaa86d13f708926c57ec8918ce75a6b50e2e562/Benchmark-Models/Rahman_MBS2016) | Seven species; nine estimated parameters; one observable at 23 times; constant supplied noise scale. | The infection rule contains an exponential involving states and an estimated parameter. This exceeds the current known-input transformation; a simple table importer would not make it supported. |

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

## Recommended next increment

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
4. Add further problems according to explicit compatibility criteria and
   retain exclusion reasons and numerical failures. Generalize the adapter
   only after this first mapping and scoring check works.

Keep two benchmark questions separate in reporting: fitting the original
published data, and recovering known parameters from newly simulated data
using published models. Both are useful; regenerated dense data do not
establish performance on the original sparse experiments.

For the second question, [ODEbase](https://odebase.org/) is another useful
source: it provides symbolic ODE models and labels rational/polynomial
systems. Observation choices, initial conditions, sampling, and noise would
need a declared synthetic benchmark protocol. For original experimental
problems, the PEtab collection is the better initial target.
