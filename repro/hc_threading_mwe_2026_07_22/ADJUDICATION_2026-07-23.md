# Adjudication of the independent review — evidence pack (2026-07-23)

The review's claims were re-tested directly rather than argued with. Before measuring
anything, the two leftover hunt drives (left running from the campaign) were killed and
the box confirmed quiet (loadavg 2.4 → falling). Every experiment below is reproducible
from files in this directory / the session scratchpad.

## Verdict table

| Review claim | Our verdict after re-testing | Decisive evidence |
|---|---|---|
| "Computing mixed cells" is wallpaper | **Agreed** (was already our joint finding) | MS 1.1.5/1.2.0 grep: zero threading primitives |
| HC compiled-system caches are racy | **Agreed** (was already our joint finding) | both sides independently measured lost entries |
| Coefficient change ≠ new compiled type on the solve path | **CONFIRMED — review is right, our claim was wrong** | E1 below: table growth 1→1→1 across coefficient changes; 34.58s → 0.06s |
| Solver construction precedes tracker-task spawn | **CONFIRMED — review is right** | `solve.jl`: `solver_startsolutions` on the calling task; spawn loop at `:628` |
| The captures show compilation, not deadlock | **CONFIRMED with exact numbers** | E3: thresholds 180/420s vs frozen-ages 184/432s at loadavg 54 |
| The standalone typeinst campaign is confounded | **CONFIRMED — including our own follow-up run** | E3: retained "hang dump" shows ticks advancing to 150,000 |
| `jl_as_global_root` writes are locked | **CONFIRMED from source** | E4: verbatim quotes, v1.12.6 |
| Julia-runtime race "not proven here" | **Agreed**, with a deconfounded re-test now running | E6: fixed-work campaign isolating the reviewer's `--gcthreads=1` change |

## E1. The crux experiment (decides the central causal claim)

**Setup:** ODEPE-faithful — systems built by `eval(Meta.parse(...))` with numeric
coefficients baked into the expression strings, `HC.set_default_compile(:all)`
(ODEPE's `homotopy_continuation.jl:415`), `threading = true`, `-t 14`, Julia 1.12.6,
HC 2.20.0. Script: `scratchpad/crux_type_churn.jl`. Direct measurement of
`length(ModelKit.TSYSTEM_TABLE)` / `THOMOTOPY_TABLE` across solves.

**Raw output:**

```
julia=1.12.6  HC=2.20.0  threads=14  compile=all
baseline (F1,F2 constructed, nothing solved)         TSYSTEM=  0  THOMOTOPY=  0
after solve(F1)            34.58s  nsols=17          TSYSTEM=  1  THOMOTOPY=  0
after solve(F2) same supp   0.06s  nsols=17          TSYSTEM=  1  THOMOTOPY=  0
after solve(F2') same supp  0.00s  nsols=17          TSYSTEM=  1  THOMOTOPY=  0
after solve(F3) NEW supp    3.63s  nsols=25          TSYSTEM=  2  THOMOTOPY=  0
after CompiledSystem(F1) DIRECT                      TSYSTEM=  3  THOMOTOPY=  0
after CompiledSystem(F2) DIRECT (same supp!)         TSYSTEM=  4  THOMOTOPY=  0
after CompiledSystem(F2) DIRECT repeat (exact dup)   TSYSTEM=  4  THOMOTOPY=  0
```

**Conclusion: the review is right.** On the production (square-polyhedral) solve path
the compiled type is **per-support**: two solves with identical support and different
coefficients reuse one table entry and one compiled evaluator (0.06s vs 34.58s). A new
support adds exactly one entry. The claim "every coefficient change creates a fresh
`CompiledSystem{(h,k)}` and recompiles all trackers per solve" is **refuted**.

**Source confirmation** (active HC 2.20.0, `98yZ2`): `polyhedral.jl:275`
`support, target_coeffs = support_coefficients(f)` separates structure from numbers;
`:396` `F = fixed(polyhedral_system(support); compile)` compiles the **support-only**
parametrized system; `:400–404` inject the numeric coefficients as runtime vectors
(`CoefficientHomotopy(F, p, q)`). Coefficients never enter the hash on this path.

**Where our error came from** (last three lines of the output): calling
`ModelKit.CompiledSystem(F)` **directly on the numeric system** *does* churn one entry
per coefficient set — that is what our stress tests (`tsys_stress.jl`) did, and we
wrongly assumed `solve()` does the same internally. It does not.

**Production-shaped corroboration** from the campaign's own retained log
(`logs/capd14on_r1.log`, real captured ODEPE daisy_mamil4 32×32 systems, sequential):

```
ATTEMPT 1 ... daisy4_000 ... DONE nsol=2 83.42s     <- cold: one support, first compile
ATTEMPT 2 ... daisy4_001 ... DONE nsol=2  0.11s     <- same support, new coefficients
ATTEMPT 3 ... daisy4_002 ... DONE nsol=2  0.10s     <- same again
```

## E2. Construction-before-spawn — confirmed

`HomotopyContinuation.solve` builds the solver and start solutions on the **calling
task** (`solve.jl:447` entry; starts collected before threading); `threaded_solve`'s
spawn loop begins at `solve.jl:628` and its tasks receive `deepcopy(tracker)` —
instances of an **already-created** type. Tracker tasks can convoy on the *first lazy
method compilation* of that one type (the review concedes this too); they do **not**
concurrently construct fresh types. Our §5 "the convoy causes concurrent `apply_type`"
bridge is retracted for the sequential production path.

## E3. The "deadlock" captures and the typeinst campaign — confounds confirmed

Verified from the retained artifacts:

- `g14` arm: stall threshold **180s**; round-18 capture fired at **184s** frozen. Each
  attempt in that arm generates a *random dense system* — a **new support every
  attempt** — so every attempt is a cold compile; under the deliberately loaded box a
  large one plausibly exceeds 180s. `drive.sh`'s own comment states the design
  assumption ("STALL only needs to exceed the slowest *healthy*") that the load
  violated.
- `fo14off` arm: threshold **420s**, capture at **432s** frozen, and the capture header
  records **`loadavg=54.41`** on 14 CPUs at that moment.
- The gdb captures show live compilation: LLVM frames present in r18 (22), r19 (20),
  fo14on (21). (fo14off_r7's snapshot shows 0 LLVM frames with 15 `jl_typeinf_lock`
  waiters — consistent with active *inference*, which presents as Julia frames, though
  that single snapshot can't prove activity either way.)
- The retained typeinst "hang dump" (`logs/typeinst_hangdump_run.log`) shows workers
  ticking **all the way to 150,000 (= completion of their loops)** — progress until
  kill, not a stall. The gdb attach for that run failed (yama), and the campaign
  table's `t=14 run=3 -> SEGFAULT` row has **no retained raw log**. The only retained
  segfault trace (`logs/ts14_r1.log`) is from the **TSYS-STRESS** arm, which was
  concurrently corrupting HC's unlocked Dicts in-process — so it cannot isolate a Julia
  bug. All as the review said.
- **Our own follow-up "verification" is withdrawn**: the 3/3 "HANG at `-t 14`" run of
  2026-07-22 evening shows in its own log workers progressing (ticks to 100,000+) right
  up to the 180s kill, and it ran while the two leftover hunt drives were still active
  on the box. It was a timeout of slow-but-progressing work, misclassified.

## E4. Julia 1.12.6 source — the review's reading is correct

`staticdata.c`, `jl_as_global_root` (v1.12.6):

```c
    // check table before acquiring lock to reduce writer contention
    jl_value_t *rval = jl_idset_get(jl_global_roots_list, jl_global_roots_keyset, val);
    if (rval) return rval;
    JL_LOCK(&global_roots_lock);
    rval = jl_idset_get(...);            // re-check under lock
    ... jl_idset_put_key / jl_idset_put_idx ...   // ALL writes under lock
    JL_UNLOCK(&global_roots_lock);
```

`smallintset.c` header comment states the concurrency contract explicitly:

```c
// ... supports concurrent calls to jl_smallintset_lookup (giving acquire ordering),
// provided that a lock is held over calls to smallintset_rehash, and the elements
// of `data` support release-consume atomics.
```

Writers locked; readers designed lock-free with acquire atomics (`jl_intref_acquire`).
The "simultaneous unsynchronized writers rehashing the table" mechanism in our writeup
is **wrong against the source** and is retracted. Any residual defect would have to be
a subtle memory-ordering bug in a structure explicitly designed for this pattern — a
much higher evidentiary bar, currently unmet.

## E5. What stands, jointly agreed

1. **HC's unlocked `TSYSTEM_TABLE`/`THOMOTOPY_TABLE` race is real** — reproduced
   independently by both sides (reviewer: 8,413/180,000 lost at `-t 8`). File it with
   HC as its own issue, decoupled from any hang narrative. The reviewer's note that
   `mwe_tsystem_race.jl:47` probes `interpret(CS)` (instance — never reads the table)
   instead of `interpret(typeof(CS))` is **correct**; the MWE proves corruption via
   entry counts, and the read-path probe should be fixed before filing.
2. **"Computing mixed cells…" is wallpaper**; MixedSubdivisions is serial and innocent.
3. **Cold-compile convoy** is the evidenced explanation for multi-*minute* first-solve
   silences (per **support**, once — not per solve), especially under load; the gdb
   captures show it live (`jl_typeinf_lock` waiters + one LLVM-active thread).
4. Cosmetic: HC `solve.jl:639` `started` never incremented; ProgressMeter 1.11
   `threadid()`-based lock heuristic is unsafe under task migration (corruption, not
   deadlock).

## E6. Residual deltas and provenance closure

1. **The reviewer's clean control changed two variables at once** (fixed total work
   *and* `--gcthreads=1`). A deconfounded campaign was run
   (`typeinst_fixed.jl` + `typeinst_clean_campaign.sh`): fixed 1.8M total ops for
   *every* arm, quiet box (load-gated), timestamped ticks, 720s cap, 240s tick-silence
   stall detector with prctl-enabled gdb capture, all raw outputs retained. Arms:
   4× (`-t 14`, 12 workers), 2× (`-t 14`, 2 workers), 2× (`-t 4`, 2 workers),
   2× (`-t 14`, 12 workers, `--gcthreads=1`). Results are reported in E8 below.
2. **The alleged parked phenomenon is not established by retained evidence.** We
   also add two corrections *against our own prior evidence base*: the
   June "biohydrogenation hung at `threads=8` even with HC threading off" datapoint was
   later root-caused to MTK 11.26.0 GCD term-swell (fixed in MTK 11.26.6) — compute,
   not a hang; and the June "receptor 10.5h hang" was legitimate single-threaded
   tracking of 63,577 paths. **Provenance audit of the "parked event" — 2026-07-23, see
   [`PROVENANCE_PARKED_EVENT_2026-07-23.md`](PROVENANCE_PARKED_EVENT_2026-07-23.md):
   the claim is withdrawn as stated.** The retained artifacts show two
   `diag_sumtest.jl` runs that received SIGTERM after their 400s deadlines,
   printed Julia death reports, and then remained alive until manual `kill -9`
   (~8.6h and at least
   ~1h26m after the respective reports; Event 2's exact SIGTERM time was not
   retained). Redirected Julia output was buffered and never flushed, so its absence cannot
   locate either process before SIAN or HC. Event 1's nested phase is unknown;
   Event 2 was actively compiling in LLVM/JIT when signalled. The previously
   claimed overlap with the healthy one-thread control is false: that control
   completed at 12:23:37Z, while Event 2 launched at 12:26:17Z. No
   `/proc/wchan` sampling, gdb, repeated snapshots, or per-thread CPU measurement
   ever happened ("sampled via /proc/wchan" was a misrecollection). The
   correctly-characterized retained anomaly is narrower: two post-SIGTERM
   **termination-path lingers** on Julia 1.12.6, with their owner undetermined.
   No pre-SIGTERM stall is established by these artifacts. June cluster-era
   reports remain unaudited here, and the June-2 latent runs' termination stacks
   show *active* HC tracking/LLVM (compute, not parking), so they are not
   parked-event evidence either. Correction:
   `repro/latent_hc_stall_2026_06_02/` is an **un-run deferred harness** (README:
   "run DEFERRED"; no dumped systems) — not an existing MWE. **Bottom line: no
   retained artifact reviewed here documents a mid-solve, all-threads-parked
   deadlock.**
   Any future claim requires instrumented capture at event time: long-timeout
   watchdog, prctl+gdb-on-stall, per-thread CPU deltas, repeated snapshots.

## E7. Corrections applied to our own documents

- `hc_hang_explained.html` — correction banner added; §3 "ignition", §5 bridge, and the
  §7 causal chain are retracted as written (per-support compile + locked global roots).
- `DISCOURSE_POST.md` — marked **superseded / do not post** pending the deconfounded
  campaign; will be rewritten around what survives (HC cache race; convoy).
- `FINDINGS.md` — status banner added pointing here.

## E8. Deconfounded typeinst campaign — results (complete)

Fixed **1,800,000 total ops for every arm** (the original `-t 14` workload), load-gated
quiet box, timestamped ticks, 240s tick-silence stall detector with gdb capture armed,
720s hard cap, all raw outputs retained (`scratchpad/typeinst_clean_bt/`).

| Arm | Config | Run times (s) | Outcome |
|---|---|---|---|
| A ×4 | `-t 14`, 12 workers *(the "always hangs" config)* | 274.7, 255.5, 258.4, 260.8 | **4/4 DONE** |
| B ×2 | `-t 14`, 2 workers | 184.0, 184.4 | 2/2 DONE |
| C ×2 | `-t 4`, 2 workers | 181.8, 182.3 | 2/2 DONE |
| D ×2 | `-t 14`, 12 workers, `--gcthreads=1` | 258.8, 258.4 | 2/2 DONE |

**Zero hangs. Zero segfaults. And the decisive number for Julia 1.12.6: healthy
completion of the original `-t 14` workload on an otherwise-idle box is ≈260s —
the original campaign killed it at 180s.** The 180s "HANG" threshold was below the
measured healthy 1.12.6 runtime even at zero load, so every corresponding 1.12.6
HANG row was a guaranteed timeout artifact before the load-10–54 conditions are
considered. The 1.11.5 rows used the same invalid 180s censoring and therefore
cannot support a hang/race claim, but this campaign did not run an equivalent
long-cap 1.11.5 completion control; calling those rows guaranteed timeout artifacts
would exceed the measurement.

Further readings from the table:

- **Contention, not deadlock, and only mild:** 12 workers ≈260s vs 2 workers ≈184s at
  the same total work — aggregate throughput *drops* ~29% as concurrency rises 6×,
  consistent with serialization on the locked global-roots insertion path (each fresh
  tuple-parameter type is interned as a permanent globally-rooted object; ~140µs/op is
  intrinsic to this workload, which retains 1.8M type objects). Exactly the review's
  "substantial lock contention, not deadlock."
- **Our residual pushback #1 dissolves:** `--gcthreads=1` makes no measurable
  difference (arm D ≈ arm A). The reviewer's control was fine.
- The original campaign's "hang caught live: 11 threads **R**, 1 D, 24 S" is likewise
  explained: R is the *running* state — active contention, with ticks in the retained
  dump advancing to completion.

**Final position on the typeinst Julia-runtime claim: this campaign establishes no
Julia-runtime bug.** The review's hedge ("a rare defect remains possible, but is not
proven here") stands as the maximal defensible statement. This does not resolve the
separate, owner-undetermined post-SIGTERM termination anomaly documented in E6.
