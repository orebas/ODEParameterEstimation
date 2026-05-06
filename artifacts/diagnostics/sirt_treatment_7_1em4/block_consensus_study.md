# Exact Block Consensus Study: sirt_treatment_7_1em4

- Model: `sirt_treatment`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4`
- Generated: `2026-04-07T16:57:51.818`
- Candidate source: `benchmark_result_csv`
- Shared candidate load/generation: 8.655 s
- Shared context build: 1127.973 s
- Shared total pre-selection time: 1136.628 s
- Raw candidate count: 77

## System Summary

- States: `In(t)`, `Npop(t)`, `S(t)`, `Tr(t)`
- Parameters: `a`, `b`, `d`, `g`, `nu`
- Observables: `y1`, `y2`, `y3`
- Datasize: 1501
- Time interval: [0.000, 10.000]

## Raw Pool Reference

- Best raw fit index: 77
- Best raw oracle index: 71
- Best-fit raw combined RMSE: 23.14%
- Best-truth raw combined RMSE: 7.47%

## Strategy Comparison

| Strategy | Selection s | Effective Total s | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|-------------|-------------------|-----------|------------|---------------|---------|
| `best_fit_baseline` | 0.000 | 1136.628 | 1.7769e+02 | 30.25% | 23.14% | method=algebraic, source=imported, candidate=77 |
| `branch_consensus_v1` | 340.361 | 1476.989 | 2.9822e+01 | 0.00% | 0.02% | method=direct_opt, source=synthesized, candidate=68, polished=true |
| `block_consensus_v2` | 68.072 | 1204.700 | 2.9822e+01 | 0.00% | 0.02% | method=direct_opt, source=assembled, polished=true |

## High Correlations

| Variable A | Variable B | |corr| |
|------------|------------|--------|
| `S(0)` | `a` | 0.9974 |
| `S(0)` | `d` | 0.8909 |
| `b` | `d` | 0.8854 |
| `a` | `d` | 0.8804 |
| `S(0)` | `b` | 0.8692 |
| `g` | `nu` | 0.8586 |
| `a` | `b` | 0.8476 |
| `Tr(0)` | `b` | 0.8114 |

## Inferred Blocks

| Block | Variables | Cluster | Medoid Candidate | Cluster Weight | Dominance | Spread | Silhouette |
|-------|-----------|---------|------------------|----------------|-----------|--------|------------|
| 1 | `In(0)` | 1 | 70 | 0.9837 | 0.9837 | 0.0257 | 0.9149 |
| 1 | `In(0)` | 2 | 15 | 0.0163 | 0.0163 | 0.0597 | 0.9149 |
| 2 | `Npop(0)` | 1 | 47 | 0.8591 | 0.8591 | 0.0092 | 0.9780 |
| 2 | `Npop(0)` | 2 | 58 | 0.1409 | 0.1409 | 0.0223 | 0.9780 |
| 3 | `S(0), Tr(0), a, b, d` | 1 | 69 | 0.9600 | 0.9600 | 0.0891 | 0.9022 |
| 3 | `S(0), Tr(0), a, b, d` | 2 | 10 | 0.0400 | 0.0400 | 0.1759 | 0.9022 |
| 4 | `g, nu` | 1 | 71 | 0.8648 | 0.8648 | 0.0792 | 0.6937 |
| 4 | `g, nu` | 2 | 13 | 0.1352 | 0.1352 | 0.1196 | 0.6937 |

## Top Assembled Hypotheses

| Rank | Source Clusters | Source Candidates | Fit Error | Equation Penalty | Combined Score | Polished | Lineage |
|------|-----------------|-------------------|-----------|------------------|----------------|----------|---------|
| 1 | `1, 1, 1, 1` | `70, 47, 69, 71` | 2.9822e+01 | 2.7127e-01 | 0.0000 | true | method=direct_opt, source=assembled, polished=true |
| 2 | `1, 2, 1, 1` | `70, 58, 69, 71` | 2.9822e+01 | 2.7127e-01 | 0.0000 | true | method=direct_opt, source=assembled, polished=true |
| 3 | `1, 1, 1, 2` | `70, 47, 69, 13` | 5.4431e+05 | 1.7239e+00 | 0.3113 | false | method=direct_opt, source=assembled |

## Variable Confidence

| Variable | Block | Representative | Cross-Hypothesis Spread | Block Dominance | Confidence | Tier |
|----------|-------|----------------|-------------------------|-----------------|------------|------|
| `In(0)` | 1 | 0.757898 | 0.0062 | 0.9837 | 0.9768 | `high` |
| `Npop(0)` | 2 | 0.660000 | 0.0000 | 0.8591 | 0.9295 | `high` |
| `S(0)` | 3 | 0.806009 | 0.0309 | 0.9600 | 0.9132 | `high` |
| `Tr(0)` | 3 | 0.873382 | 0.0177 | 0.9600 | 0.9393 | `high` |
| `a` | 3 | 0.715031 | 0.0734 | 0.9600 | 0.8458 | `high` |
| `b` | 3 | 0.669009 | 0.0004 | 0.9600 | 0.9789 | `high` |
| `d` | 3 | 0.143007 | 0.0344 | 0.9600 | 0.9067 | `high` |
| `g` | 4 | 0.417002 | 0.0039 | 0.8648 | 0.9228 | `high` |
| `nu` | 4 | 0.233999 | 0.0594 | 0.8648 | 0.8179 | `high` |

