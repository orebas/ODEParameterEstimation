# SI request and mixed-volume evidence, September 14

Interpretation is in the
[investigation report](../../../../../docs/2026-09-14_identifiability_cost_and_mixed_volume.md).
The [harness README](../../README.md#si-request-audit-and-longer-mixed-volume-run)
gives reproduction commands. Production source stayed at `62baa5d` throughout.

| Directory | Request |
|---|---|
| `sneyd_local`, `fujita_local` | Local single-experiment classification and coordinate transcendence basis, three seeds, probability 0.999. |
| `fujita_global` | Original global classification, probability 0.99. Compare its nonidentifiable set with `fujita_local`. |
| `sneyd_fixed`, `fujita_fixed` | Local classification after substituting the returned parameter basis at ones and distinct rationals; three seeds for each slice. |
| `sneyd_absent` | Identifiable functions with final simplification disabled, bounded at 600 seconds. |
| `fujita_mixed_volume_long` | Original retained 85-equation SIAN basis and equation order, bounded at 1,800 seconds. |

`result.json` records each SI model's exact rescaled equations, source model/data
hashes, executed worker hash, stage clock, and returned values or interruption
stack. `supervisor.json` records the outer deadline and exit status. The
mixed-volume files use an `mv_85` prefix. Source snapshots are the versions
actually executed: the first modes preceded addition of `local_fixed`.

`summary.json` records checked agreements across modes, compact measured results,
the unchanged dependency-manifest hash, source tree IDs, and hashes of the
installed SI implementation inspected for the API/call-graph audit.
`manifest.json` hashes all retained files except itself. Sampling reports are
compressed losslessly as `*.txt.gz`; a report can include preparation/compilation
as well as the selected operation. Original `/tmp` artifact paths in the logs
describe the executed runs, not portable input locations.

Every SI mode uses the retained report/data selected in `supervise.py`.
Physical-model equality is asserted before rescaling; equality of the rescaled
equations across local/global/fixed/absent modes was checked on promotion.
The local seeds agree. Fujita's global and local nonidentifiable sets agree.
All six fixed-slice checks per model return local identifiability for every
remaining parameter/state and an empty residual transcendence basis.

The absent-simplification run is a timeout, not a successful function-generation
result. It saved its interruption record before a process-exit FLINT finalizer
segfault; the worker log and return code −11 are retained. All five completed
SI workers exited with code 0. No completed package gate or recovery result is
inferred from a bounded probe.
