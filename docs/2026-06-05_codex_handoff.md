# Codex handoff — benchmark/fleet + heisenbug investigation (2026-06-05, live)

The risky part is **live state**: which partial run / cloud box / workaround is authoritative.
Disk has the code + artifacts. This doc captures what disk doesn't.

## TL;DR (live state + intent)

- **3 DigitalOcean droplets are the authoritative live experiment.** Oren explicitly said
  **do not tear them down** — he wants to see if they finish + their timing. SSH:
  `ssh -i ~/.ssh/id_ed25519 root@<ip>`; cells run inside a docker container named per box.
  - `hb-bioh` **146.190.210.127** — mid ODEPE recompile (399% CPU); about to restart the bioh cell at threads=8.
  - `hb-receptor` **147.182.167.158** — julia alive ~3h50m, **uncapped**, in the main HC solve (mixed cells), not yet at backsolve.
  - `hb-latent` **165.22.179.229** — julia alive ~3h50m, **uncapped**, in the `:generic_start` fan-out, not yet at backsolve.
- **`rc.txt` = `RC=137` on ALL THREE is MISLEADING / not authoritative.** bioh's is from a manual
  kill; receptor/latent's is from killing their `timeout` wrapper (the parent bash wrote the
  timeout's exit code). **All three julia processes are alive and running.** Track completion via
  `ps` (julia gone) + `/work/<box>/result.csv` + `/work/<box>/wall_time.txt`, NOT `rc.txt`.
- `doctl compute droplet list` returned empty in my last call (likely a bad `--format Tag` column
  or transient) — the droplets DO exist (ssh works). Verify with
  `doctl compute droplet list --format Name,PublicIPv4,Status`.

## 1. Objective and what "done" means

Immediate: characterize/settle the 3 quoll cells that never finished — **biohydrogenation_3_1em8**,
**receptor_subtype_binding_branch**, **latent_subpopulation_branch** — each on its own dedicated
box, fully-logged, "do they hang?". "Done" = (a) bioh either reaches its backsolve and we see
whether the FLINT `fmpq_mpoly_gcd` swell reproduces (and ideally capture the operands), or we
characterize where it dies; (b) receptor/latent either complete (giving timing+result) or we
characterize their hang; (c) the env/FLINT question is settled (it is — see §6/§9).
Broader: feed all this into the **v2 benchmark fleet run** (docs/2026-06-04_benchmark_fleet_v2_plan.md).

## 2. Commands running / recently run (+ cwd)

- **bioh box (in container `bioh`):** currently `inject-odepe.sh --mounted` recompiling the edited
  `/opt/odepe` (logs → `/work/bioh/warm.log`). When done, restart with:
  `docker exec -d bioh bash -c 'cd /work/bioh && rm -f run.log rc.txt && env JULIA_NUM_THREADS=8 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 OMP_NUM_THREADS=1 BIOH_MWE_CAPTURE=1 julia --startup-file=no flush_and_run.jl > run.log 2>&1; echo RC=$? > rc.txt'`
  (no `timeout` = no cap; `flush_and_run.jl` includes `script.jl`).
- **receptor/latent boxes:** `julia --startup-file=no script.jl` in `/work/<box>/` inside their
  containers, threads=8, **uncapped** (timeout wrapper killed). cwd `/work/<box>`.
- **Local (Oren's box), cwd `~/ParameterEstimationBenchmark-local`:** a recurring MONITOR cron
  tick (dup-kill / mem-guard / orphan-keepalive); 1 local re-solve cell running (~2h,
  `latent_subpopulation_branch_5_1em6`, threads=1 — protected, do NOT kill).
- **Staging, cwd `~/heisenbug_staging`:** `flush_and_run.jl`, `gcd_logger.jl` (do NOT reuse — §9),
  `reconstruct_gcd.jl`, `add_flushes.py`, RFF clone.

## 3. Active resources + safe-to-destroy

| Resource | What | Destroy? |
|---|---|---|
| 3 DO droplets (s-8vcpu-32gb, nyc1, tag `heisenbug`) | the live experiment | **NO** — Oren wants them to finish |
| `ghcr.io/orebas/odepe-bench:heisenbug` | image the boxes pulled (frozen env + injected ODEPE) | keep; it's a temp tag, deletable later |
| local container `hb_val` | idle validation container | safe to `docker rm -f` |
| local julia (latent_5_1em6 re-solve, ~2h) | monitor's protected re-solve | **NO** — real work, no cloud result |
| `/tmp/nemo_0_54_2`, `/tmp/nemo_0_55_1` | bare-Nemo envs for the FLINT A/B | keep (cheap) |

## 4. Canonical data + which summaries to trust

- Quoll results: `~/ParameterEstimationBenchmark-local/benchmark_quoll_broad_2026-05-29/filetree/`
  (local) + `cloud/hetzner/results/broad/.../filetree/` (cloud). A cell is "done" iff it has a
  `result.csv` in either.
- **Trust:** `docs/2026-06-05_heisenbug_investigation.md` (the §6/§9 findings here are its summary);
  completed cells' `wall_time.txt`/`result.csv`. The quoll-vs-wallaby analysis in
  `results/quoll_analysis/` (memory project_2026_06_04_quoll_vs_wallaby_artifact).
- **Do NOT trust:** the boxes' `rc.txt` (§TL;DR); my earlier verbal claims that got retracted (§9).
- Live bioh log: `/work/bioh/run.log` on the bioh box (after restart, the `[HC-PARAM] Point N`
  fan-out + `[RESOLVE-ENTER]` markers now flush in real time).

## 5. Uncommitted changes that matter (ODEPE = `~/.julia/dev/ODEParameterEstimation`)

- `src/core/homotopy_continuation.jl` — **the `_hc_solve` threading fix**: `const HC_SOLVE_THREADING = Ref(false)` (l.14) + `_hc_solve` wrapper; all 9 HC solve/track calls routed through it. **+ 30 inline `flush(stdout)` lines added IN-CONTAINER ONLY on the bioh box** (after tagged `println`s) — NOT in this local copy or the staged copy.
- `src/core/si_template_integration.jl` — `BIOH_MWE_CAPTURE` instrumentation + `[RESOLVE-ENTER]/[RESOLVE-EXIT]` logging in `resolve_states_with_fixed_params`. (+22 in-container flushes on bioh box.)
- `src/core/branch_completion.jl`, `src/diagnostics/analytical_branch_oracle.jl` — routed their HC.solve through `_hc_solve`.
- `parameter_estimation.jl` — the negative-err fix (Fminbox barrier in `:direct_opt` fallback) — **commit was pending Oren** (verify it's present; memory project_2026_06_03_csv_err_bug).
- New (untracked): `docs/2026-06-05_heisenbug_investigation.md`, `docs/2026-06-05_codex_handoff.md` (this), `docs/2026-06-04_benchmark_fleet_v2_plan.md`, `repro/bioh_swell_2026_06_04/` (MWE + sweep + gcd wrapper).
- None of the above is committed. The bioh box's `/opt/odepe` = this local ODEPE + the in-container flushes.

## 6. Known bugs (P0/P1/P2)

- **P1 — receptor/latent HC threads>1 deadlock.** Nondeterministic GC-safepoint hang in HC's
  "Computing mixed cells" at `JULIA_NUM_THREADS>1`. `_hc_solve` (HC-internal-threading off) is the
  candidate fix but is **UNCONFIRMED** (the boxes haven't deadlocked in ~3h50m, but that's not
  proof; the deadlock is nondeterministic). Open question: is `_hc_solve` sufficient or is
  `JULIA_NUM_THREADS=1` actually required?
- **P1 — bioh backsolve FLINT `fmpq_mpoly_gcd` swell.** Single-threaded FLINT gcd blows up inside
  SI `lie_derivative` during the backsolve (`resolve_states_with_fixed_params`). gdb-confirmed
  (prior). Never reproduced in isolation (needs full-pipeline context). NOT captured this run
  (bioh hasn't reached the backsolve).
- **P2 — newer FLINT is unreachable.** Nemo 0.55.1/FLINT 301.500 is hard-blocked by
  SI 0.5.19 → RationalFunctionFields → ParamPunPam (all cap Nemo ≤0.54). Upstream issue, not ours.
- **Not a bug:** bioh's "Point-14 crash" was **my gcd_logger** (raw FLINT ccall replacing
  `Nemo.gcd`), not ODEPE. The negative-err bug is fixed (cosmetic).

## 7. Manual decisions already made

- **HC threading:** `_hc_solve` forces `threading=false` everywhere. `JULIA_NUM_THREADS=8` on
  cloud/receptor boxes (Oren's explicit choice), **threads=1 on the saturated local box**.
- **generic_start:** `homotopy_tracking_mode = :generic_start` is DEFAULT (estimation_options.jl:586) —
  flipped from `:gamma_straight` for the aggressive quoll build; generic solve hoisted once over all interpolators.
- **branch_completion = true**, **use_column_scaling = true** (defaults; estimation_options.jl:416/568).
- **POLISH_MAXTIME:** config-dependent — `config.json`=3600s, most quoll/nopolish configs=1200s
  (the quoll polish was budget-constrained vs wallaby's 3600 — see quoll_analysis). Verify in the
  exact config used (`config/config_quoll_broad.json`).
- **rank_strategy:** scheme **S2** is the default sort (kept after a revert was overridden on broader
  benchmark data — memory project_2026_05_19_s2_decision_reversed).
- **receptor inclusion:** receptor is **excluded** from the headline presentation metrics; it's a
  separate hard tier (6402-path solves). The quoll artifact/analysis excludes receptor.
- **AMIGO2:** runs on **CUNY (matlab)**, intentionally NOT in the docker image (docker/Dockerfile comment).

## 8. Run next / do NOT run

**Next:** (a) when the bioh recompile finishes, restart the bioh cell (command in §2) and watch
`/work/bioh/run.log` for `[HC-PARAM] Point N` then `[RESOLVE-ENTER]` (= reached backsolve); (b) let
receptor/latent run to completion (collect `wall_time.txt`+`result.csv`); (c) IF bioh reaches the
backsolve and swells, the operands could be captured + replayed via `reconstruct_gcd.jl` in
`/tmp/nemo_0_54_2` vs `/tmp/nemo_0_55_1` — but a non-crashing capture method is still needed (§9).

**Do NOT:** destroy the 3 boxes (Oren's call); re-introduce `gcd_logger.jl` (crashes bioh — §9);
trust `rc.txt` on the boxes; run bioh at threads=1 (agreed=8); `Pkg.update()` expecting it to help
(it's a no-op); force Nemo 0.55 into the SI stack (turtles: RFF→ParamPunPam); kill the local
latent re-solve or any "hours-old, no-cloud-result" re-solve.

## 9. Failed attempts / misleading signals (read this)

- **`gcd_logger.jl` (type-piracy on `Nemo.gcd` via raw `@ccall libflint.fmpq_mpoly_gcd`) crashes
  bioh** in the fan-out (~Point 14): abrupt death, no Julia error, not OOM. Latent survived Point 14
  *with* it → bioh-specific. Don't reuse it as-is.
- **Block-buffered stdout** → a frozen `run.log` while CPU=100% is NOT "stuck." I misread this
  repeatedly. The in-code flushes (now on the bioh box) fix it; the `@async`/`Threads.@spawn`
  background flusher is **starved during JIT/load** and does NOT work — don't rely on it.
- **`pgrep -f "julia --startup"` matches its own command line** → false "RUNNING" for a dead
  process. Use `ps -eo stat,comm | grep -w julia`.
- **Reliable signals only:** CPU% (100%=working, 0%=blocked/dead), `ps STAT` (R/S/D/Z), and the
  cell's own `result.csv`/`wall_time.txt`. Not logs, not pgrep, not rc.txt.
- **My RETRACTED claims (do not propagate):** "the threading fix is confirmed" (no — unconfirmed);
  "bioh deadlocks at threads=8 despite the fix" (no — that was the gcd_logger crash + a pgrep
  false-positive); "bioh stuck in a 50-path solve" (no — buffering hid a progressing fan-out).
