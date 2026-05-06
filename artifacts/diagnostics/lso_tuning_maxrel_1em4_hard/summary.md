# LSO Max-Rel Tuning Sweep

- Generated: `2026-05-01 23:47:47`
- Suite size: `20 / 20` cases flushed
- Primary metric: oracle best-in-set `max_rel_err`
- Thresholds: `1%`, `10%`, `50%`
- Phase A λ grid: `0`, `1e-04`, `1e-03`, `1e-02`, `1e-01`
- Phase B Δ grid: `3`, `10`, `30`
- Phase B tolerance profiles: `baseline`, `strict`

## Frozen Controls

| Control | <=1% | <=10% | <=50% | Median max-rel | Median runtime (s) |
| --- | ---: | ---: | ---: | ---: | ---: |
| `Scalar log-space λ=0` | 0 | 1 | 1 | 1.0276 | 563.11 |
| `Bounded FastLM log-space λ=0` | 0 | 1 | 4 | 0.9926 | 90.73 |

## Phase A: λ Scan

| λ | <=1% | <=10% | <=50% | Median max-rel | Median runtime (s) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| `0` | 0 | 3 | 8 | 0.9997 | 2.3064e+03 |
| `1e-04` | 1 | 2 | 5 | 1.2651 | 2.1908e+03 |
| `1e-03` | 1 | 2 | 5 | 1.1437 | 2.1553e+03 |
| `1e-02` | 0 | 2 | 5 | 1.4635 | 1.5997e+03 |
| `1e-01` | 0 | 2 | 6 | 1.4607 | 1.5965e+03 |

## Selected λ For Phase B

- ``

## Phase B: Δ / Tolerance Scan

| λ | Δ | tol | <=1% | <=10% | <=50% | Median max-rel | Median runtime (s) |
| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |

## Winning LSO Config

- Winner: `LSO LM log-space λ=1e-03, Δ=10, baseline tol`
- Threshold counts: `1` at `1%`, `2` at `10%`, `5` at `50%`
- Median finite max-rel: `1.1437`
- Median runtime: `2.1553e+03 s`

## Winner vs Controls

| Baseline | Better | Tie | Worse | Unsupported |
| --- | ---: | ---: | ---: | ---: |
| `Scalar log-space λ=0` | 9 | 2 | 9 | 0 |
| `Bounded FastLM log-space λ=0` | 7 | 4 | 9 | 0 |
