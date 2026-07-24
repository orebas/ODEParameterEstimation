# HC compile-mode microbenchmark (2026-07-23)

## Scope

This is a bounded plumbing/performance check, not an estimation benchmark. Each
mode ran in a fresh Julia process against the same retained 2×2 ODEPE-captured
system:

`captured_systems/sum_test_009_neq2_nvar2.jl`

Environment:

- Julia 1.12.6
- HomotopyContinuation 2.20.0
- one Julia thread; HC `threading=false`
- three solves per process
- 120-second wall limit with a 15-second TERM-to-KILL grace period

The first solve includes first-use Julia/HC compilation. The second and third
solve measure reuse within the same process.

## Results

| `compile` | setup (s) | first solve (s) | second solve (s) | third solve (s) | max RSS | solutions |
|---|---:|---:|---:|---:|---:|---:|
| `:all` | 1.062 | 33.524 | 0.001507 | 0.000384 | 1.130 GB | 1 |
| `:mixed` | 1.096 | 38.666 | 0.001832 | 0.000613 | 1.122 GB | 1 |
| `:none` | 1.181 | 48.127 | 0.002156 | 0.000579 | 1.402 GB | 1 |

All modes returned the same solution count. In this deliberately tiny case,
`:all` had the lowest cold time and comparable warm time and memory. These
measurements therefore give no reason to change ODEPE's existing effective
`:all` default.

This is one cold sample per mode on a tiny system, so it is not a general
performance ranking. The implementation exposes the policy per invocation so a
future representative-system campaign can make a better-informed choice
without another API change.

Raw outputs:

- `compile_all_sum_test_2x2.tsv`
- `compile_mixed_sum_test_2x2.tsv`
- `compile_none_sum_test_2x2.tsv`

Reproducer:

- `benchmark_hc_compile_modes.jl`
