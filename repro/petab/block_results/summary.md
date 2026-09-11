# Bounded PEtab experiment trials

Same canonical problems and recorded starts as the original pilot. All scores and refinement use the full original PEtab objective. Workers overlapped; these are feasibility results, not speed rankings.

| Model | Conditions | Status | Rank / unknowns | Order | Valid seeds | Raw NLLH | Refined NLLH |
|---|---:|---|---:|---:|---:|---:|---:|
| Bruno_JExpBot2016 | 2 | success | 7/7 | 2 | 5 | 7959836.5 | 874.20124 |
| Bruno_JExpBot2016 | 4 | success | 18/18 | 3 | 5 | 448356.72 | -46.688181 |
| Bruno_JExpBot2016 | 6 | success | 21/21 | 1 | 12 | 51.564392 | -46.68818 |
| Fujita_SciSignal2010 | 2 | rank_deficient_at_limit | 30/34 | 4 | 0 | — | — |
| Fujita_SciSignal2010 | 4 | timeout | 52/52 | 4 | 0 | — | — |
| Sneyd_PNAS2002 | 2 | timeout | 4/26 | 1 | 0 | — | — |
| Zhao_QuantBiol2020 | 2 | rank_deficient_at_limit | 10/14 | 4 | 0 | — | — |

A deficient capped pool is not a structural-identifiability verdict. A successful refinement is not proof of global optimality. Full precision, original baseline objectives, and timings are in `summary.csv`.

Implementation SHA-256: `98b60cbe97a6146d52cdfb34c19b6653cbf0fcb4a64e7840d5123ce95c1300df`.
