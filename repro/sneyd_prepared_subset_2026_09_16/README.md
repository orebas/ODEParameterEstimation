# Prepared Sneyd: production subset selector, no parameter elimination

This research probe supplies all 27 rational jet equations in 12 shared
kinetic combinations to `ODEParameterEstimation._noise_select_pool`. It keeps
the prescribed initial state, all nine condition records, and derivative
orders 1–3 of `z = (9A + O)/10`. It does not use the data-dependent elimination
from `../sneyd_manual_hc_2026_09_16`.

The exported names `b2`, `bm2`, `d4`, `dm4`, `b3`, `bm3` mean
`k₂`, `k₋₂`, `ℓ₄`, `ℓ₋₄`, `k₃`, `k₋₃`, respectively.

The exact derivative targets and SBML checks reuse that experiment's oracle
generator. Its generating roots are read only by construction validation and
by `validate.py`, never by either Julia worker.

```sh
python3 repro/sneyd_prepared_subset_2026_09_16/build.py \
  --model-dir /tmp/odepe-petab-full-20260910/Benchmark-Models/Sneyd_PNAS2002

python3 repro/sneyd_prepared_subset_2026_09_16/supervise.py select \
  repro/sneyd_prepared_subset_2026_09_16/evidence/system.json \
  /tmp/sneyd-subset-selection --seconds 1200

python3 repro/sneyd_prepared_subset_2026_09_16/validate.py \
  repro/sneyd_prepared_subset_2026_09_16/evidence/system.json \
  /tmp/sneyd-subset-selection/result.json /tmp/sneyd-subset-ranks.json

python3 repro/sneyd_prepared_subset_2026_09_16/supervise.py solve \
  repro/sneyd_prepared_subset_2026_09_16/evidence/system.json \
  /tmp/sneyd-subset-nominal --seconds 1800 \
  --selection /tmp/sneyd-subset-selection/result.json --case nominal

# Repeat the same selected rows on the moderate dataset as a control.
python3 repro/sneyd_prepared_subset_2026_09_16/supervise.py solve \
  repro/sneyd_prepared_subset_2026_09_16/evidence/system.json \
  /tmp/sneyd-subset-moderate --seconds 1800 \
  --selection /tmp/sneyd-subset-selection/result.json --case moderate

python3 repro/sneyd_prepared_subset_2026_09_16/validate.py \
  repro/sneyd_prepared_subset_2026_09_16/evidence/system.json \
  /tmp/sneyd-subset-selection/result.json /tmp/sneyd-subset-validation.json \
  --solve /tmp/sneyd-subset-nominal/result.json \
  --solve /tmp/sneyd-subset-moderate/result.json
```

For the HC interpreter control, repeat either solve with `--compile none`
and a fresh output directory. `--compile all` is the default. This selects
HC's existing backend option; it does not modify a dependency or a polynomial.

Use fresh output directories for supervised runs. `ODEPE_PETAB_ENV` can point
at the existing pinned environment; the default is
`/tmp/odepe-petab-pilot-env`. No script resolves or installs packages. The
supervisor uses a writable temporary depot followed by the existing user
depot, one Julia/BLAS thread, `--startup-file=no`, and existing compiled
modules. Package loading has a separate ten-minute cap. After the operation
starts, a monotonic clock enforces `--seconds`, with periodic SIGUSR1 profiles.

The selector uses its default 64-candidate limit, beam width 16, three seeded
generic Jacobian probes, and absolute rank tolerance 10⁻⁸. Candidate mixed
volume scoring is explicitly disabled: selection uses the existing support
score and tie breakers. The chosen system then enters HC's default affine
polyhedral solver, so the required support calculation is attempted once for
the solve. This is not a test of the default policy that scores every candidate
by mixed volume.

The rank matrix uses the rational observation map. Denominator clearing occurs
only after the selector finds the minimum feasible derivative order. Exact
numerator/denominator polynomials are prepared with SymPy polynomial arithmetic
and supplied through the selector's existing materialization callback. No row
combinations or parameter substitutions inferred from data are used.

`solve.jl` substitutes the exact derivative targets, normalizes each row by
its largest coefficient, and explicitly rounds to Float64 at the HC boundary.
It uses seed 20260916, the requested HC compilation backend, serial streaming
path tracking, and no
supplied root, monodromy, or column rescaling. All 12 unknowns are kinetic
combinations; there are no unknown state derivatives to which the production
derivative-column scaling rule would apply. `validate.py` independently checks
row ranks over two finite fields and any returned roots against all 27 original
rational equations at 100-digit precision.

A validated positive endpoint has positive real coordinates, scaled imaginary
parts below 10⁻⁷, and maximum relative error in all 27 jets below 10⁻⁷. Recovery
of the generating vector additionally requires maximum relative error in the
12 combinations below 10⁻⁶. Observed moderate recovery is much tighter than
these thresholds. Validation also records dimensionless Jacobian conditioning
and V₁ sensitivity at the two oracle vectors; these diagnostics are never
used to select rows or initialize HC.

Each new supervised run saves the worker and supervisor source in its
`source/` directory. The original compiled runs retain their five-argument
worker there; the current worker adds the optional compilation-mode argument
with the same `:all` default.
Archived `worker.log` files have terminal escape sequences and carriage-return
progress formatting normalized for text review. Numerical JSON records and
source snapshots retain their original contents.
