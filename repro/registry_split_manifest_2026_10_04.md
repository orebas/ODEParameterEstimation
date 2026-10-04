# Registry split research snapshot — 2026-10-04

The `research` branch began at ODEParameterEstimation commit `01b816f`, before
the release-tree cleanup on `main`. The preceding production source commit was
`21072a148d9d848db740f9dca7986f85ebe8eea4`. This branch retains the
research source, historical tests, scripts, and tracked evidence. Core fixes
from `main` should be cherry-picked individually; merging its cleanup commit
would delete this branch's research tree.

Three previously ignored raw result records are now retained below. They are
distinct from the smaller curated files under `dense_single/evidence/`. Their
scripts and inputs are in `repro/petab/dense_single/`; the records retain model,
status, Julia version, and available harness/manifest hashes. The JSON strings
were checked for home-path and credential markers before adding.
The status is part of the evidence: `interrupted` is not a completed fit.

| Record | SHA-256 | Status |
| --- | --- | --- |
| `dense_single/results/bruno_201/result.json` | `67d956914a6ebf9863b9e8bc2bb91767f3d72d87488ffc33fcb94b43e99994cd` | complete |
| `dense_single/results/fujita_201_fixed/result.json` | `32fdfa232f8774f1905158f981a98d7bccc9820c111e730f11db71a84d80ac69` | interrupted |
| `dense_single/results/sneyd_denominators/result.json` | `c8a14d51522f31ef6854f1ea361ed57836c2d40d2776a0ef9cd7250b140ad4b2` | interrupted |

The other 1,189 ignored files were not promoted. Most are generated PEtab
AMICI binaries, worker logs, profiles, and Python caches. They remain in the
local checkout and should not be removed with `git clean` during this split.
