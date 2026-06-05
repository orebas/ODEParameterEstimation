# latent_subpopulation_branch — does HC.jl stall on the symmetric (low-noise) system?

**Status (2026-06-02):** harness READY, run DEFERRED. Heavy julia + a deliberately-hanging
solve — run only when the broad-benchmark slow tier has drained off this box (an OOM here
crashes the WSL VM). `run.sh` enforces that guard.

## What we KNOW (verified, not hypothesis)
- `latent_subpopulation_branch` (`src/examples/models/branch_stress_systems.jl`): states
  S, I1, I2, I3, R. The three infected subpopulations obey the *identical* form
  `D(Ik) = bk*S*Ik − ak*Ik` and reach the observables only through symmetric sums
  (`y1 = S`, `y2 = I1+I2+I3`, `y3 = R`). So the map (params, ICs) → data is invariant under
  the **S₃ group** permuting the three `(ak, bk, Ik)` triples ⇒ **exactly 3! = 6 distinct
  parameter sets reproduce any dataset** (the M=6 multiplicity; the "branch" in the name).
  This is read directly off the equations — airtight.
- **No parameter is near 0** (a completed cell: all params 0.36–0.90) and **no IC is near 0**
  (0.13–0.74). So the hang is NOT a vanishing coefficient and NOT a zero-IC jet degeneracy.

## The OPEN question (why the MWE is needed)
The hangs cluster at LOW noise (0 / 1e-8 / 1e-6; never 1e-4 / 1e-2) — but they are a *small
subset*. In the nopolish arm, latent **idx-0 @ noise 0 HANGS**, yet **idx 1–7 @ noise 0 all
COMPLETED**. So the S₃ symmetry is **necessary but not sufficient**: every latent cell has it,
only a few hang. The precise trigger — a near-collision of two of the 6 branches? a specific
polyhedral-start degeneracy? a particular interpolator's parameterized solve? — is NOT pinned
by armchair reasoning. The empirical MWE settles it.

## The experiment (controlled — same params, only the symmetry-breaking differs)
idx-0 fixes the params (`p_true = [0.295, 0.245, 0.463, 0.54, 0.611, 0.477]`, distinct ⇒ M=6):
- **symmetric:** `latent_subpopulation_branch_0_0`     (noise 0   — the cell that hangs)
- **generic:**   `latent_subpopulation_branch_0_1em2`  (noise 1e-2 — expected to solve fast)

Dump the polynomial system each one hands to HC.jl, then solve each in `mwe_hc_solve.jl` with
`show_progress=true` and a path-result breakdown.

## Files
- `mwe_hc_solve.jl` — standalone: load a dumped system → `convert_to_hc_format` → `HC.solve`
  verbose → return-code stats + wall time. The reportable artifact (HC.jl + the polys only).
- `run.sh` — guards (abort if slow workers running / < 8 G free) → export both systems under
  `timeout` → MWE-solve each. Run ONLY when the box is free.

## The export hook (apply manually before `run.sh`; REVERT after)
First `cp src/core/homotopy_continuation.jl{,.bak}`. Then insert in `solve_with_hc`, right
after `hc_system, hc_variables = convert_to_hc_format(poly_system, varlist)` (~line 674):

```julia
        # --- TEMP export hook (latent_hc_stall repro) — inert unless ODEPE_DUMP set; REVERT ---
        if haskey(ENV, "ODEPE_DUMP")
            try
                save_poly_system("$(ENV["ODEPE_DUMP"])_n$(length(poly_system))_$(length(varlist)).jl",
                                  poly_system, varlist)
                @info "[export hook] dumped poly system" n=length(poly_system)
            catch err; @warn "[export hook] dump failed" err; end
        end
        # --- end TEMP export hook ---
```

Inert for every normal run (no `ODEPE_DUMP`). `run.sh` checks the hook marker is present and
that `using ODEParameterEstimation` still loads before exporting. Revert from `.bak` after.
(Each `solve_with_hc` call dumps a file named by `(neqs, nvars)`, so the big 47×47 fresh
system is identifiable among the per-interpolator dumps.)

## Outcomes & what each means
- **sym stalls / floods `:at_infinity` or `:terminated`, gen solves fast** → confirmed: the
  polyhedral tracker stalls on the exactly-symmetric (non-generic) target; noise rescues it.
  → strip `mwe_hc_solve.jl` to a *pure*-HC.jl repro (polys in `@var` syntax, no ODEPE) for an
  HC.jl issue / research note. This is the "research direction" outcome.
- **sym ALSO solves fast in the MWE** → the hang is NOT the fresh symmetric solve; it's
  elsewhere (a parameterized per-interpolator solve, the γ-straight track, or an endgame on a
  different system). The size-named dumps localize which solve actually stalls.
- Either way we learn something true, and stop guessing.
