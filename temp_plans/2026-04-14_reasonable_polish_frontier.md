# Reasonable Polish Frontier

## Summary

Near-term direction:

- keep the current standard-polish candidate set as the baseline,
- add new candidate families from the newer research paths,
- reject only clearly unreasonable additive seeds,
- polish the combined distinct set,
- cluster the polished results into basins,
- return finalists rather than forcing a single winner too early.

This is deliberately **not** a fixed-`top K` strategy. It is also deliberately **not** a strict compute-budget strategy yet. The goal is to be close to Pareto-better than `odepe_polish` and the current tryhard paths, with extra runtime as the main tradeoff.

## Why This Direction

Recent tryhard experiments showed:

- fixed `top K by fit` is brittle,
- post-polish fit is a poor single-winner selector,
- breadth matters,
- the current fixed-rank policies are overtuned and unlikely to scale cleanly.

The `daisy_mamil4_6_1em4` case is the clearest example:

- current tryhard raw breadth (`top 10` distinct by fit) topped out at `4.63%` combined RMSE,
- polishing all `119` distinct imported raw seeds improved that to `0.77%`,
- the winning imported raw seed was fit-rank `100`, not remotely near the top by fit,
- benchmark `odepe_polish` still did slightly better at `0.53%`.

That is a strong argument against more `top 5 / top 10 / top 20` tuning.

## Design Principle

The new path should be an **augmentation** of standard polish, not a replacement for it.

Starting invariant:

- anything that standard `polish_solutions=true` would polish after the existing declustering should remain in the pool,
- except exact or near-exact duplicates under the existing seed-distance rule.

New research-generated candidates may add coverage, but they should not force us to throw away baseline seeds just because they rank better under some heuristic.

This is the simplest way to avoid obvious regressions like:

- standard polish had the right basin,
- the fancy selector discarded the seed family that would have reached it.

## Candidate Sources

The candidate pool for polishing should be built from multiple sources:

1. baseline declustered raw seeds
2. branch/block/synthesized/generated seeds
3. optional consensus winners or family/block representatives
4. optional per-source medoids when a generator produces many nearby variants

The important shift is:

- do not pre-commit to a tiny fixed count from any one source,
- and do not let fit-only ranking dominate seed admission.

## Reasonable Frontier

The combined pre-polish seed set should be filtered into a **reasonable frontier**.

This frontier is not a winner ranking. It is an admission rule for which seeds deserve polish.

### Always keep

- the baseline declustered standard-polish seeds

### Additive seeds should earn entry by

- distinctness from seeds already kept
- non-pathological numeric status
- at least one signal of plausibility

### Cheap rejection rules for additive seeds

Reject additive seeds if they are clearly hopeless:

- non-finite values
- gross bound violations before clamping
- duplicate of an already kept seed
- catastrophic objective values several orders of magnitude outside the raw pool
- clearly pathological equation/support scores

These filters should be intentionally conservative. The point is to remove garbage, not to recreate a brittle ranking policy.

### Cheap admission credits for additive seeds

Keep additive seeds when they are meaningfully different and have some evidence behind them:

- distinct seed geometry
- support/equation score is not terrible
- comes from a different generator family
- appears in more than one source route
- likely opens a new basin, not just a small variant of an existing seed

## Polishing Policy

Near-term policy:

- polish the full reasonable frontier
- do not over-optimize the count yet
- monitor how much larger it is than standard polish

Practical target:

- standard polish count plus a moderate additive margin
- something like `+25%` to `+50%` is a good mental model for now
- `2x` should be treated as an upper warning zone, not a design goal

The key point is:

- if standard polish would have handled `N` distinct seeds,
- and the new generators produce another `M` plausible, distinct seeds,
- we should prefer to polish `N + M` rather than invent a brittle rule that discards `M` too early.

## Post-Polish Handling

After polishing:

1. cluster polished results into basins
2. keep basin representatives and basin membership counts
3. return finalists

The primary output should be:

- `best_result` for compatibility
- `finalists`
- basin metadata

The actual success criterion should be:

- is the good solution in the returned set?

not:

- did a fit-only single winner happen to be ranked first?

## Benchmark Objective

The main benchmark objective for this path should be:

- best-in-set quality versus `odepe_polish`

Secondary diagnostics:

- finalist-set coverage
- number of polished seeds
- number of discovered basins
- fraction of finalists supported by multiple seed families

This is a better fit for the current evidence than more single-winner tuning.

## Near-Term Implementation Direction

1. Reconstruct the standard-polish declustered seed set as the base pool.
2. Add research-generated seeds from block/branch/synth paths.
3. Apply conservative additive filtering only to the new seeds.
4. Polish the combined distinct frontier.
5. Cluster polished outputs into basins.
6. Return finalists and compare best-in-set against `odepe_polish`.

## Longer-Term Direction

Longer term, this should probably move toward an explicit compute-budget or saturation rule:

- stop when new seeds no longer produce new basins,
- or when marginal best-in-set improvement stalls.

But that is not the immediate need.

Immediate need:

- stop using brittle fixed-rank truncation,
- preserve baseline standard-polish coverage,
- let new candidate generators add diversity rather than replace existing breadth.
