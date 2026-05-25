# Branch Hunt Results

Date: 2026-05-24

## Outcome

The branch hunt found one strong constructed mechanistic `M = 6` case and one
secondary constructed `M = 2` case.

The best new example is an exchangeable latent-subpopulation model. Three
hidden subpopulations have distinct rates but are only observed through their
sum. Structural identifiability marks the subpopulation states and rates as
locally identifiable, and the algebraic multiplicity computation returns
`M = 6`, matching the `3!` label permutations. When the three subpopulations
are separately observed, the same model becomes globally identifiable with
`M = 1`.

The secondary example is a two-receptor-subtype binding model. Free ligand is
observed and the two bound complexes are observed only through total bound
signal. The aggregate-output version has `M = 2`; the separately observed
control has `M = 1`.

## Recommended Branch Suite

- Real/benchmark physical `M = 2`: `daisy_mamil4`, `seir`.
- Constructed physical `M = 6`: `latent_subpopulation_branch`.
- Constructed physical `M = 2`: `receptor_subtype_binding_branch`.
- Algebraic/out-of-bounds caveats: `slow_fast`, `biohydrogenation`.

This gives a cleaner paper story than relying only on two-branch systems. The
latent-subpopulation case is still constructed, but it is close to a realistic
bulk-assay situation: unlabeled cell or infection subpopulations are observed
only through aggregate burden.

## Negative Results

- ERK is not structural branch evidence. Existing notes reported multiple HC
  roots and a `C1 <-> C2` solution class, but StructuralIdentifiability reports
  global identifiability and `compute_algebraic_multiplicity` returns `M = 1`.
  Treat it as a reminder that solver roots alone are not branch evidence.
- Twin peripheral PK and DAISY MAMIL3 aggregate variants were not useful in
  the quick pass. Equal aggregates produced continuous nonidentifiability;
  weighted aggregates became globally identifiable with `M = 1`.
- A three-receptor-subtype aggregate had the expected local-identifiability
  pattern, but the Groebner multiplicity step was too expensive for the quick
  branch hunt. Do not rely on it without a separate dedicated run.

## Verification Commands

The expensive checks live in:

```bash
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/branch_stress_multiplicity.jl")'
```

The default fast test suite only checks that the new constructors and registry
entries are wired correctly.
