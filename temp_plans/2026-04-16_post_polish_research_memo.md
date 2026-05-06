# Post-Polish Research Memo

_Generated: 2026-04-16_

## Summary

This memo records the post-`ODE+POLISH` estimation work that was added to improve bilby benchmark performance, especially on cases where AMIGO2 was outperforming ODEPE. It is intentionally limited to the work layered on top of the standard search + polish baseline, not the full history of multipoint or earlier structural-identifiability research.

The high-level arc was:

1. add new **seed generators** beyond the stock polished raw pool,
2. add ways to **polish broader seed sets** without collapsing back to a single brittle winner,
3. shift evaluation from “did fit choose the right winner?” to “is the good basin in the returned set?”,
4. gradually replace fixed-rank truncation with **baseline-preserving frontier admission** and **post-polish basin clustering**,
5. separate problems that look like finalizer/basin issues (`crauste`) from problems that look structural or bounds-related (`cstr`).

The core lesson is that, on hard bilby cases, **post-polish fit is often a bad selector**, while **set coverage** is a much more reliable target. The strongest additions were therefore not new fit heuristics, but machinery to preserve more plausible basins and return finalists rather than forcing an early single winner.

## Baseline and Motivation

For this memo, “`ODE+POLISH`” means the standard ODEPE pipeline where the algebraic/raw search produces a candidate population and `polish_solutions=true` declusters and polishes that set. The baseline was already strong on many systems, but bilby/AMIGO comparisons exposed a few recurring failure modes:

- the best polished solution was sometimes **not** the truth-closest polished solution,
- good basins could exist far down the raw fit ranking,
- some hard cases benefited from broader polishing, but naïve “polish more” policies were too brittle or too expensive,
- some families (`crauste`) looked like search/basin problems, while others (`cstr`) looked structurally different.

This drove a shift in objective:

- early: improve the **selected winner**
- later: improve **best-in-set / finalist coverage**
- always: keep an eye on **runtime**, but only after the quality signal was understood

## Baseline Reference Point

The standard comparison target throughout this work was the bilby benchmark’s saved `odepe_polish` result, not just `odepe_nopolish`. That distinction mattered. Many cases that looked bad against `odepe_nopolish` were already partly rescued by stock polish, so new methods needed to justify themselves against the stronger benchmark.

The bilby aggregate comparisons and saved case artifacts under:

- [`artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_support_budgets/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_support_budgets/summary.md)
- [`artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/summary.md)
- [`artifacts/diagnostics/cstr_crauste_deep_dive/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cstr_crauste_deep_dive/summary.md)

were the main evaluation sources.

## Major Algorithm Threads

### 1. Block Consensus / `block_v2_no_polish`

**Problem being solved**

The raw candidate ranking was not robust enough on hard cases. We wanted a second-stage selector that used cross-candidate support rather than trusting raw fit alone.

**Algorithm shape**

The block path grouped variables into blocks, rescored candidates on selected support points / support combos, assembled cross-block hypotheses, and chose the best no-polish assembled candidate. The key implementation entrypoint is:

- [`_assemble_block_consensus_report(...)`](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/block_consensus_v2.jl#L746)

High-level flow:

1. build candidate evidence over support points / multipoint combos,
2. decompose variables into blocks,
3. assemble cross-block hypotheses,
4. rescore hypotheses,
5. optionally polish later as a separate step.

**What it helped**

The block selector was often much better than weak raw baselines on cases where the raw fit winner was obviously wrong. In the `1e-4` support-budget sweep:

- `seir_2_1em4`: `polish_top_3_raw_by_fit` was `202.79%`, while `block_v2_no_polish_4x4` got `65.47%`, and `polish_best_block_budget` got `44.47%`
- `dc_motor_1_1em4`: top-3 polish exploded to `234163624869.34%`, while `block_v2_no_polish_4x4` stayed at `3.97%`

These results are in [`support_budgets/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_support_budgets/summary.md).

**What we learned**

- block consensus was useful as a **different seed source** and sometimes as a safer fallback than polishing a bad raw seed,
- but block alone was not a universal winner,
- and on some hard AMIGO-favored cases its no-polish winner was still poor.

**Current status**

Still active, but mostly as one input family into broader finalist/frontier logic.

### 2. Support-Budget Study

**Problem being solved**

It was unclear whether more support points / support combos materially improved block decisions, or whether we should just pay more time for larger witness sets.

**Experiment**

The overnight sweep compared:

- `block_v2_no_polish_4x4`
- `block_v2_no_polish_8x8`
- `block_v2_no_polish_12x12`

against `polish_top_3_raw_by_fit` and a “polish best block seed” follow-up.

Artifact:

- [`support_budgets/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_support_budgets/summary.md)

**Result**

On the tested 15-case `1e-4` slice:

- `8x8` vs `4x4`: winner changed on `0` cases
- `12x12` vs `8x8`: winner changed on `0` cases

The summary explicitly records zero winner changes and zero quality improvement from larger budgets.

**What we learned**

- on that slice, `4x4` was enough
- larger support budgets were not justified
- future work should spend effort on better seed handling, not on `8x8`/`12x12`

**Current status**

Settled for the tested regime: `4x4` is the practical budget.

### 3. Polish-After-Block Variants

**Problem being solved**

A good block seed sometimes looked promising, but we needed to know whether polishing the best block seed reliably improved quality.

**Algorithm shape**

`polish_block_v2_best` simply took the best no-polish block output and ran standard polish on it.

**What worked**

On some cases this was genuinely useful:

- `daisy_mamil3_4_1em4`: `block_v2_no_polish_4x4` was `1.47%`, `polish_best_block_budget` got `0.01%`
- `sirt_treatment_6_1em4`: `26.53%` dropped to `11.70%`

**What failed**

It was also brittle:

- `dc_motor_1_1em4` showed that polishing the wrong block seed could explode while the no-polish block result stayed good
- some block-selected seeds were simply not stable polish starts

**What we learned**

Block polishing is useful as an escalation on the right seed, but not as a trusted default on its own.

**Current status**

Still conceptually useful, but superseded by broader finalist/frontier logic.

### 4. Fixed-`Top K` Tryhard Polish

**Problem being solved**

The stock winner was often not the truth-close one. The first simple response was to polish more seeds:

- top `K` raw by fit
- top `K` block hypotheses
- merge and polish them all

**Algorithm shape**

This became the first tryhard benchmark driver. The early policy was essentially:

1. import `odepe_nopolish` raw pool from `result.csv`
2. build block hypotheses at `4x4`
3. take top distinct raw seeds and top distinct block seeds
4. merge and deduplicate
5. polish all
6. compare best polished result against benchmark `odepe_polish`

**What worked**

It demonstrated that extra breadth could beat benchmark polish on hard cases:

- `seir_7_1em4`: `odepe_polish` `647.61%` vs local best-in-set `573.36%`
- `fitzhugh_nagumo_2_1em4`: `3.62%` vs `1.48%`
- `sirt_treatment_7_1em4`: `2.96%` vs `0.02%`

**What failed**

The policy was obviously overtuned. `daisy_mamil4_6_1em4` exposed the problem:

- fixed top-`10` raw tryhard topped out at `4.63%`
- polishing all `119` imported raw seeds improved that to `0.77%`
- the good seed was raw fit-rank `100`
- benchmark `odepe_polish` still did slightly better at `0.53%`

This failure is summarized in [`2026-04-14_reasonable_polish_frontier.md`](/home/orebas/.julia/dev/ODEParameterEstimation/temp_plans/2026-04-14_reasonable_polish_frontier.md).

**What we learned**

- breadth matters
- fixed top-`K` by fit is brittle
- deeper seeds can matter enormously
- fit rank is a poor admission criterion

**Current status**

Superseded by the reasonable-frontier design.

### 5. Diversity-First Finalist Sets

**Problem being solved**

Even after polishing broader seed sets, the selected winner was often wrong because post-polish fit did not identify the truth-close solution.

**Algorithm shape**

Shift output from “one winner” to:

- `best_result` for compatibility
- `finalists` as the real product

This logic lives in:

- [`research_tryhard_finalists(...)`](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/benchmark_sweeps.jl#L1788)

The key change was conceptual:

1. polish a broader set,
2. cluster polished outputs into basins,
3. return basin representatives and membership counts,
4. evaluate success by **best-in-set** rather than ranked-best.

**What worked**

This solved an important scientific/product problem: if several polished solutions were effectively distinct basins, the system stopped pretending fit could reliably choose one.

Examples:

- `aircraft_pitch_6_1em4`: ranked-best `155.51%`, but best finalist in set `8.05%`
- `seir_7_1em4`: ranked-best `28351.97%`, but best finalist in set `238.72%`
- `boost_converter_3_1em4`: ranked-best `2814960.53%`, but best finalist in set `0.22%`

These case studies are in the tryhard case files under [`artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases).

**What we learned**

- the returned set was often good even when the ranked winner was terrible
- set coverage was a better benchmark target than fit-only winner quality

**Current status**

Still active. This was the conceptual turning point of the post-polish work.

### 6. Reasonable Frontier

**Problem being solved**

Fixed-rank tryhard still threw away important seed families too early. We needed something that preserved standard polish coverage while still allowing new generators to add diversity.

**Algorithm shape**

This design is captured in:

- [`2026-04-14_reasonable_polish_frontier.md`](/home/orebas/.julia/dev/ODEParameterEstimation/temp_plans/2026-04-14_reasonable_polish_frontier.md)
- [`_build_reasonable_tryhard_frontier(...)`](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/benchmark_sweeps.jl#L1252)

High-level flow:

1. reconstruct the standard-polish declustered baseline seed pool,
2. generate additive seeds from block / branch / synthesized paths,
3. reject only clearly unreasonable additive seeds,
4. preserve all baseline seeds,
5. admit additive seeds into a soft-capped frontier,
6. polish the full admitted frontier,
7. cluster polished outputs into basins.

**What worked**

This fixed the worst fixed-`K` regression:

- `daisy_mamil4_6_1em4` moved from `4.63%` under fixed top-`K` tryhard to `0.77%` under the baseline-preserved frontier

The case study shows:

- baseline-only finalists: `0.77%`
- additive-only finalists: `0.77%`
- reasonable frontier finalists: `0.77%`
- benchmark `odepe_polish`: `0.53%`

So the frontier did not fully beat benchmark polish there, but it fixed the major seed-coverage miss.

**What failed**

The frontier was not automatically monotone relative to its component seed families. `brusselator_5_1em4` exposed this:

- baseline-only best-in-set: `0.09%`
- additive-only best-in-set: `0.08%`
- merged frontier best-in-set: initially `0.13%`, later fixed down to `0.08%`

This revealed representative-selection and admission details that still mattered.

**What we learned**

- preserving the full baseline declustered pool was the right move
- additive seeds should augment baseline polish, not replace it
- runtime can balloon if the frontier is not controlled

**Current status**

Still active. This is the main current post-polish policy direction.

### 7. Post-Polish Dedup / Basin Clustering Rework

**Problem being solved**

Early finalist sets returned far too many “distinct” solutions. The issue was not just compute. It was that plain geometric dedup was a bad notion of “same answer.”

**Algorithm shape**

The main clustering logic lives in:

- [`_cluster_tryhard_finalists(...)`](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/benchmark_sweeps.jl#L1422)

The design evolved through several stages:

1. split **pre-polish** and **post-polish** dedup thresholds
2. stop hard-rejecting additive seeds just because their pre-polish fit was `Inf`
3. add trajectory-hybrid post-polish clustering:
   - primary merge check: observable trajectory distance
   - secondary merge check: spread-weighted / geometry-aware distance
   - geometry fallback when trajectory info was insufficient
4. add representative tie-breaks for non-finite / tied fit cases

**What worked**

The biggest success was `daisy_mamil4_6_1em4`:

- before the clustering rework, the frontier returned about `125` finalists
- after trajectory-hybrid clustering, it returned `29`
- best-in-set stayed `0.77%`

That is a genuine improvement in scientific usability, not just speed.

`brusselator_5_1em4` also improved:

- finalists dropped to `29`
- representative update counts became visible
- merged best-in-set stabilized at `0.08%`

**What failed**

Plain scalar geometry thresholds were too blunt. They could under-merge fake diversity and over-merge meaningful cross-family candidates. This is why the work moved toward trajectory-aware clustering instead of only tuning `0.001` vs `0.003`.

**What we learned**

- pre-polish dedup should stay conservative
- post-polish clustering needs a better equivalence notion than raw parameter geometry
- observable trajectory similarity is a more defensible basis for basin identity

**Current status**

Active, but still incomplete. Trajectory-hybrid clustering is the current best version.

### 8. Crauste / CSTR Diagnostic Pivot

**Problem being solved**

Not all hard cases were the same. We needed to know whether remaining gaps were mostly:

- finalizer / basin coverage problems, or
- search / structural / bounds problems

**Experiment**

The benchmark-faithful deep dive is in:

- [`artifacts/diagnostics/cstr_crauste_deep_dive/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cstr_crauste_deep_dive/summary.md)

**What we learned**

`cstr`:

- looks structurally different from the finalist/frontier problem
- only 1 observable for a 3-state system
- stock polish does not materially rescue it
- exported polished pools violate nominal bounds heavily
- likely next issues are observability / latent-state treatment / bounds enforcement

`crauste`:

- benchmark spec itself does not look bad
- clean-data ODEPE is already strong
- under noise, polish helps a lot but still leaves a large gap to AMIGO
- looks more like noisy search / basin quality than a bad problem spec

**Current status**

`crauste` remains a post-polish/finalizer target; `cstr` does not.

## Experiments Run and Main Conclusions

### Support-Budget Sweep

Artifact:

- [`artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_support_budgets/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_support_budgets/summary.md)

Conclusion:

- larger support budgets (`8x8`, `12x12`) produced no winner changes on the tested `1e-4` slice
- `4x4` was enough

### Tryhard / Finalist Benchmark

Artifact:

- [`artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/summary.md)

Conclusion:

- best-in-set / finalist coverage often beat benchmark `odepe_polish`
- ranked-best remained unreliable
- the frontier direction was justified, but runtime remained high

### CSTR / Crauste Deep Dive

Artifact:

- [`artifacts/diagnostics/cstr_crauste_deep_dive/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cstr_crauste_deep_dive/summary.md)

Conclusion:

- `crauste` still looks like a search/basin problem
- `cstr` looks like bounds/observability/identifiability, not a finalist-set problem

### Strict Shared-Search `crauste` Rerun

Purpose:

- answer the strongest question possible: does frontier beat stock on the same freshly rerun, bilby-faithful raw pool?

What happened:

- this was far too expensive for a development loop
- it effectively combined:
  - a full bilby-faithful raw rerun,
  - stock polish,
  - frontier additive generators,
  - merged-seed polishing
- it never produced a useful artifact locally

What it taught:

- this experiment shape is too expensive for iteration
- we need saved-pool comparisons for development, and only occasional full reruns

### Saved-Pool `crauste` Comparison

Purpose:

- compare stock polish vs frontier on the same saved `odepe_nopolish` pool, without rerunning the raw search

Status:

- in progress as of this memo
- the new driver adds:
  - explicit generator-stage timings
  - merged-seed caps
  - polish error / `maxiters` counts

This is the right near-term loop for `crauste`.

## Key Case Studies

### `daisy_mamil4_6_1em4`

Why it mattered:

- the clearest proof that fixed top-`K` was brittle

What it showed:

- benchmark `odepe_polish`: `0.53%`
- fixed top-`K` tryhard had previously topped out at `4.63%`
- baseline-preserved frontier recovered to `0.77%`
- trajectory-hybrid clustering reduced finalists from about `125` to `29` while keeping `0.77%`

Lesson:

- preserve baseline breadth
- do not trust fixed rank truncation
- better post-polish clustering matters

Source:

- [`daisy_mamil4_6_1em4/study.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases/daisy_mamil4_6_1em4/study.md)

### `brusselator_5_1em4`

Why it mattered:

- clean demonstration of additive-family usefulness and representative-selection issues

What it showed:

- benchmark `odepe_polish`: `6.23%`
- baseline-only finalists: `0.09%`
- additive-only finalists: `0.08%`
- merged frontier finalists: `0.08%`
- merged finalists reduced to `29`

Lesson:

- additive seeds can matter even when all fit values are `Inf`
- representative tie-break logic matters when fit is unusable
- this is the kind of case where finalist sets are obviously better than one winner

Source:

- [`brusselator_5_1em4/study.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases/brusselator_5_1em4/study.md)

### `seir_7_1em4`

Why it mattered:

- strongest example of raw fit being catastrophically misleading

What it showed:

- `odepe_nopolish`: `91870.57%`
- benchmark `odepe_polish`: `647.61%`
- frontier best finalist in set: `238.72%`
- frontier ranked best stayed awful at `28351.97%`

Lesson:

- finalist coverage can improve dramatically even when winner ranking remains poor
- “best-in-set” and “ranked-best” must be treated separately

Source:

- [`seir_7_1em4/study.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases/seir_7_1em4/study.md)

### `fitzhugh_nagumo_2_1em4`

Why it mattered:

- a hard AMIGO-favored case where broader polishing clearly helped

What it showed:

- benchmark `odepe_polish`: `3.62%`
- baseline-only finalists: `1.48%`
- additive-only finalists: `1.48%`
- frontier finalists: `1.48%`

Lesson:

- broader polishing can close a real benchmark gap
- this was not mainly a block-only win; the broader finalist logic mattered more than a specific seed family

Source:

- [`fitzhugh_nagumo_2_1em4/study.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases/fitzhugh_nagumo_2_1em4/study.md)

### `aircraft_pitch_6_1em4`

Why it mattered:

- clearest case where ranked-best was bad but best-in-set was strong

What it showed:

- benchmark `odepe_polish`: `586.42%`
- baseline-only finalists: ranked-best `311.51%`, best-in-set `8.05%`
- merged frontier best-in-set: `8.05%`

Lesson:

- post-polish winner ranking by fit can be wildly misleading
- even the baseline preserved pool alone can contain much better polished basins than the selected winner

Source:

- [`aircraft_pitch_6_1em4/study.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases/aircraft_pitch_6_1em4/study.md)

### `crauste_3_1em8`

Why it mattered:

- canonical hard benchmark target for the next phase

What it showed:

- benchmark `odepe_nopolish`: `342.216198` RMS relative error in stdout, selected RMSE `0.2923` in the deep-dive table
- benchmark `odepe_polish`: `2.919046` RMS relative error in stdout, selected RMSE `1.9784` in the deep-dive table
- AMIGO2 selected RMSE: `7.2761e-06`
- stock bilby runtimes:
  - `odepe_nopolish`: `5388.7598 s`
  - `odepe_polish`: `8360.2181 s`

Lesson:

- polish helps enormously compared with raw ODEPE
- but the remaining AMIGO gap is still large
- this is the right benchmark-faithful case for finalizer-vs-search diagnosis

Sources:

- [`cstr_crauste_deep_dive/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cstr_crauste_deep_dive/summary.md)
- [`odepe_nopolish/crauste_3_1em8/stdout.txt`](/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/crauste_3_1em8/stdout.txt)
- [`odepe_polish/crauste_3_1em8/stdout.txt`](/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/crauste_3_1em8/stdout.txt)

### `cstr_1_1em8`

Why it mattered:

- clearest example of a case that likely is **not** a frontier/finalist problem

What it showed:

- `odepe_nopolish`: `0.1834`
- `odepe_polish`: `0.1834`
- AMIGO2: `0.0253`
- exported ODEPE pools were heavily out-of-box

Lesson:

- polishing breadth is not the main issue
- next work needs to target bounds, observability, and latent-state treatment

Source:

- [`cstr_crauste_deep_dive/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/cstr_crauste_deep_dive/summary.md)

## Algorithm Sketches

### `block_v2_no_polish`

**Inputs**

- raw candidate population
- support point / support combo budget

**Steps**

1. build candidate evidence at support points and combos
2. decompose variables into blocks
3. assemble cross-block hypotheses
4. rescore hypotheses
5. return best no-polish assembled result

**Output**

- block report
- best assembled hypothesis / result

**Known weakness**

- can still choose the wrong seed family
- evidence build is expensive

### `polish_block_v2_best`

**Inputs**

- best no-polish block output

**Steps**

1. take best block seed
2. run standard polish
3. select polished result

**Output**

- polished block result

**Known weakness**

- unstable if block chooses a bad or fragile seed

### Pooled Tryhard Polish

**Inputs**

- imported raw candidates
- optional block hypotheses

**Steps**

1. pick top distinct raw seeds
2. pick top distinct block seeds
3. merge and deduplicate
4. polish all merged seeds
5. choose best polished result

**Output**

- pooled polished set

**Known weakness**

- fixed-`K` truncation was brittle and overtuned

### Diversity-First Finalists

**Inputs**

- polished seed population

**Steps**

1. cluster polished solutions into basins
2. keep basin representatives and membership counts
3. return `best_result` plus finalists

**Output**

- finalist report

**Known weakness**

- winner ranking remained poor if based on fit only

### Reasonable Frontier

**Inputs**

- baseline standard-polish declustered pool
- additive block / branch / synthesized seeds

**Steps**

1. preserve baseline seeds
2. conservatively filter additive seeds
3. admit additive seeds into a soft-capped frontier
4. polish the full frontier
5. cluster polished outputs

**Output**

- merged frontier finalists

**Known weakness**

- can still be runtime-heavy
- admission and representative details still matter

### Trajectory-Hybrid Post-Polish Clustering

**Inputs**

- polished frontier results
- observable trajectory signatures

**Steps**

1. compare polished results by observable trajectory distance
2. apply secondary spread-/geometry-aware distance
3. fall back to geometry where needed
4. update basin representative with non-fit tie-breaks when fit is useless

**Output**

- basin summaries
- final finalists

**Known weakness**

- still heuristic
- not yet a full sensitivity-aware equivalence notion

## What Worked

- `4x4` block support budget was enough on the tested slice; bigger support sets were wasted effort there.
- Preserving the full standard-polish baseline pool was the single most important correction to fixed-`K` tryhard.
- Returning finalists instead of trusting one polished winner was a major conceptual improvement.
- Trajectory-hybrid post-polish clustering reduced obviously excessive finalist counts without destroying best-in-set quality.
- Benchmark-faithful deep dives were useful for separating `crauste`-type and `cstr`-type failure modes.

## What Did Not Work

### Larger support budgets

Why it looked promising:

- more witness points should have improved scoring

Why it failed:

- on the measured slice, `4x4`, `8x8`, and `12x12` produced identical winners

What replaced it:

- keep `4x4`, spend effort elsewhere

### Fixed `top K raw + top K block`

Why it looked promising:

- simple way to broaden polishing

Why it failed:

- good seeds could live far down the fit ranking
- `daisy_mamil4_6_1em4` exposed a major miss

What replaced it:

- baseline-preserved frontier

### Fit-only post-polish ranking

Why it looked promising:

- stock polish already used fit, so it seemed natural to reuse it

Why it failed:

- many cases had nearly identical fit but wildly different truth error
- ranked-best was often much worse than best-in-set

What replaced it:

- finalist-set evaluation
- trajectory-aware clustering
- limited representative tie-break fixes

### Over-focusing on tiny numeric gains

Why it looked promising:

- cases like `brusselator_5_1em4` showed small merged-vs-additive gaps

Why it was de-emphasized:

- `0.13% -> 0.08%` mattered far less than getting finalist count from `125` to `29`
- some tiny gaps were representative-selection artifacts, not real search failures

What replaced it:

- prioritize structural fixes and robust set coverage

### Strict benchmark-faithful full reruns as the default dev loop

Why it looked promising:

- strongest possible test: same raw rerun, stock vs frontier

Why it failed:

- too expensive to iterate on
- fresh `crauste` reruns plus frontier generators blew up wall-clock dramatically

What replaced it:

- saved-pool same-search comparisons
- runtime instrumentation and merged-seed caps

### Plain geometric post-polish dedup

Why it looked promising:

- simple and cheap

Why it failed:

- returned too many fake “distinct” finalists
- could not distinguish low-sensitivity variation from genuinely different basins

What replaced it:

- trajectory-hybrid post-polish clustering

## Current Best Understanding

The current working stack is:

1. keep the standard-polish declustered baseline seed pool,
2. augment it with block / branch / synthesized additive seeds,
3. admit additive seeds into a reasonable frontier,
4. polish the frontier,
5. cluster polished outputs into basins using trajectory-hybrid logic,
6. judge quality by best-in-set / finalist coverage before trusting any single winner.

This stack has clearly improved hard-case coverage on several AMIGO-favored families:

- `seir`
- `fitzhugh_nagumo`
- `sirt_treatment`
- `brusselator`
- parts of `aircraft_pitch`

It also corrected some major design mistakes:

- fixed rank truncation
- over-trusting fit after polish
- using one plain geometric threshold as the entire notion of basin identity

But major issues remain:

- runtime is still high for broad frontier runs
- `crauste` still needs the same-pool stock-vs-frontier diagnosis
- `cstr` probably needs a different line of work entirely

## Open Questions

1. On `crauste_3_1em8`, does frontier beat stock on the same saved raw pool, and if so, which additive families justify their cost?
2. How much of the current runtime blow-up is generator-stage work versus per-seed polish versus repeated SI-template instantiation?
3. For `cstr`, is the next high-value intervention:
   - stricter bounds enforcement,
   - better latent-state handling,
   - or a benchmark-spec rethink?
4. When should the public surface explicitly return a finalist set instead of forcing a single winner?
5. Is the current trajectory-hybrid clustering enough, or do we eventually need a more sensitivity-aware basin equivalence?

## Notes on Current In-Progress Work

As of this memo, the next `crauste` experiment has already pivoted away from the failed strict full rerun and toward a cheaper saved-pool comparison with:

- frontier generator timing instrumentation,
- merged-seed caps,
- polish error / `maxiters` counters.

That is the right next experiment shape for development. The strict full rerun proved the benchmark-faithful question was valid, but not that it was a usable inner-loop workflow.

## 2026-04-21 Addendum: AMIGO Local-Polish Differences

The next meaningful gap to check after log-space was not another seed trick. It was local polish structure.

On the AMIGO side, the benchmark scripts are doing at least three things that differ materially from the current ODEPE polish path:

- global search with `eSS` before local finish,
- local finish in log-space over positive estimated variables,
- residual-vector nonlinear least squares via `nl2sol`, rather than a generic scalar SSE objective.

The benchmark evidence for the AMIGO local objective is explicit:

- [`amigo2_run/crauste_3_1em8/script.m`](/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/amigo2_run/crauste_3_1em8/script.m#L1568) sets `PEcost_type='lsq'`, `lsq_type='Q_I'`, `nlpsolver='eSS'`, and `local.solver='nl2sol'`
- [`amigo2_run/crauste_3_1em8/objf_nl2sol.m`](/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/amigo2_run/crauste_3_1em8/objf_nl2sol.m#L1) returns the residual vector `R`

By contrast, the current ODEPE polish path in [`_build_polish_context(...)`](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/parameter_estimation.jl#L1906) still builds a scalar simulation SSE objective, even when the selected optimizer is a Gauss-Newton / Levenberg-style method.

### Log-space ablation result

A research-only internal coordinate transform was added to polish:

- `:linear`
- `:log_positive`

This stays internal to the polish context and does not change the public `EstimationOptions` surface. The key implementation lives in:

- [`parameter_estimation.jl`](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/parameter_estimation.jl)
- [`generate_log_polish_ablation.jl`](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_log_polish_ablation.jl)

The first clean hard-case evidence was:

- [`artifacts/diagnostics/log_polish_ablation/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/log_polish_ablation/summary.md)

For `crauste_7_1em4`, on the same imported `odepe_nopolish` pool:

- saved `amigo2_run`: `19.62%`
- saved `odepe_polish`: `167.02%`
- scalar linear selected RMSE: `198638.81%`
- scalar linear best-in-set RMSE: `6445.99%`
- log-positive selected RMSE: `1859.55%`
- log-positive best-in-set RMSE: `310.30%`

That is still far from AMIGO, but it is much better than linear polish on the same pool. So log-space is a real part of the gap, not just a stylistic difference.

Earlier same-pool evidence on `sirt_treatment_0_1em4` also suggested that log-space can improve polish geometry/runtime even when quality is unchanged:

- linear and log tied in quality,
- log reduced runtime from about `101 s` to about `46 s`.

### Residual-vector ablation

The next research ablation is now prepared in:

- [`generate_residual_polish_ablation.jl`](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_residual_polish_ablation.jl)

This driver compares, on the same imported benchmark pool:

- scalar linear
- residual linear
- scalar log-positive
- residual log-positive

using a residual-vector `NonlinearLeastSquaresProblem` with `LevenbergMarquardt()` as the first proxy for the AMIGO `nl2sol` difference. This is intentionally narrower than a full AMIGO reproduction:

- it does not add global `eSS`,
- it does not try to clone `nl2sol`,
- it only isolates residual-vector least-squares structure on the same pool.

At this point the working hypothesis is:

1. global basin finding is still probably the largest AMIGO advantage,
2. log-space is already showing real value on positive-box cases,
3. residual-vector least squares is the next most meaningful local-polish difference to test before spending more time on ranking or seed-set tweaks.

## 2026-04-22 Addendum: Julia NLLS Solver Shootout

One important correction became clear during the residual-polish work: current `PolishLevenberg` / `PolishGaussNewton` are not fair tests of Julia NLLS solvers. In the main polish path they still run through a scalar `OptimizationProblem`, not a `NonlinearLeastSquaresProblem`. So poor behavior there does not, by itself, mean Julia-side LM/GN is intrinsically weak.

To steelman the residual-vector alternative, the research harness in:

- [`generate_residual_polish_ablation.jl`](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_residual_polish_ablation.jl)

was expanded into a same-pool NLLS solver shootout. The roster now includes:

- `LevenbergMarquardt()`
- `FastShortcutNLLSPolyalg()`
- `TrustRegion()`
- `LeastSquaresOptimJL(:lm)`
- `LeastSquaresOptimJL(:dogleg)`
- `FastLevenbergMarquardtJL()` when the backing package is available

The current environment does not have `FastLevenbergMarquardt.jl` installed, so that arm is expected to report `unsupported` rather than silently disappear.

The comparison basis stays:

- imported bilby `odepe_nopolish` pools,
- same candidate pool for every arm,
- `scalar + linear` and `scalar + log` as the baseline controls,
- residual-vector solvers tested in both linear and log-positive coordinates.

At this stage, the working local-polish picture is:

1. `log-space` is a real improvement,
2. naive residual-vector LM can help relative to bad scalar linear behavior on some hard cases,
3. but residual-vector LM has not beaten `scalar + log` on the cases tested so far,
4. so the remaining AMIGO gap is unlikely to be explained by “use residual vectors” alone.

### Shootout status

The shootout harness has now been hardened enough to make the solver comparison itself meaningful:

- `LevenbergMarquardt()` is now instantiated explicitly from `NonlinearSolve` instead of relying on the ambiguous exported name that collides with `LeastSquaresOptim`.
- The native `NonlinearSolve` NLLS arms are constructed explicitly with `AutoForwardDiff()`.
- `FastLevenbergMarquardtJL()` still reports `unsupported` in this environment because `FastLevenbergMarquardt.jl` is not installed in the project.

The first flushed control case is:

- [`artifacts/diagnostics/residual_polish_ablation/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/residual_polish_ablation/summary.md)

For `sirt_treatment_0_1em4` on the same imported pool:

- `scalar + log`: `0.01%`
- `LevenbergMarquardt() + log`: `1.22%`
- `TrustRegion() + log`: `0.01%`
- `LeastSquaresOptimJL(:lm) + log`: `0.01%`
- `LeastSquaresOptimJL(:dogleg) + log`: `0.01%`

So, on the easy control:

- true residual `LevenbergMarquardt()` is still worse than `scalar + log`,
- `TrustRegion()` and both `LeastSquaresOptimJL` variants match `scalar + log`,
- and they do so faster than the scalar baseline.

One solver remains unresolved:

- `FastShortcutNLLSPolyalg()` is still erroring through an Enzyme path even when constructed with `AutoForwardDiff()`.

So the current best read is:

1. the residual-vector alternative is worth testing seriously,
2. the strongest Julia-side candidates so far are `TrustRegion()` and `LeastSquaresOptimJL`,
3. and the remaining AMIGO gap still looks more like basin-finding / search quality than “Julia lacks a competent local least-squares solver.”

### Five-case shootout outcome

The full five-case same-pool shootout is now complete in:

- [`artifacts/diagnostics/residual_polish_ablation/summary.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/residual_polish_ablation/summary.md)

Final best-in-set results versus `scalar + log`:

- `LevenbergMarquardt()`: `0 better / 0 tie / 5 worse`
- `TrustRegion()`: `0 better / 2 tie / 3 worse`
- `LeastSquaresOptimJL(:lm)`: `1 better / 2 tie / 2 worse`
- `LeastSquaresOptimJL(:dogleg)`: `1 better / 2 tie / 2 worse`
- `FastShortcutNLLSPolyalg()`: unresolved, still failing through an Enzyme path
- `FastLevenbergMarquardtJL()`: unsupported in the current project environment

The main per-case lessons were:

- `sirt_treatment_0_1em4`: `scalar + log` remains optimal; `TrustRegion()` and both `LeastSquaresOptimJL` variants tie it and run faster.
- `crauste_7_1em4`: true residual solvers dramatically improve on scalar linear, but none beat `scalar + log`.
- `fitzhugh_nagumo_2_1em4`: `scalar + log`, `TrustRegion() + log`, and both `LeastSquaresOptimJL + log` variants all tie at the best value.
- `seir_4_1em4`: residual-vector solvers are substantially worse than `scalar + log`.
- `flexible_arm_0_1em4`: both `LeastSquaresOptimJL(:lm)` and `LeastSquaresOptimJL(:dogleg)` beat `scalar + log`, recovering `0.54%` versus `30.93%`.

So the residual-vector steelman result is:

1. a better Julia-side NLLS local solver can matter on some cases,
2. `LeastSquaresOptimJL` is the strongest local-solver candidate in this shootout,
3. `TrustRegion()` is respectable but not clearly stronger than `scalar + log`,
4. `LevenbergMarquardt()` is not competitive here,
5. and even the best residual solver result does not explain most of the AMIGO gap on the harder positive-box cases.

That pushes the current interpretation toward:

- keep `log-space` as a real local-polish improvement,
- consider `LeastSquaresOptimJL` as the strongest Julia-side residual local solver worth further use,
- and treat the remaining AMIGO advantage as primarily a search / basin-discovery problem rather than a simple local-solver deficiency.

### FastShortcut / FastLM follow-up

After the initial five-case shootout, I did a focused follow-up specifically on the two unresolved residual arms:

- `FastShortcutNLLSPolyalg()`
- `FastLevenbergMarquardtJL()`

Two concrete implementation changes were made for this follow-up:

1. `FastLevenbergMarquardt.jl` was added to the local project, so `FastLevenbergMarquardtJL()` is no longer merely “unsupported” due to a missing package.
2. The residual harness was reconfigured to be more favorable to both solvers:
   - `FastShortcutNLLSPolyalg()` is now constructed with:
     - `concrete_jac = true`
     - `autodiff = nothing`
     - `jvp_autodiff = AutoFiniteDiff()`
     - `vjp_autodiff = AutoFiniteDiff()`
   - `FastLevenbergMarquardtJL()` is now set up to use an explicit finite-difference Jacobian in the residual harness rather than the earlier no-Jacobian `AutoForwardDiff()` path.

The important current diagnosis is:

- `FastLevenbergMarquardtJL()` looks like a **harness-configuration problem**, not a fundamental Julia-wrapper failure.
  - It works on simple standalone `NonlinearLeastSquaresProblem` tests.
  - The remaining issue is getting a clean benchmark-case result through the shared residual harness with the more favorable explicit-Jacobian setup.
- `FastShortcutNLLSPolyalg()` still looks like a **deeper package-path issue**.
  - Even with an explicit finite-difference Jacobian and finite-difference `jvp` / `vjp` overrides, the flushed benchmark artifact is still hitting an `EnzymeMutabilityException`.
  - The source confirms that `FastShortcutNLLSPolyalg()` is a polyalgorithm over `GaussNewton`, `TrustRegion`, and `LevenbergMarquardt`, so there are more internal derivative-selection paths than in the simpler single-solver wrappers.

So the follow-up status is:

1. `FastLMJL` is likely salvageable.
2. `FastShortcut` is still unresolved and is increasingly likely to require a package-level workaround or upstream fix rather than a small harness tweak.

### Explicit ForwardDiff-Jacobian Cleanup

The residual harness has now been cleaned up further so that the benchmark shootout no longer relies on finite-difference Jacobians in its main path.

Current residual-harness policy:

- attach an explicit in-place `ForwardDiff` Jacobian to the `NonlinearFunction`
- keep both coordinate systems:
  - `:linear`
  - `:log_positive`
- use that attached Jacobian for all serious residual arms

This matters because the earlier “residual solver” comparisons were partly confounded by solver-specific derivative fallbacks.

The current solver-specific status is:

- `LevenbergMarquardt()`
  - runs cleanly with the attached ForwardDiff Jacobian
  - still loses badly to `scalar + log` on the easy control
- `TrustRegion()`
  - runs cleanly with the attached ForwardDiff Jacobian
  - remains a credible baseline residual solver
- `LeastSquaresOptimJL(:lm)` / `LeastSquaresOptimJL(:dogleg)`
  - now run cleanly when configured with `autodiff = nothing`, letting the wrapper use the attached Jacobian instead of trying to choose its own Jacobian backend
- `FastLevenbergMarquardt`
  - the `NonlinearSolve.FastLevenbergMarquardtJL()` wrapper still proved brittle in the benchmark harness
  - but the underlying package solver is now working through a direct `FastLevenbergMarquardt.lmsolve!` call when given residual/jacobian callbacks that return the mutated arrays
- `FastShortcutNLLSPolyalg()`
  - still fails on the real ODE residual problems with an `EnzymeMutabilityException`, even though a toy explicit-Jacobian probe now succeeds

Two concrete validation points from the cleanup work:

- the explicit-Jacobian toy probe at
  [`fast_nlls_forwarddiff_probe.md`](/home/orebas/.julia/dev/ODEParameterEstimation/artifacts/diagnostics/residual_polish_ablation/fast_nlls_forwarddiff_probe.md)
  shows that:
  - `FastShortcutNLLSPolyalg()`
  - `FastLevenbergMarquardtJL()`
  - `TrustRegion()`
  - `LevenbergMarquardt()`
  all solve a simple explicit-Jacobian NLLS problem successfully
- on the real `sirt_treatment_0_1em4` benchmark residual path:
  - `LeastSquaresOptimJL(:lm)` now runs cleanly with best benchmark RMSE `7.0667e-05`
  - `LeastSquaresOptimJL(:dogleg)` now runs cleanly with best benchmark RMSE `7.0667e-05`
  - direct `FastLevenbergMarquardt.lmsolve!` now runs cleanly with best benchmark RMSE `7.0667e-05`
  - `FastShortcutNLLSPolyalg()` still fails on this same case with an Enzyme mutability error

So the updated conclusion is tighter than the earlier “FastLM likely salvageable” note:

1. `LeastSquaresOptimJL` is clean and benchmark-usable under the explicit ForwardDiff Jacobian path.
2. direct `FastLevenbergMarquardt` is also clean and benchmark-usable under that same path.
3. `FastShortcut` is now the only residual solver in this roster that still fails after an explicit-Jacobian cleanup, and should be treated as broken for this workflow unless an upstream/package-level workaround is identified.

### Clarification: Differential Reference vs Saved `odepe_polish` vs Local Ablations

One source of confusion in the later solver experiments is that three different comparison objects are in play:

1. The benchmark differential reference in
   [AMIGO2_vs_ODEPE_differential_reference.md](/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/analysis_results/AMIGO2_vs_ODEPE_differential_reference.md)
   compares `amigo2_run` against saved `odepe_nopolish`.
2. The saved `odepe_polish` numbers in the benchmark analysis are historical benchmark artifacts from the bilby run.
3. The local residual/log ablations are current-checkout experiments that import the saved `odepe_nopolish/result.csv` pool and then run current local polish variants on that imported pool.

So when the solver-shootout summaries show:
- a local `scalar + log` or residual result, and
- a `saved odepe_polish` reference,

those are not outputs of the same code path. The saved `odepe_polish` number is a reference target, not the thing being rerun locally.

Two concrete consequences:

- `flexible_arm_0_1em4`
  - local same-pool ablations start from the saved `odepe_nopolish` export (`62` rows)
  - saved `odepe_polish` has a larger different export (`143` rows)
  - so the local same-pool solver shootout is a pool-limited experiment, not an apples-to-apples rerun of saved `odepe_polish`
- `brusselator_5_1em4`
  - the local scalar `Inf` row in the residual-polish summary was a harness/reporting bug (`_best_fit_raw_candidate(::Vector{Any})`), not a real scalar result
  - separately, the saved `odepe_nopolish/result.csv` and saved `odepe_polish/result.csv` are byte-identical even though the benchmark comparison tables report different RMSEs (`0.34%` vs `0.05%`), which means the comparison-table selection is not explained purely by the exported per-case result pool

### Follow-up Audit: `flexible_arm` and `brusselator`

Two concrete follow-up checks tightened the picture:

1. The scalar harness bug in the local ablation was real and local.
   - The fix was to normalize `analyzed_candidates` back to `Vector{ParameterEstimationResult}` in
     [generate_log_polish_ablation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_log_polish_ablation.jl)
     and
     [generate_residual_polish_ablation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_residual_polish_ablation.jl)
     before calling `_best_fit_raw_candidate(...)`.
   - The old `Inf` scalar row on `brusselator_5_1em4` should therefore be read as a reporting bug, not a scalar-polish result.

2. `flexible_arm_0_1em4` turned out to be more subtle than “the good basin is absent from the imported pool.”
   - Benchmark-selected saved rows:
     - `odepe_nopolish`: `7.50%`
     - `odepe_polish`: `3.60%`
     - `amigo2_run`: `0.54%`
   - Imported-pool stage audit:
     - best imported `odepe_nopolish` row: `6.62%`
     - benchmark-selected `odepe_nopolish` row survives import at row `27`
     - best imported row fit error: `22356.53`
     - best imported row fit rank: `34 / 62`
     - imported candidates with `err < MAX_ERROR_THRESHOLD`: `2`
     - best analyzed-pre-polish row: `32.11%`
   - The local same-pool solver shootout only reached:
     - `scalar linear`: `32.64%`
     - `scalar log`: `30.93%`
     - best residual result: `18.75%` (`LeastSquaresOptimJL(:lm)` in log-space)

This narrows the local same-pool `flexible_arm` failure substantially. The imported `odepe_nopolish` pool already contains materially better rows than the downstream ablation preserved, and the primary loss happens in `analyze_estimation_result(...)` at [analysis_utils.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/analysis_utils.jl#L249). Because this case has `2` candidates with `err < MAX_ERROR_THRESHOLD`, analysis keeps only those fit-good rows and discards the truth-better imported rows before polish. So the main culprit here is the fit-gated analysis/selection stage, not the local polish solver.

`brusselator_5_1em4` shows the opposite flavor of mismatch:

- benchmark-selected saved rows:
  - `odepe_nopolish`: `0.34%`
  - `odepe_polish`: `0.05%`
- but the two exported per-case CSVs are byte-identical (`123` rows each)
- recomputed best benchmark RMSE over those exported pools gives:
  - exported `odepe_nopolish`: `1.56%`
  - exported `odepe_polish`: `0.00035%`

So for `brusselator`, the mismatch is not just the local scalar harness bug. The benchmark comparison table and the exported per-case pools are not describing the same selected object in any simple way.

### Bounded Residual Follow-Up

After the ungated solver sweep, the next obvious fairness gap was bounds. The residual-vector harness was still only:

- clamping the initial seed to the benchmark box, then
- solving an unconstrained residual problem in either `original-space` or `log-space`.

That meant the earlier residual comparisons were still weaker than the scalar bounded baseline on one important axis: true box handling.

The bounded follow-up was intentionally narrow:

- keep the same imported bilby `odepe_nopolish` pools,
- keep the same ungated analysis mode,
- keep the same `original-space` / `log-space` coordinate options,
- add real bounds only where the installed solver API already supports them cleanly,
- and write new results to a separate artifact root instead of overwriting the ungated baseline.

Two source checks mattered:

1. `FastLevenbergMarquardt.jl` really does support bounds.
   - The installed source in
     [`~/.julia/packages/FastLevenbergMarquardt/.../src/lm.jl`]( /home/orebas/.julia/packages/FastLevenbergMarquardt/qAte0/src/lm.jl )
     accepts `lb` and `ub` directly and clamps / restricts steps against those bounds.
2. `LeastSquaresOptim.jl` also supports bounds.
   - The installed README and source expose `lower` / `upper` arguments, and the package tests include explicit bounded solves.

The residual harness was updated accordingly in
[generate_residual_polish_ablation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_residual_polish_ablation.jl):

- added bounded solver variants for:
  - direct `FastLevenbergMarquardt.lmsolve!`
  - direct `LeastSquaresOptim` `LevenbergMarquardt`
  - direct `LeastSquaresOptim` `Dogleg`
- threaded a `bounds_mode` flag through the residual-polish path
- when `bounds_mode == :bounded`, the harness now passes:
  - `ctx.internal_lb`
  - `ctx.internal_ub`
  to the solver
- in `log-space`, that means the bounded solver acts on the internal transformed box, not just on positivity by parameterization

The other residual solvers were deliberately left unchanged:

- `NonlinearSolve.LevenbergMarquardt`
- `NonlinearSolve.TrustRegion`
- `FastShortcutNLLSPolyalg`

because there is still no equally clean, documented bounded NLLS path for them in the current harness.

At the time of writing this memo update, the bounded residual sweeps were still running. So the engineering state is:

- the bounded residual feature work is implemented,
- the unbounded ungated artifact remains the baseline reference,
- and the next interpretation step depends on the bounded follow-up results:
  - if bounded `FastLM` or bounded direct `LeastSquaresOptim` improves materially on the hard positive-box cases, then the earlier residual comparisons were still unfairly underestimating those solvers
  - if bounded and unbounded results are close, the remaining AMIGO gap should still be read as mostly search / pool / winner-selection rather than missing local box constraints

### Log-Space L2 Regularization Sweep

A research-only regularization branch is now implemented in the benchmark harnesses.

Scope:

- no public API change
- no change to the current package default
- log-space only
- small `L2` shrinkage toward `x = 1`, i.e. toward `z = log(x) = 0`

The scalar and residual paths are handled differently so that the objective remains coherent:

- scalar log-space polish:
  - optimize `RSS(x) + λ ||z||²`
  - implemented by wrapping the scalar research polish objective in
    [generate_log_polish_ablation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_log_polish_ablation.jl)
- residual log-space polish:
  - augment the residual vector with `sqrt(λ) * z`
  - so the induced scalar objective is exactly `||r(z)||² + λ ||z||²`
  - implemented in
    [generate_residual_polish_ablation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_residual_polish_ablation.jl)

The dedicated sweep driver is:

- [generate_local_polish_regularization_sweep.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_local_polish_regularization_sweep.jl)

Design choices:

- suite: the same hard positive-box `1e-4` suite used for local-polish standardization
- methods:
  - scalar log-space
  - bounded `LeastSquaresOptim` LM log-space
  - bounded `FastLevenbergMarquardt` log-space
- default lambda grid:
  - `0`
  - `1e-4`
  - `1e-3`
  - `1e-2`
  - `1e-1`
- research analysis mode:
  - `ungated`

The regularization sweep writes its own separate artifact root and supports case/lambda filtering for smoke runs. The immediate question for that branch is narrow:

- do small `L2` penalties help the shortlisted log-space polishers reach better oracle-quality basins on the hard suite, or do they mostly just shrink parameters without improving benchmark RMSE?
