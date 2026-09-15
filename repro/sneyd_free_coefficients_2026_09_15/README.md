# Sneyd with nine independent effective rates

This is a **different inference problem**, requested after the rational-kinetic
HC experiments. The six-state reaction topology, shared return rate, and
observation `y = (0.9 A + 0.1 O)^4` are retained. The nine distinct reaction
coefficients become independent parameters; no equations connecting them to
the original kinetic parameters are imposed. This is not the equivalent
coefficient lifting in `repro/coefficient_lifting_2026_09_14`.

**Retained result:** the original-data trial reaches a 72×72 system with
1,306 monomials and maximum degree four. The ordinary generic-start solve
returns no starts after 958.57 seconds, with an Int64 multiplication overflow
during polyhedral start construction. No completed mixed volume or data fit
is obtained. See [the full record](../../docs/2026-09-15_sneyd_free_coefficients.md)
and `evidence/validation.json`; the moderate-data option was not run.

The default trial has one experiment, 201 clean samples on `[0, 0.98]`, and
**single-point estimation only**. Twenty shooting locations mean twenty
separate anchors, not a coupled twenty-point polynomial system. All nine usual
interpolators are configured. All six initial states remain unknown, matching
the preceding dense-data study. M counting and selection MV scoring are
disabled. The ordinary HC polyhedral generic-start solve is retained; no
monodromy solver is substituted and the old M = 544 is not reused.

```sh
python3 repro/sneyd_free_coefficients_2026_09_15/prepare.py /tmp/sneyd-free-spec.json
python3 repro/sneyd_free_coefficients_2026_09_15/supervise.py \
  /tmp/sneyd-free-spec.json /tmp/sneyd-free-original --seconds 1800
python3 repro/sneyd_free_coefficients_2026_09_15/analyze_structure.py \
  /tmp/sneyd-free-spec.json /tmp/sneyd-free-structure.json \
  --system /tmp/sneyd-free-original/generic_system_1.json
```

Use fresh output paths. The supervisor snapshots its Julia/Python sources and
input specification, uses one Julia/BLAS thread, gives preparation 600 seconds,
and gives estimation 1,800 seconds on a monotonic clock. It requests a ten-second
profile every minute and interrupts the worker on expiry. Compilation counts
toward these caps. The Julia worker activates the existing optional environment
`/tmp/odepe-petab-pilot-env` (override with `ODEPE_PETAB_ENV`), without resolving
or installing dependencies; it does not import PEtab for this native model.

`prepare.py` reads retained source extraction and data, verifies exact equality
of all six original vector fields after substituting coefficient definitions,
checks conservation, and constructs a sparse native model specification. The
worker independently simulates that model to check agreement with the old
signal, then feeds the **saved original samples** to estimation. Generating
values are never used to seed roots or choose a winning branch.

`capture_and_solve.jl` saves each actual selected HC family and then invokes the
unmodified production generic-start method. If that method returns no starts,
the diagnostic stops explicitly, avoiding repeated fresh HC solves at every
anchor. This stop is instrumentation local to a separate Julia worker, not
production behavior. Per-trajectory polishing has a 120-second cap; terminal
direct optimization and UQ are disabled. Positivity bounds are broad `[0, 10^6]`
for both rates and ICs; the old kinetic-parameter bounds do not define a
rectangular box for independent rates.

`analyze_structure.py` computes the exact characteristic coefficient map of
the 6×6 state matrix. A nonzero 5×5 Jacobian minor proves its generic rank is
five, while a nonzero 6×6 observability determinant proves the six unknown
states can supply arbitrary local linear-output jets. Consequently four
continuous rate ambiguities remain for this single observed trajectory with
free ICs. Individual rate errors are descriptive, not a unique-recovery test.
It also checks a positivity limitation of the actual selected representative:
the fixed return rate is one, while every nonzero decay of the generating
trajectory exceeds one. See the [full record](../../docs/2026-09-15_sneyd_free_coefficients.md)
for the exact interlacing argument and its limits.

The optional `--scenario moderate` uses explicitly synthetic moderate rates
and a `[0, 10]` interval. It is a separate numerical experiment, not a substitute
for the original-data comparison. Its availability does not imply it was run.
