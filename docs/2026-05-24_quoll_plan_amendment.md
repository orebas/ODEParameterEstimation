# Quoll Plan Amendment

Date: 2026-05-24

Authors: cluster-Claude, Codex, Oren

Status: Live Quoll execution plan. This document supersedes conflicting parts
of `docs/2026-05-25_quoll_benchmark_handoff_spec.md`.

## Settled Decisions

1. **Wallaby broad, Quoll focused.** Wallaby remains the broad benchmark. Quoll
   is a focused branch-stress experiment plus offline Wallaby analysis. The
   proposed 5000-cell Quoll Main rerun is dropped.
2. **Rank strategy.** Quoll pins `rank_strategy = :sat_neg1_err` (S2) in PEB
   templates and manifests. `:err_only` and `:sat_err` are offline Wallaby
   ablations, not headline defaults.
3. **Rank ablation acceptance criterion.** S2 is displaced only if another
   strategy improves the primary Wallaby ODEPE Best-of-branches metric by at
   least 2 percentage points overall, has no noise-level regression larger than
   1 percentage point, does not regress M>1 branch-aware metrics, avoids a
   scientifically embarrassing severe-regression tail, and preserves or
   improves both polish and nopolish unless the headline explicitly narrows to
   one.
4. **Branch-diversity selection.** `branch_diversity_selection` is ablated
   before being pinned for Quoll. The chosen value must be explicit in the PEB
   template and manifest.
5. **AAA diagnostic.** The diagnostic is ODEPE with `InterpolatorAAAD`, not the
   legacy PE runner. It must set `auto_filter_interpolators = false` so noisy
   cells do not silently fall back to `InterpolatorAAADGPR`.
6. **Minimal-GP ablation.** `odepe_minimal_gp` is useful supporting evidence but
   does not block branch-stress smoke, pilot, or full runs. Smoke
   `shooting_points = 0` and `shooting_points = 1` before freezing the template.
7. **AMIGO2.** AMIGO2 stays in the Paper 1 main chart. The action item is a
   baseline-fairness memo, not replacement by SciML.
8. **Branch metadata.** Branch semantics live in a sidecar
   `config/branch_metadata.json`, separate from `config/systems.json`, and are
   consumed only by post-hoc analysis.
9. **Postprocessors first.** Branch-aware postprocessors, manifest capture, and
   pinned knobs must exist before cluster spend.

## Variant Keys

Accepted PEB estimator keys:

- `odepe_aaa_polish`
- `odepe_aaa_nopolish`
- `odepe_minimal_gp`

The AAA variants mirror Quoll default ODEPE polish/nopolish settings except for
the interpolator:

```julia
EstimationOptions(
    interpolator = InterpolatorAAAD,
    interpolators = [InterpolatorAAAD],
    auto_filter_interpolators = false,
    rank_strategy = :sat_neg1_err,
    branch_top_k = 20,
    branch_diversity_selection = pinned_after_ablation,
    algebraic_multiplicity = nothing,
    use_si_template = true,
    auto_handle_transcendentals = true,
    flow = FlowStandard,
)
```

The minimal-GP variant is an ODEPE ablation with one GP interpolator and the
robust pipeline disabled:

```julia
EstimationOptions(
    interpolator = InterpolatorAGPRobust,
    interpolators = [InterpolatorAGPRobust],
    use_multipoint = false,
    shooting_warp = false,
    use_parameter_homotopy = false,
    polish_solutions = false,
    polish_solver_solutions = false,
    branch_diversity_selection = false,
    use_si_template = true,
    auto_handle_transcendentals = true,
    flow = FlowStandard,
    algebraic_multiplicity = nothing,
    branch_top_k = 20,
    rank_strategy = :sat_neg1_err,
    branch_detection = true,
)
```

Smoke both `shooting_points = 0` and `shooting_points = 1`; pin the less
pathological setting before large runs.

## Branch Metadata Sidecar

`config/branch_metadata.json` should have this shape:

```json
{
  "_meta": {
    "schema_version": 1,
    "created_from_odepe_sha": "<filled at generation time>",
    "notes": "Used only by post-hoc branch analysis, never estimator input"
  },
  "latent_subpopulation_branch": {
    "algebraic_multiplicity": 6,
    "physical_multiplicity_positive_bounds": 6,
    "branch_orbit": {
      "type": "label_permutation",
      "permuted_groups": [
        ["a1", "a2", "a3"],
        ["b1", "b2", "b3"],
        ["I1", "I2", "I3"]
      ],
      "fixed": ["S", "R"]
    }
  },
  "receptor_subtype_binding_branch": {
    "algebraic_multiplicity": 2,
    "physical_multiplicity_positive_bounds": 2,
    "branch_orbit": {
      "type": "involution",
      "swap_pairs": [
        ["R1tot", "R2tot"],
        ["kon1", "kon2"],
        ["koff1", "koff2"],
        ["Ca", "Cb"]
      ],
      "fixed": ["L"]
    }
  },
  "latent_subpopulation_observed_control": {
    "algebraic_multiplicity": 1,
    "physical_multiplicity_positive_bounds": 1,
    "branch_orbit": null
  },
  "receptor_subtype_binding_observed_control": {
    "algebraic_multiplicity": 1,
    "physical_multiplicity_positive_bounds": 1,
    "branch_orbit": null
  },
  "daisy_mamil4": {
    "algebraic_multiplicity": 2,
    "physical_multiplicity_positive_bounds": 2,
    "branch_orbit": null
  },
  "seir": {
    "algebraic_multiplicity": 2,
    "physical_multiplicity_positive_bounds": 2,
    "branch_orbit": null
  },
  "slow_fast": {
    "algebraic_multiplicity": 2,
    "physical_multiplicity_positive_bounds": 1,
    "branch_orbit": null
  },
  "biohydrogenation": {
    "algebraic_multiplicity": 2,
    "physical_multiplicity_positive_bounds": 1,
    "branch_orbit": null
  }
}
```

`branch_orbit = null` means analysis falls back to geometric clustering in
identifiable parameter space. This is acceptable for the Wallaby retrofit; the
new branch-stress systems carry the explicit orbit evidence.

The branch-orbit hash should be computed from canonical JSON, for example
`json.dumps(branch_orbit, sort_keys=True, separators=(',', ':'))`.

## Manifest Additions

Capture these fields for Quoll and branch-related runs:

- `algebraic_multiplicity_source` (`auto`, `catalog`, or `explicit`)
- `branch_orbit_definition_hash`
- `rank_strategy`
- `branch_diversity_selection`
- `branch_diversity_eps`
- `branch_top_k`
- ODEPE git SHA and dirty status
- PEB git SHA and dirty status
- `julia_odepe` manifest SHA256
- generated template hashes

## Baseline Fairness Memo

For each method, record:

- estimator key and exact template/script;
- software version, git SHA, package manifest hash, and runtime environment;
- input data, observables, time grid, and noise level;
- estimated variables, fixed variables, excluded unidentifiable quantities, and
  transformations;
- bounds/search domain and their source;
- objective function, weighting, and failed-simulation handling;
- restart, population, iteration, wall-time, and CPU budgets;
- stopping criteria and failure criteria;
- initialization policy;
- postprocessing/polishing policy;
- output cardinality;
- tuning effort and whether settings were chosen before seeing results;
- known caveats.

AMIGO2 is protocol-clean if those choices are explicit and defensible. It need
not match ODEPE structurally; it must be compared transparently.

## Sequencing

No cluster spend until:

1. Wallaby branch-occupancy postprocessor exists.
2. Rank-strategy offline ablation exists.
3. Branch-diversity ablation is run or scheduled as a Quoll smoke artifact.
4. Naive-all-parameter supplemental table exists.
5. Baseline-fairness memo skeleton exists.
6. Shared branch classifier exists.
7. PEB templates pin rank, branch, top-K, and M-policy knobs.
8. Quoll branch systems and sidecar metadata are represented in PEB.

Then run:

1. Quoll smoke.
2. Quoll branch pilot.
3. Quoll branch full.
4. AAA diagnostic and minimal-GP variants as supporting ablations, without
   blocking the branch-stress sequence.
