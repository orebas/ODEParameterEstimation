# Bounded multi-experiment construction trial

This follows the [initial pilot](2026-09-10_petab_pilot.md), where concatenating
every condition before symbolic preparation caused several timeouts. The working
hypothesis is the same algebraic construction used for multipoint: shared
parameters, local state blocks, and joint equation reduction. The trial starts
with two conditions and compares four where practical; six is an explicit limit.

## Implementation

`estimate_petab_problem(...; experiment_groups=[["condition_a", "condition_b"]])`
opts into the constructor in `ext/petab/experiment_blocks.jl`. The original
combined route remains available when this keyword is omitted.

For each condition, the constructor starts from its observed expressions and
uses its ODE to generate successive local observation derivatives. State
derivatives are eliminated in these expressions. Parameter symbols retain their
PEtab IDs; state symbols remain local. Only states with no dependency path to
an observed signal are omitted. No independent representative values are fixed.

After each derivative order, the combined pool goes through the existing
multipoint noise-frontier rank/basis selector. Rank is evaluated on the rational
observation map: random data in cleared-denominator equations can otherwise
create spurious rank off the solution set. At the first feasible order, up to
eight bases are compared by the existing support/conditioning criteria. This
trial does not compute mixed volumes for basis ranking. The selected square
system uses the existing parameterized HC solver, including column scaling.
Roots are checked against the selected original rational equations and ODE poles.

The derivative cap is four in the recorded runs. This cap is a computational
choice, not a theorem about identifiability or an assertion that four noisy
derivatives can be estimated accurately. The API originally permitted an explicit
cap from zero through eight; the [follow-up](2026-09-11_petab_derivatives_and_bruno.md)
extends this to ten and records separate higher-cap trials. Rank deficiency at the cap is reported without invoking
SIAN on the concatenated system or increasing derivative order silently.

Each root keeps its retained states from every selected experiment and their
physical anchor times. Closed local subsystems are integrated back to physical
time zero for preparation projection. Parameters absent from the group retain
the recorded start. Every candidate is scored on all original observations;
refinement frees all PEtab-estimated parameters and uses all conditions.

A related core bug was fixed: multipoint shared-parameter classification used
the optional truth dictionaries. Those are intentionally empty for PEtab.
Classification now uses the model's declared parameter and state lists.

## Protocol and results

See the [retained trial table](../repro/petab/block_results/summary.md) and
[full precision CSV](../repro/petab/block_results/summary.csv). The original
`pilot_results` records are unchanged. Starts are exact copies of that pilot,
mapped by parameter ID. Canonical benchmark revision remains
`ddaa86d13f708926c57ec8918ce75a6b50e2e562`; no dependency versions or public model
files were changed. Each method has its own 900-second model-specific budget,
including model import and compilation after package loading. Workers overlap,
so these runs do not establish a speed ranking or success probability.

Bruno's first two conditions reduce to seven unknowns (three kinetic parameters
and four local states). Nine equations through second derivatives reduce to a
seven-equation system. It produces 12 roots, five valid full-objective seeds,
and refines to NLLH 874.2012375, close to both original numerical baselines.
Its best raw NLLH is about 7.96 million, slightly worse than the recorded start's
7.85 million. This establishes a tractable algebraic seed route for this subset;
the final good likelihood still depends on numerical refinement.

With four conditions, Bruno uses 18 unknowns and derivatives through order
three, reducing 32 equations to 18. It yields 24 roots, five valid seeds, raw
NLLH 448356.72, and refined NLLH **−46.6881812**. With all six conditions it
needs **only first derivatives**: 22 equations reduce to 21 unknowns, all 12
returned roots give valid seeds, the best raw NLLH is **51.5643917**, and the
refined NLLH is **−46.6881798**. Thus more conditions increased system size but
substantially reduced the required derivative order and improved the raw seed.
The lower refined objective than the two earlier baseline runs indicates a
better attained solution, not a general optimizer ranking or proof of optimality.

[Independent AMICI re-evaluation](../repro/petab/block_results/bruno_amici_validation.json)
confirms all six raw/refined scores from these three runs on the untouched
canonical model. Differences at the two better refined solutions are below
`6e-6` in NLLH. This validation performs no optimization and supplies no new starts.

Fujita's two-condition pool has 30 independent equations for 34 unknowns at
order four. Four conditions reach 52/52 rank and reduce 60 equations to 52, but
the run times out inside HC's polyhedral mixed-cell construction before returning
candidates. The interpolation stage also reported GP hyperparameter fallback
warnings; the termination stack identifies the later HC stage, not GP fitting,
as the active operation at termination.

Zhao's first two conditions reach 10/14 rank at order four. Its fitted rates are
distinct by region/stage, so these conditions do not share estimated kinetic
parameters; concatenating them gives no such cross-experiment information gain.
Separate estimation is a natural next comparison there, though each relaxed
single-condition pool would still require more than four derivatives or additional
constraints. This capped result does not establish nonidentifiability.

Sneyd times out while clearing denominators for the next local jet, inside
SymbolicUtils/MultivariatePolynomials rational GCD simplification. Its last
completed rank check is 4/26 at order one. Even completing the order-four pool
would provide at most ten observation equations for 26 unknowns. This case needs
both a better formulation and cheaper symbolic preparation; simply increasing
the condition count is not established as a remedy.

The two timed-out records report about 940–943 seconds through termination and
cleanup, versus the requested 900-second worker budget. Timeout snapshots and
log digests are retained in
[`timeout_diagnostics.json`](../repro/petab/block_results/timeout_diagnostics.json).

These trials support keeping small joint groups as an option. They do not
support imposing a universal cutoff based only on condition count: six Bruno
conditions worked with 21 unknowns and first derivatives, while four Fujita
conditions produced a 52-unknown system requiring fourth derivatives. Separate
fits are particularly appropriate to investigate when parameter sets do not overlap.

## Validation

The Julia 1.13 core gate passed **1,813/1,813** tests (15m58.4s); recovery passed
**10/10** (23m31.9s), with the four recorded recovery errors unchanged from the
previous commit. The final optional PEtab contracts passed **111/111** and the
Python supervisor contracts passed **4/4**. Existing development overrides and
dependency versions were preserved. Optional tests cover an exactly
solvable pair that is identifiable only jointly, shared parameter identity with
empty truth dictionaries, rational-map rank, state/epoch mapping, closed-subsystem
omission, and scoring/refinement of the unchanged full PEtab objective.

Separate complete experiment fits and reconciliation of their estimates are
not implemented by this trial. Neither a capped rank failure nor successful
refinement establishes the full problem's structural identifiability. Known
preparation constraints, conservation relations, additional anchors, and joint
representative selection may still matter for the harder models.
