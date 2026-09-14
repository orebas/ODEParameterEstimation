# Representative-fixed multiplicity

See the [implementation and validation record](../../docs/2026-09-14_fixed_multiplicity.md).

Start Julia from the global environment with the existing GaussianProcesses
and SIAN development checkouts. Package gates preserve dependency versions
with `Pkg.test(...; allow_reresolve=false)` via `test/current.jl`.

```sh
julia --startup-file=no test/current.jl test_si_multiplicity_fixing.jl
julia --startup-file=no test/current.jl
julia --startup-file=no test/current.jl benchmark

julia --startup-file=no --compiled-modules=existing repro/fixed_multiplicity_2026_09_14/inspect_sneyd.jl /tmp/sneyd-fixed-input
python3 repro/petab/dense_single/supervise.py sneyd /tmp/sneyd-fixed-estimation --si-fix-strategy local_basis --seconds 2400
python3 repro/deferred_denominators_2026_09_11/supervise.py fitzhugh_nagumo /tmp/fhn-fixed-multiplicity --si-fix-strategy local_basis --seconds 1800
python3 repro/deferred_denominators_2026_09_11/supervise.py biohydrogenation /tmp/bioh-fixed-multiplicity --si-fix-strategy local_basis --seconds 3600
```

Use fresh output directories. `inspect_sneyd.jl` inspects both the unfixed and
fixed multiplicity inputs without calling Gröbner. It copies the current
construction prefix into a separately named diagnostic function and then
calls the production input-preparation helper. Its outputs include full
polynomials, per-polynomial sizes, an exact-sample verification, and source
hashes. It does not replace a production method.

`sneyd_si_model.toml` contains the exact SI equations from
`repro/petab/dense_single/evidence/si_cost_20260914/sneyd_local/result.json`.
That earlier probe checked the imported physical model against the retained
dense run and applied the normal problem rescaling. The nine fixed coordinates
are the basis selected for that model by the local-SI implementation.

The first input probe caught an unsupported `Nemo.QQ(Float64)` conversion.
Assignments now pass through exact Julia rationals before constructing Nemo
coefficients. The corrected input probe verifies both systems successfully.

Long runs may overlap. Their elapsed times are not controlled comparisons of
the implementations.

`evidence/source.json` records the implementation/test hashes and unchanged
global/optional-PEtab dependency manifests. `evidence/input` retains the
successful input inspection with a hash manifest. The evidence directory
also contains both frozen rational recovery runs and their exact comparison
with the previous local-SI results. `evidence/gates` retains compressed test
logs, and `validation.json` summarizes completed checks.

`evidence/sneyd` retains the bounded production attempt: full model/options,
data, result/error, supervisor record, compressed raw log and profiles, and
hashes. The watchdog ended the run in the initial modular F4 calculation,
before HC. It was configured for 2,400s, but the worker's monotonic estimation
duration was 2,162.2s; the supervisor's wall-clock deadline disagreed with the
monotonic timers. Preserve that distinction when comparing run durations.
