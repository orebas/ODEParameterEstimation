# Repro: sirt_treatment_0_1em8 (v2_polish, 10.1h on cluster)

## Files
- `script.jl` — Julia run script (Mustache-rendered v2_polish template for this specific cell)
- `data.csv` — noisy data (additive noise, level 1e-8)
- `cell_seed.txt` — RNG seeds (noise_free=3415265780, noise=948807732)
- `data.csv.sha256` — integrity check

## Ground truth (from script.jl)
- params: a=0.473, b=0.734, d=0.378, g=0.775, nu=0.62
- IC: In=0.674, Npop=0.208, S=0.725, Tr=0.109
- time_interval: [0.0, 10.0]
- datasize: 750

## Run
You need a julia_odepe environment with the same ODEParameterEstimation
commit + Manifest.toml that the cluster uses. From the PEB repo root:

  cd ParameterEstimationBenchmarking
  export JULIA_ODEPE_ENV="$(pwd)/environments/julia_odepe"
  cd /tmp/repro_sirt_treatment_0_1em8
  julia script.jl

(The script's `Pkg.activate(raw"$(JULIA_ODEPE_ENV)")` reads that env var; the
substitution happens in the shell before julia parses it. If you want a
literal path, edit script.jl line 6.)

## What it does
- Solves a 5-param 4-state parameter-estimation problem via ODEPE-v2:
  shooting=20, multipoint (n_points=2, max_pairs=15),
  PolishLSOBoundedLog, abstol=reltol=1e-12, terminal_fallback=:direct_opt.
- The polish is the slow part — sirt_treatment is one of the systems where
  PolishLSOBoundedLog spends a *lot* of time.
- Wrote out odepe_metadata.json with provenance + result.csv with
  estimated params/states.

## What to expect
On a 16-core node the cluster ran this in 10.1h. On a 4-8 core laptop expect
2-4× longer. To shorten while debugging, lower `multipoint_max_pairs` from
15 down to 3 and/or set `polish_solutions = false` to confirm the polish
is the bottleneck.
