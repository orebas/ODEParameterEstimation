# PEtab feasibility pilot

ODEPE can import a restricted PEtab v1 problem, generate candidates from a joint
algebraic model, and score or refine those candidates with the original PEtab
likelihood. PEtab is an optional dependency. The tested importer is PEtab.jl
5.4.3 on Julia 1.13; the compatibility range is restricted to its 5.4 patch series
because the adapter accesses its imported model representation.

This is a feasibility integration. Loading a supported model does not establish
that its polynomial system can be solved within a useful time budget. The
[pilot record](2026-09-10_petab_pilot.md) describes the canonical target set,
dependency findings and actual outcomes.

The [dense single-experiment study](2026-09-11_dense_single_experiments.md)
separately tests synthetic recovery with the normal nine-interpolator benchmark
workflow and profiles symbolic setup. It does not use the original noisy PEtab
measurements or claim a likelihood comparison.

## Data and experiment semantics

`ObservationSeries(id, experiment_id, expression, times, values)` owns and sorts
one signal's measurements. `ObservationData(series; initial_time=0.0)` collects
independent grids and retains repeated observations. No values are filled in or
averaged. Its dictionary lookup returns values by symbolic expression;
`observation_times(data, expression)` returns their real timestamps. `data["t"]`
is an algebraic anchor grid inside the interval common to all signals, not a
measurement grid for every signal.

Repeated observations enter GP fitting as separate rows. The robust GP can fit
the repeated times; its derivative curve remains an approximation. Optional
`noise_std` metadata is retained and rescaled, but the current algebraic GP fits
do not consume per-row noise weights. Core trajectory scoring uses unweighted
SSE. The PEtab adapter instead delegates scoring and refinement to PEtab's
original likelihood, including its noise model, observable transformations and
parameter priors.

Each PEtab simulation condition gets its own state variables. Estimated
parameters are shared by PEtab ID. The combined equations are built **before**
SI/SIAN identifiability analysis and structural representative fixing. Merely
changing `experiment_id` on a core observation series does not create independent
states: core callers must construct the joint equations explicitly.

Autonomous conditions with different absolute observation windows use independent
time offsets for algebraic anchors. Recovered states are integrated back to the
original physical preparation. Affine initial-only parameter maps are then
projected by least squares. Algebraic initial states are relaxed; their mismatch
with the original preparation is reported. Every candidate's PEtab objective
reimposes the original preparation. Final refinement frees every `estimate=1`
parameter, including any representative fixed during the algebraic stage.

## API

```julia
using ODEParameterEstimation, PEtab, Fides

problem = load_petab_problem("path/to/problem.yaml")

function refine_petab(p, x, seconds)
    # Fides requires the starting vector and bounds to have matching types.
    start = similar(p.lower_bounds)
    start .= x
    calibrate(p, start, Fides.BFGS();
        options=Fides.FidesOptions(maxtime=Float64(seconds), maxiter=10_000))
end

result = estimate_petab_problem(problem;
    options=EstimationOptions(compute_uncertainty=false),
    seed=20260910, polish=refine_petab, max_seconds=900.0)

result.candidates        # complete scaled vectors, PEtab NLLH and provenance
result.rejected          # invalid candidates and reasons
result.refined           # accepted refinement, or nothing
result.polish_error      # failure text, retaining algebraic candidates
result.parameter_ids    # ordering for every vector
```

Omit `polish` to inspect algebraic candidates alone. Supply `x0` in PEtab's scaled
parameter coordinates to control initialization. Otherwise the pilot samples
uniformly within scaled bounds with its recorded seed; problems with explicit
initialization distributions require a supplied vector. Published estimated
nominal values are used only in validation tests, never to initialize a fit.
Parameters absent from the algebraic equations, such as noise parameters, retain
their starting values until PEtab refinement.

`max_seconds` prevents starting later stages after the budget expires. A separate
process supervisor is required to interrupt noninterruptible SI/Groebner/HC
preparation. The provided runner enforces the wall-clock limit and checkpoints
scored candidates before refinement.

### Bounded experiment groups

The opt-in block constructor uses one local state block per condition and shares
kinetic/observable parameters by PEtab ID. It expands the local observation jets
one derivative order at a time, eliminates state derivatives using the local ODE,
then applies the existing multipoint rank/basis selector to the combined pool.
It does not run SIAN on the concatenated ODE or fix representatives separately
inside each experiment.

```julia
conditions = collect(keys(problem.condition_states))
result = estimate_petab_problem(problem;
    options=EstimationOptions(compute_uncertainty=false, shooting_points=3),
    experiment_groups=[conditions[1:2]], max_derivative_order=4,
    x0=recorded_start, polish=refine_petab, max_seconds=900.0)
result.construction  # order-by-order equation counts, unknowns and numerical rank
```

Start with two conditions. Groups are explicitly limited to six conditions;
the derivative limit defaults to four and accepts 0–10. Several shooting anchors
produce several systems with the same block count, rather than one larger system.
A pool that remains deficient at the limit returns `:rank_deficient_at_limit`.
This numerical rank check is not a structural-identifiability certificate.
The current trial examines up to eight bases at the first full-rank order and
uses the existing parameterized HC solver, without mixed-volume ranking.

Every root retains all of its local states and physical anchor times. Candidate
projection uses the selected conditions' preparations; parameters that the group
does not estimate stay at `x0`. Scoring and refinement still use **all** original
conditions and **all** estimated PEtab parameters. No state trajectories are
averaged across experiments. States with no ODE dependency path to a measured
signal are omitted from candidate generation and listed in the construction
report. Their original preparations still enter full-objective simulation.
Auxiliary input states currently require the original
combined constructor. Separate complete experiment fits remain a future comparison.

The [derivative-cap follow-up](2026-09-11_petab_derivatives_and_bruno.md)
records explicit cap-10 trials, polynomial degrees and term counts, and a detailed
Bruno example showing the distinction between a relaxed algebraic root and its
prepared parameter seed.

### Experimental coefficient extraction

For models with rational parameter assignments and linear reaction fluxes,
the optional extension can preserve the parameter-to-rate definitions:

```julia
extension = Base.get_extension(ODEParameterEstimation, :ODEParameterEstimationPEtabExt)
structure = extension.petab_coefficient_structure(problem, condition_id)
structure.assignments           # named SBML assignment rules
structure.coefficients          # reaction rates retaining those names
structure.expanded_coefficients # rational functions of estimated parameters
structure.dynamics              # ODEs using constrained coefficient variables
structure.denominator_guards    # source exclusions, retained before cancellation
```

Extraction checks the expanded equations against the loaded adapter. It is an
inspection helper; the definitions are not yet consumed by estimation. The
[Sneyd trial](2026-09-15_coefficient_lifting.md) records exact branch-preserving
polynomial lifting and its 20-minute Gröbner timeout.

## Current boundaries

- The joint ODE and observation formulas must be rational in states and
  estimated parameters. Estimated or noninteger powers are rejected.
- Exponential forcing of the form `exp(rate*t)` can be represented exactly by
  an auxiliary state with initial value one. This covers Boehm. Combining this
  lift with a nonzero experiment time offset is not implemented.
- Fixed piecewise inputs can be simplified only if no switch occurs inside the
  simulated interval. General events, estimated switches, pre-equilibration,
  steady-state measurements and DAEs remain outside this pilot.
- All signals need a common interval after experiment time offsets. Crauste
  violates this condition and its Naive signal has only two observations; it is
  retained as an unsupported challenge case, without invented derivative data.
- UQ for the new observation representation is rejected explicitly. This work
  makes no new calibration claim.

The importer includes narrowly scoped compatibility repairs for condition-dependent
SBML initial assignments and constant-within-experiment inputs. It leaves the
published problem files and installed dependencies untouched. Regression fixtures
check analytic trajectories, initial maps, parameter derivatives and absence of
nominal-value leakage. The older nested code under
`ext/ODEParameterEstimationPEtabExt/src/` is historical and is not loaded.

## Reproduce the pilot

See [repro/petab/README.md](../repro/petab/README.md) for environment setup, the
pinned public models, validation commands and the comparison runner. The core
full gate and recovery benchmark remain separate from optional PEtab contracts.
