# Sneyd: select without MV, then inspect the actual HC family

These are research drivers, not production solver defaults. They reuse the
existing PEtab diagnostic environment without resolving or installing packages.
The [findings and interpretation](../../docs/2026-09-15_sneyd_hc_boundary.md)
record successful selection, the later polyhedral start-system failure, and
three monodromy attempts that never reached loops. No estimation roots or
benchmark scores were produced.

## Capture the selected system

From the repo root, using fresh output directories:

```sh
python3 repro/petab/dense_single/supervise.py sneyd \
  /tmp/sneyd-selected --seconds 1200 --multiplicity 544 \
  --skip-selection-mv --capture-generic-system
```

The normal dense-data workflow runs through SI and single-point subsystem
selection with `construction_compute_mixed_volume=false`. An explicitly loaded,
process-local method captures the first call to `compute_generic_start_solutions`
and raises an interrupt; the harness records `captured_generic_system`. No HC
solve or observation fit has happened at this point. The production source
and defaults are unchanged. Without `--capture-generic-system`, the dense run
continues normally. Without `--skip-selection-mv`, selection still scores MV.

`generic_system.json` contains the ordered unknowns, data parameters, equations,
exact numerator/denominator/exponent lists, and the generic complex parameter
vector the normal hoisted solve would use. Float coefficients are stored as
their exact binary rational values. These are the **selected** equations, which
need not have the same size as the earlier rank-trimmed SI template.

## Two separate solver diagnostics

```sh
python3 repro/sneyd_hc_2026_09_15/supervise.py \
  /tmp/sneyd-selected/generic_system.json /tmp/sneyd-polyhedral \
  polyhedral --seconds 1800
python3 repro/sneyd_hc_2026_09_15/supervise.py \
  /tmp/sneyd-selected/generic_system.json /tmp/sneyd-monodromy \
  monodromy --seconds 600
```

Both reconstruct and check every coefficient and exponent before invoking HC.
They use one Julia thread, seed 20260915 and `compile=:all`. Inputs, exact worker
sources, checkpoints, logs, sampled profiles and supervisor results are saved.
The supervisor bounds the whole operation with a monotonic clock, including
start-pair search and compilation; monodromy's own timeout alone excludes some
of that setup. SIGINT has a 20-second grace period before process termination.

The polyhedral arm calls HC's usual `solver_startsolutions` once at the captured
generic data vector. Its affine start system can augment supports with the
origin; its path count is distinct from the torus-only selection MV and from M.
If setup completes, `ResultIterator` streams the same HC paths serially instead
of allocating every start vector in advance. This driver saves successful
endpoints but does not deduplicate them or claim a complete root count.

The monodromy arm first calls `find_start_pair` with 100 random Newton attempts
in both unknowns and data parameters. It supplies no nominal states/parameters
or known synthetic root. It then allows ten loops without progress, with no
M-based stopping target or symmetry quotient. Residuals and distinct-root
certification are recorded separately from heuristic root discovery; neither
alone establishes completeness. These roots are at its discovered data vector,
not necessarily at the polyhedral arm's generic vector or any observed data.

No parameter estimates or PEtab benchmark scores follow from these diagnostics
alone. The earlier six-variable coefficient counter is a different system.

## Exact inspection and a supplied-start comparison

`inspect_selected.py SYSTEM_JSON SI_TEMPLATE OUTPUT_JSON` checks ordered
polynomial identity against the separate SI-template save, counts state/kinetic
roles and degrees, and verifies a nonempty extraneous family at `l6=l_6=0`.
It requires SymPy, already present in the research environment.

If the automatic start search fails, a separate diagnostic supplies one exact
root by forward-generating state/output jets from the earlier counter's
six-state matrix. It uses the same independent `(2,3,5,7,11)` kinetic reference
as the side count, not the published data-generating values. Every selected
polynomial is checked over the rationals before HC sees the start.

```sh
python3 repro/sneyd_hc_2026_09_15/make_known_start.py \
  /tmp/sneyd-selected/generic_system.json /tmp/sneyd-side-counter/counter.json \
  /tmp/sneyd-known-start.json
python3 repro/sneyd_hc_2026_09_15/supervise.py \
  /tmp/sneyd-selected/generic_system.json /tmp/sneyd-known-monodromy \
  monodromy --seconds 600 --known-start /tmp/sneyd-known-start.json
```

The matrix artifact is reproducible with
`repro/separate_m_2026_09_15/build_counter.py`; its original compressed copy is
retained with that study. Supplying a root changes what this arm measures: it
tests loop tracking/discovery, not whether HC can find a start unaided.

`normalize_known_start.py SYSTEM_JSON START_JSON OUTPUT_DIR` produces another
pair of inputs with exact invertible scaling of unknowns, data parameters, and
equation rows. The same `supervise.py ... --known-start ...` command runs it.
The normalized system retains every exponent and records all rational scale
factors; the script checks every scaling identity and every root residual
exactly. Root vectors reported for this arm are in **normalized coordinates**.
This is not ODEPE's production column-scaling policy, which does not use a known
root; it isolates the numerical difficulty of tracking this particular family.
