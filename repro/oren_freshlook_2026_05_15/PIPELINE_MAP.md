# Current default ODEPE pipeline — verified flow map

This is the actual sequence of operations when a user calls
`analyze_parameter_estimation_problem(pep, opts)` with default
`EstimationOptions()` as of commit `823cdeb` (2026-05-15 main).

Each stage lists:
- **Where called** — the orchestrator site
- **Where implemented** — the logic
- **Gated by** — relevant default options and their values
- **What it does** — one-sentence description

File paths are relative to `~/.julia/dev/ODEParameterEstimation/`.

---

## Stage 0 — Entry: `analyze_parameter_estimation_problem`

`src/core/analysis_utils.jl:696+`. Top-level orchestrator. Branches into
the FlowStandard (default) or FlowDirectOpt path. Calls
`transform_pep_for_estimation` first (Stage 1).

---

## Stage 1 — Transcendental auto-transformation

- **Where called**: `analysis_utils.jl:696–702`
- **Where implemented**: `src/core/transcendental_utils.jl::transform_pep_for_estimation`
- **Gated by**: `opts.auto_handle_transcendentals = true` (default)
- **What it does**: Detects `sin(c·t)`, `cos(c·t)`, `exp(c·t)`, `log(c·t)`
  expressions and substitutes auxiliary `_trfn_*` state variables to keep
  the system polynomial-friendly for SI/HC.

## Stage 2 — Workflow selection

- **Where called**: `analysis_utils.jl:715–729`
- **Gated by**: `opts.flow = FlowStandard` (default) →
  `optimized_multishot_parameter_estimation`. Alternative
  `FlowDirectOpt` skips algebra and goes straight to BFGS.

## Stage 3 — Identifiability analysis (SI setup)

- **Where called**: `optimized_multishot_estimation.jl:1280–1286`
- **Where implemented**: `src/core/si_equation_builder.jl::setup_identifiability`
- **Gated by**: `opts.use_si_template = true` (default)
- **What it does**: Runs SIAN once, shared across all interpolators and
  shooting points. Computes which states/parameters are structurally
  identifiable, picks the `good_deriv_level` (how many derivatives the
  template needs), and produces `numerical_advisory`.

## Stage 4 — SI template construction

- **Where called**: `optimized_multishot_estimation.jl:1326–1357`
- **Where implemented**: `parameter_estimation.jl:641–707::prepare_si_template_with_structural_fix`
- **Gated by**: `opts.use_si_template = true`
- **What it does**: Builds the polynomial template once (squared via rank
  trimming, with `structural_fix_set` pegging non-identifiable variables
  to canonical values). Stored on disk if `opts.save_system = true`.

> This is the "peg the unidentifiable directions" step we discussed.
> Continuous non-id (per SIAN) gets a value substituted; the remaining
> system is locally identifiable. **Note**: the pegging happens here, in
> the *algebraic* problem. Numerical ridges that aren't caught by SIAN
> won't be pegged at this stage.

## Stage 5 — Shooting point selection

- **Where called**: `optimized_multishot_estimation.jl:1396–1410`
- **Defaults**: `opts.shooting_points = 12`, `opts.shooting_warp = true`,
  `opts.shooting_warp_beta = 3.0`
- **What it does**: Picks 12 time points from the dataset, exponentially
  warped toward t=0 (where observability tends to be highest).

## Stage 6 — Interpolation loop (multi-method)

- **Where called**: `optimized_multishot_estimation.jl:1454–1929`
- **Default interpolator portfolio**: `[InterpolatorAGPRobust,
  InterpolatorAGPRobustRQ, InterpolatorS3AdaptSE, ..., InterpolatorAAADGPR, ...]`
  (~9 methods, in `opts.interpolators`)
- **Auto-filter**: `opts.auto_filter_interpolators = true` strips AAA
  methods if noise σ̂ > 1e-4 (empirically catastrophic there)
- **What it does**: For each interpolator method, fits the data and runs
  Stages 7–9 below to produce a candidate pool. All pools merge.

## Stage 7 — HC.jl polynomial solving

- **Where called**: `optimized_multishot_estimation.jl:1484–1696` (parameter homotopy path) or `1702–1803` (single-point path)
- **Where implemented**: `src/core/homotopy_continuation.jl`
- **Gated by**: `opts.use_parameter_homotopy = true` AND `opts.shooting_points ≥ 3` (default true) → `solve_with_hc_parameterized`. Otherwise `solve_with_hc` runs per-point.
- **What it does**: Instantiates the SI template's "data variables" with derivative values at the 12 shooting points, solves the resulting polynomial system via HC.jl. Parameter homotopy tracks solutions across the 12 points; single-point solves each independently.

> **The "truncation introduces spurious solutions" concern lives here.**
> The system fed to HC.jl is the SI template post-rank-trimming, which
> has equations dropped for squareness. Truncation can introduce roots
> that aren't roots of the full overdetermined system. HC returns all
> complex solutions of the truncated system — we filter to real later but
> the spurious-root contamination stays.

## Stage 8 — Solver-output polish

- **Where called**: `optimized_multishot_estimation.jl:1626–1674`
- **Gated by**: `opts.polish_solver_solutions = true` (default)
- **What it does**: Fast Levenberg-Marquardt refinement on each raw HC
  solution before downstream stages. Improves numerical conditioning of
  candidates but doesn't touch ODE integration yet.

## Stage 9 — Multi-point template solving

- **Where called**: `optimized_multishot_estimation.jl:1809–1899`
- **Gated by**: `opts.use_multipoint = true` (default), `opts.multipoint_n_points = 2`, `opts.multipoint_max_pairs = 20`
- **Where implemented**: `src/core/multipoint_template.jl`
- **What it does**: Builds larger combined-polynomial systems from
  N-tuples of shooting points (default 2-tuples, capped at 20 pairs),
  solves via HC, tags solutions with `provenance.source_type = :multipoint`.

## Stage 10 — Algebraic backsolve & error compute

- **Where called**: `parameter_estimation_helpers.jl:590+::process_estimation_results`
- **What it does**: Converts HC-space candidates back to original ODE
  state/parameter space, integrates each candidate's IVP, computes
  trajectory residual → `err` field.

## Stage 11 — Backsolve-recovery rescue

- **Where called**: `optimized_multishot_estimation.jl:1977–2247`
- **Gated by**: `opts.backsolve_recovery = :algebraic_resolve` (default)
- **What it does**: For candidates with blown ICs (err > bounds), re-solves
  state ICs at t=0 with parameters held fixed, via cascading symbolic
  substitution (`resolve_states_with_fixed_params` in `si_template_integration.jl`).

## Stage 12 — Sensitivity-seed augmentation

- **Where called**: `optimized_multishot_estimation.jl:2249–2266`
- **Gated by**: `opts.use_sensitivity_seeds = false` (**OFF by default**)
- **What it does**: When enabled, probes near existing candidates along
  low-sensitivity eigenvector directions to discover nearby basins. See
  `temp_plans/2026-05-03_sensitivity_seeds_validation.md`.

## Stage 13 — Synthesized aggregate candidates

- **Where called**: `optimized_multishot_estimation.jl:2268–2284`
- **Gated by**: `opts.synthesize_aggregate_candidates = true` (default ON)
- **Where implemented**: `src/core/synthesize_aggregates.jl::_maybe_synthesize_aggregate_candidates`
- **Strategy**: Per-component median, mean, 25%-trimmed-mean, and
  weighted-median of SP + MP candidates across shooting groups. Emits
  ~9–20 synthetic candidates per configuration, tagged
  `provenance.source_type = :synthesized_aggregate`. Lineage logged to
  `artifacts/diagnostics/<model>/synthesis_log.csv`.

## Stage 14 — Candidate polishing

- **Where called**: `optimized_multishot_estimation.jl:2286+`
- **Where implemented**: `parameter_estimation.jl:2587–2765::_polish_batch_from_context`
- **Gated by**: `opts.polish_solutions = true` (default)
- **Default method**: `opts.polish_method = PolishLSOBoundedLog` (bounded
  Levenberg-Marquardt in per-variable log-space, recommended after the
  2026-05 bake-off in `temp_plans/2026-05-01_local_polish_default_recommendation.md`)
- **Safeguards**: `polish_maxtime = 3600s` deadline (fix from prior session at `polish_residual.jl`), `polish_divergence_factor = 10.0`, `polish_stagnation_window = 50`
- **Concurrency**: `polish_max_concurrency = Threads.nthreads()`
- **What it does**: Minimizes the ODE-trajectory residual via residual-form LM. Sets each candidate's `err`, `provenance.pre_polish_error`, `provenance.post_polish_error`, `provenance.polish_source_hc_idx` (only for candidates entering through this exact path — aggregates, fallback rescues, etc. leave it as `nothing` → -1 in CSV).

### Stage 14a — Pre-polish filter + cluster (inside Stage 14)

- **Where**: `parameter_estimation.jl:2394–2586::_polish_cluster_metadata`
- **Gated by**: `opts.branch_detection = true`, `opts.branch_err_factor = 100.0`, `opts.branch_cluster_eps = 0.001`
- **What it does**: (1) drop candidates with err > 100× min_err; (2) L∞-normalize identifiable axes via MAD; (3) cluster at relative-distance 0.001; (4) keep one rep per cluster as the polish input.

## Stage 15 — Output result construction

- **Where called**: `analysis_utils.jl::analyze_estimation_result` (returns from `analyze_parameter_estimation_problem`)
- **Steps**:
  1. **Score** candidates by err (`scored_results` → `sorted_results` by ascending err).
  2. **Cluster** at `CLUSTERING_THRESHOLD = 1e-5` (defined `core_types.jl:62`) via `cluster_solutions(sorted_results)` (`analysis_utils.jl:50–69`). This is *tight* — only essentially-identical polished candidates merge.
  3. **Cluster reps** = `[first(cluster) for cluster in clusters]` — i.e., lowest-err per cluster.
  4. **Annotate** `branch_size = length(c)` on each rep.
  5. **Cap** at `opts.branch_top_k = 100` (default) when `opts.branch_detection = true` — slice `cluster_reps[1:100]`. **No `_detect_branches` at this stage** — that historical step was removed in commit `f34d28d` (the 2026-05-14 numbat regression eval showed it dropped truth-near rows in 43% of regression cells).
  6. **Fallback if `branch_detection = false`** (legacy): oracle-sort the cluster_reps. This is the "06 cheat" path.

## Stage 16 — Uncertainty quantification

- **Where called**: `analysis_utils.jl:375–409`
- **Gated by**: `opts.compute_uncertainty = false` (**OFF by default**)
- **What it does**: GP-derivative covariance + Σ_x = S · Σ_d · S' to bound
  parameter uncertainty on the best-error row. See multiple project memory
  entries (`UQ Phase 3` etc.).

---

# Cross-references to existing documentation

(From the doc inventory pass. Files cited relative to ODEPE repo unless noted.)

## User-facing pipeline behavior
- `docs/2026-03-17_results_and_api.md` — result types, provenance fields, what `besterror`, `n_solutions`, etc. mean.
- `docs/2026-03-17_user_quickstart.md` — runnable example.
- `docs/2026-03-17_supported_models_and_limitations.md` — which model classes work.
- `docs/2026-03-17_benchmark_contract.md` — the contract with the PEB harness.

## Algorithm design and rationale
- `docs/2026-05-01_variable_scaling_investigation.md` — column scaling investigation (the cluster-claude open thread).
- `docs/2026-03-17_high_order_si_derivative_limit.md` — SIAN scaling limits.
- `temp_plans/2026-05-01_local_polish_default_recommendation.md` — why `PolishLSOBoundedLog` became default.
- `temp_plans/2026-03-24_multipoint_writeup.md` — multipoint template construction.
- `temp_plans/2026-04-16_post_polish_research_memo.md` — polish behavior post-bake-off.
- `STRUCTURAL_RESIDUALS_RESEARCH.md` — concept doc on using polynomial residuals as polish objective (not implemented).
- `TRANSCENDENTAL_FUNCTIONS_DESIGN.md` — transcendental handling design.
- `docs/2026-05-06_interpolator_gating_spec.md` — interpolator selection rules.

## Investigation / failure analysis
- `temp_plans/erk_deep_dive/*.md` (10 files) — extensive ERK analysis (matches our slow_fast Z/2 finding structurally).
- `temp_plans/2026-02-19_boundary_derivative_deep_analysis.md` — left-boundary derivative pathology.
- `temp_plans/2026-03-31_sensitivity_guided_estimation.md` — sensitivity-based diagnostics.
- `temp_plans/transcendental_tests/FINDINGS.md` — known issues with sin/cos/exp.
- PEB: `temp_plans/2026-03-08_boost_converter_zero_solutions_root_cause.md` — concrete failure root-cause.

## Numbat 2026-05 investigations
- PEB: `results/numbat_analysis/three_way/HANDOFF.md` — cluster-claude's main report.
- PEB: `results/numbat_analysis/three_way/INVESTIGATION_column_scaling.md` — open thread.
- PEB: `results/numbat_analysis/three_way/INVESTIGATION_denoised_polish_target.md` — open thread.
- PEB: `results/numbat_analysis/branch_detection_comparison/flexible_arm_deepdive/report.md` — system-specific deep dive.

## Tests
- `test/runtests.jl` — orchestration.
- `test/fast_core.jl` — fast smoke.
- `test/feature_regressions.jl` — full-pipeline canaries on 15+ models. **This is where end-to-end behavior is pinned.**
- `test/generate_local_polish_regularization_sweep.jl` — λ tuning (regularization in polish that the user remembers experimenting with).
- `test/generate_residual_polish_ablation.jl` — polish impact ablation.
- `test/jacobian_geometry_audit.jl` — Jacobian conditioning diagnostics.
- `test/si_template_failure_audit.jl` — SI template coverage audit.

---

# Gaps in documentation

These pieces of the pipeline behavior aren't well-documented anywhere yet:

1. **The rationale for `branch_top_k = 100`.** Why 100 and not 20 or 500? (Commit `ed0d195` chose this empirically, but no standalone doc.)
2. **The 1e-5 dedup threshold in `cluster_solutions`.** Tight by design — but nothing explains why this is tight vs the 0.001 used in `_polish_cluster_metadata`.
3. **What `polish_source_hc_idx = -1` means.** Discovered empirically this session; was previously interpreted as "synthetic aggregate" but it's actually "polish path didn't set it". Worth a single line in the API docs.
4. **HC truncation and spurious solutions.** The "we don't compute the true generic degree" caveat isn't surfaced anywhere — users (and benchmarks) take HC's solution count at face value.
5. **Numerical-ridge vs algebraic-ridge distinction.** No doc says "you might see continuous-looking spread in result.csv that isn't a continuous identifiability orbit".

---

# Observations worth flagging

- **Aggregate synthesis is default ON.** Combined with the fact that `polish_source_hc_idx` ends up `-1` for aggregates, this explains why most result.csv rows show -1 (it's not a bug, it's the volume of aggregates).
- **Branch detection is default ON** at the output stage but is just "top-K of err-sorted cluster reps" now, not L∞-MAD re-clustering. The name `_detect_branches` is misleading — that function exists but isn't on the default output path.
- **Pre-polish clustering at 0.001 is much coarser than post-polish dedup at 1e-5**. Pre-polish: "merge nearby HC candidates so we don't waste polish budget". Post-polish: "merge only bit-identical convergences". Two different intents, both labeled "clustering".
- **No automatic algebraic-degree estimation.** The pipeline never tries to count `length(HC.solutions(result))` or similar. The closest signal is the `raw_count` in metadata, but that aggregates across all shooting points and combos.
