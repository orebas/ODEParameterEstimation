# PEtab pilot implementation record

The approved pilot covers the original canonical problems at benchmark revision
`ddaa86d13f708926c57ec8918ce75a6b50e2e562`: Perelson, Bertozzi, Okuonghae,
Bruno, Fujita, Zhao, Sneyd, Boehm, and the harder Crauste and Raia cases.
Preserve the published observations, conditions, initial preparation, parameter
constraints, and likelihood. Report algebraic candidates and optional polish
separately. Run one attempt per method/problem initially, with a 15 minute cap;
this is a feasibility pilot rather than a performance-ranking study.

## Implementation sequence

1. Isolated Julia 1.13 environment, optional PEtab API, faithful Perelson run.
2. Typed observation series, unequal grids/replicates, IC and parameter mappings;
   extend to Bertozzi and Okuonghae and assess Crauste.
3. Explicit joint rational models with shared parameters, experiment-local
   states, joint identifiability, and original joint likelihood; Bruno, Fujita,
   Zhao, Sneyd, Raia.
4. Exact Boehm input lifting, `z'=-k*z`, `z(0)=1`.
5. One-run PEtab.jl/Fides and pyPESTO/AMICI comparisons, result artifacts,
   full core gate, recovery benchmark, and optional integration tests.

Equilibria, general events, estimated switching times, arbitrary estimated
powers, large-network scaling, and uncertainty calibration are deferred.
Published fitted parameter values may validate mappings but must not initialize
estimation. Structural representative fixing must not freeze a PEtab-estimated
parameter in the final fit. Any relaxed IC constraints in the algebraic stage
must be disclosed and the original preparation used for scoring and polish.

## Status

The implementation, local validation and all 30 planned attempts are complete.
Nine models passed the adapter's simulation/preparation checks; Crauste remains
unsupported. Practical estimation is much narrower in this first pilot: ODEPE
returned a valid refined fit for Perelson, rejected every Bertozzi candidate and
timed out on the other seven supported models. The original 35-model inventory
remains in `2026-09-10_public_benchmark_triage.md` and
`2026-09-10_petab_inventory.csv`.

The environment bootstrap is `repro/petab/setup.jl`. It preserves the global
environment and fixes the existing scientific dependency versions in a separate
environment. CSV's Parsers 2 requirement is resolved only there.

The complete manifest comparison found exactly two changed shared packages in
the isolated environment: Parsers 3.0.0 to 2.8.8 and XML2_jll 2.15.3+0 to
2.13.9+0 (SBML's binary constraint). Existing scientific versions and GP/SIAN
development paths are unchanged. No global Project or Manifest was edited.

### Implementation and validation

- `ObservationSeries` and `ObservationData` preserve independent grids and
  repeated rows. Algebraic interpolation uses a common anchor interval; forward
  scoring and both core polish losses use the real timestamps. Rescaling retains
  series metadata, including aliased observable IDs without duplicating pooled
  rows. The expanded regression file passed 35 checks, including both residual
  polish solvers. The full core gate passed 1,811 assertions in 18m45.9s, and the
  recovery gate passed all 10 assertions in 29m01.0s on the original dependency
  stack. Recovery tolerances and best-of-branch errors are unchanged from the
  stabilization baseline. A diagnostic stack sample found the recovery gate's
  long silent stage in LLVM compilation of the existing robust polynomial
  Jacobian; no solver or Jacobian configuration was changed in this pilot.
- The optional extension now loads and exposes `load_petab_problem` and
  `estimate_petab_problem`. It builds the combined model before SI/SIAN analysis,
  excludes nominal estimated values from algebraic truth fields, retains all raw
  algebraic candidates for PEtab scoring, and sends the unchanged estimated
  parameter vector to optional PEtab refinement.
- Initial-only affine parameter maps are inverted from recovered states.
  Experiment-specific time offsets let Zhao's disjoint measurement windows use
  local algebraic anchors; candidate states are integrated back to the original
  preparation before initial-parameter projection. Fixed preparation is always
  enforced by the PEtab objective.
- Boehm uses an exact auxiliary exponential state; Fujita's input is simplified
  only when its linear switching condition does not change inside the simulated
  interval. General events and interior switches remain excluded.
- Nominal and displaced-parameter simulation/IC parity has passed for Perelson,
  Okuonghae, Bruno, Fujita, Zhao, Sneyd and Boehm. The focused Bertozzi/Raia
  canonical check passed 24 assertions after importer repairs. Crauste has no
  common observed interval and only two Naive measurements; it remains an
  unsupported challenge case.
- The optional fixture suite passed 36 assertions: joint grids/preparation and
  absence of nominal-value leakage, analytic condition-dependent trajectories,
  initial assignments, and finite-difference gradient checks including
  observable-dependent noise. The external supervisor passed four process
  containment tests. An optional Julia 1.13 CI profile runs these contracts;
  its fresh temporary environment also passed all 36 locally with MTK 11.42.1,
  Symbolics 7.39.2 and SymbolicUtils 4.46.4. This fresh resolution is separate
  from the pinned pilot environment. Counts, timings and local log hashes are
  retained in [`validation.json`](../repro/petab/validation.json).

### Dependency findings and development failures

- PEtab 5.4.3 freezes Bertozzi's `beta_N` at its SBML default `0.01`, even after
  applying condition values for `R0_`, `gamma_`, and `N_`. For California at the
  reference parameters the correct value is about `4.86e-9`. The optional
  adapter's compatibility layer expresses dependent parameter initial
  assignments as condition formulas and rebuilds PEtab before it allocates its
  derivative caches. It changes no files in the published problem or installed
  dependencies. This needs a focused upstream regression/fix.
- Expanding Sneyd's rational expressions with `Symbolics.simplify` introduced
  destructive floating-point cancellations. Removing that unnecessary adapter
  expansion restored parity.
- Raia's rule-free, event-free `il13_level` has `constant=false` in SBML.
  SBMLImporter drops it before PEtab applies experimental conditions. A
  semantically equivalent temporary SBML document marks that constant input
  explicitly. The native SBML conversion hook preserves its annotations.
  Raia also uses observable row-parameter placeholders inside noise formulas;
  PEtab's noise callback does not receive that vector. The adapter inlines
  mappings that are identical across rows into both formulas, preserving all
  estimated parameters and the original noise model. Varying mappings in such
  noise formulas are rejected explicitly.
- Symbolics prints integer multiples as `2k`, which PEtab's identifier scanner
  misses. Condition formulas are serialized with explicit arithmetic operators.
- The first Perelson algebraic run reached refinement, where Fides rejected a
  plain Vector alongside PEtab's ComponentVector bounds. The runner now creates
  a matching named starting vector. Candidate results are checkpointed before
  refinement, and refinement failure preserves them.
- The Python comparator required an explicit `petab` installation in addition
  to pyPESTO's AMICI/Fides extras. The isolated environment currently contains
  AMICI 1.1.0, pyPESTO 0.7.0, Fides 0.8.0 and PEtab 0.9.0. Its complete lock file
  is recorded along with Julia Project/Manifest snapshots and the dependency audit.
- Fujita's Julia baseline hit a nested time-AD error in Rodas5P. The runner uses
  QNDF for the nonautonomous Fujita/Boehm imports, with the same PEtab configuration
  for the baseline and ODEPE refinement. Its repeated compatibility check used
  the original start and is listed in `development_attempts.json`.
- A ready-marker publication race interrupted the supervisor while Sneyd's Julia
  baseline kept running. That worker finished successfully and was not repeated.
  Ready markers are now published atomically, and monitoring always contains its
  worker on failure; the regression tests exercise the original race.

Development failures are preserved separately from the active pilot results.
They are implementation checks, not additional random starts or evidence of
statistical reliability. No performance ranking is justified by this pilot.

### Completed pilot results

The [complete result table](../repro/petab/pilot_results/summary.md) and
[per-attempt CSV](../repro/petab/pilot_results/summary.csv) include every planned
cell, its status, and successful or unsuccessful terminations. Finite returned
objectives are distinguished from optimizer convergence.

The two conventional Perelson baselines completed from the same recorded random
start. Their returned NLLHs agree: Julia `10842.629398169369`, AMICI
`10842.629368386437`; both report Fides `FTOL`. This is a local termination status,
not evidence of a global optimum. The initial NLLH was about `8.3654e13`. The
corrected ODEPE run produced 122 raw candidates, five inside the PEtab bounds,
and refined the best to NLLH `227.56759766339917` (`FTOL`). The raw best scored
candidate had NLLH `1.3035344650654185e12`; its noise parameter retained the shared
random starting value until refinement. These are separate estimator stages.

The retained Perelson attempt predates a preparation-diagnostic correction: its
stored zero residual did not check all fixed initial-state constraints. That
field is not evidence that the algebraic initial states obeyed the original
preparation. The scored and refined objectives did use the original preparation.
The current adapter reports all initial-map residuals and retains raw state and
parameter provenance for rejected candidates; early artifacts have fewer fields.

Bertozzi returned 20 raw candidates, with none passing the original bounds.
Okuonghae, Bruno, Fujita, Zhao, Sneyd, Boehm and Raia reached their time caps
before returning a scored candidate. Crauste was rejected for lacking a common
observed interval. No random restarts or relaxed feasibility bounds were
introduced to turn those failures into successful runs.

Each conventional baseline returned a converged finite objective for eight
problems. Both stopped without convergence on Fujita (`DELTA_TOO_SMALL`), at
substantially different objectives, and failed from the nonfinite shared start
on Crauste. Most corresponding baseline objectives are close; Zhao differs
noticeably. A single start does not measure reliability or establish the best
attainable fit. All 63 retained starting, candidate and fitted vectors were
checked against the canonical parameter IDs and scaled bounds, and the shared
starts agree exactly by parameter ID. The published benchmark source files
remain unchanged.

The supervisor is `repro/petab/run_pilot.py`, with targets and the pinned public
revision in `repro/petab/targets.toml`. It starts the time cap after package load
and before any model-specific preparation. The scripts record initial vectors,
stage timing, exact objectives, candidate provenance, failures, and hard timeouts.

### Next computational investigation

The [retained termination evidence](../repro/petab/pilot_results/timeout_diagnostics.json)
identifies two preparation paths worth profiling:

- Bruno, Fujita and Zhao were in SIAN's `differentiate_all`/`get_x_eq`, called while
  constructing the polynomial system in `prepare_si_template_with_structural_fix`.
- Okuonghae, Sneyd, Boehm and Raia were in `populate_derivatives` during numerical
  identifiability advisory setup. Boehm and Sneyd show Symbolics derivative
  expansion; Okuonghae and Raia were printing large symbolic expressions for the
  derivative routine's coefficient-overflow check.

These are snapshots at the cap, not profiles of the full attempts. They do not
establish how much of each budget was spent on compilation, differentiation,
identifiability analysis or root solving. A follow-up should measure those stages
before enlarging the target set or running a multistart campaign. The pilot keeps
the original caps, failed attempts and bounds. It does not bypass joint SI/SIAN
analysis to manufacture successful estimates.
