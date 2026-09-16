# Sneyd prepared derivative rank probe

Companion to [the mathematical report](../../docs/2026-09-16_sneyd_prepared_jets.md).
This script does not load or modify ODEParameterEstimation, fit a model, or
run structural-identifiability or polynomial-solving packages.

Requirements used for the recorded run: Python 3.14.4, SymPy 1.14.0,
mpmath 1.3.0. The exact Python version is recorded in the results.

Run against the `Sneyd_PNAS2002` directory in a checkout of
`Benchmarking-Initiative/Benchmark-Models-PEtab` at
`ddaa86d13f708926c57ec8918ce75a6b50e2e562`:

```bash
python3 repro/sneyd_prepared_jets_2026_09_16/probe.py \
  --model-dir /path/to/Benchmark-Models-PEtab/Benchmark-Models/Sneyd_PNAS2002 \
  --output /tmp/sneyd-prepared-jets.json
```

The recorded output is [evidence/results.json](evidence/results.json).
It includes source hashes, script hash, conditions, parameter samples, all
rank sequences (array index = maximum derivative order), and singular values
for the reachable later-state check. The `nominal_sbml_values` case uses the
SBML parameter decimals; the PEtab parameter TSV differs in the last few
decimal places. No noise parameter is included in the kinetic rank.

`arbitrary_known_positive_anchor` uses rational positive normalized vectors,
one per distinct input pair. It does not claim those particular vectors lie
on the prescribed trajectories. The separate `reachable_later_checks` uses
matrix exponentials from the actual preparation, holding the resulting
observed states fixed in the equation Jacobian.

The 14-parameter cases use all nine condition records and shared original
kinetic parameters. The 9-parameter cases use one condition and independent
rates. Finite-field ranks concern exact local information. They are not
floating-point condition numbers, a global identifiability certificate,
or an estimator recovery result.
