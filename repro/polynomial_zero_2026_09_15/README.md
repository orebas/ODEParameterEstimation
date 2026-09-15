# Exact template substitution and simplifier reproducer

This directory retains the isolated SymbolicUtils performance example and
validation of ODEPE's substitution change. See the
[implementation record](../../docs/2026-09-15_polynomial_zero_detection.md)
and the [upstream issue draft](upstream_issue.md).

## Standalone simplifier

`simplify.jl` and `sneyd_equation.jl` require only Symbolics and Julia's standard
library. Start Julia from the global environment as required by this repo;
activate an existing environment declaring Symbolics if necessary. The
retained measurements used the existing PEtab environment without loading
ODEPE, PEtab, or SIAN:

```sh
julia --startup-file=no --compiled-modules=existing -e \
  'using Pkg; Pkg.activate("/tmp/odepe-petab-pilot-env"); include("repro/polynomial_zero_2026_09_15/simplify.jl")' equation
```

Replace `equation` with `fragment` or `expand` for the two smaller comparisons.
The equation text is copied from row 61 of the prior saved Sneyd template in
`../separate_m_2026_09_15/evidence/M_unknown/si_template.jl.gz`.

## Estimation and tests

```sh
julia --startup-file=no test/current.jl test_si_multiplicity_fixing.jl
julia --startup-file=no test/current.jl
python3 repro/petab/dense_single/supervise.py sneyd \
  /tmp/odepe-sneyd-polynomial-zero-20260915 --seconds 600 --multiplicity 544
```

The supervisor needs a fresh output directory. M=544 applies only to this
single-condition diagnostic with the same representative assignments and free
initial states; see the [separate-M record](../../docs/2026-09-15_external_multiplicity.md).

Retained outcomes: focused contracts 122/122; full gate 2,281/2,281. Sneyd
reached mixed-volume candidate scoring before the estimation watchdog expired.
All 72 ordered template equations match the earlier saved template exactly.
`evidence/validation.json` records inputs, source hashes and validation scope.

`compare_templates.py BEFORE AFTER` checks ordered polynomial equality using
SymPy. It accepts plain saved Julia templates or gzip files, understands the
saved Sneyd observation names, and preserves the exact binary values of
printed Float64 coefficients. It is a diagnostic parser for these retained
files, not a general Julia parser.
