#!/usr/bin/env python3
"""
Analyze the pre-polish candidate pool from pool_dump.csv.

Goal: understand whether the current 0.1% rel-dist clustering threshold
over-clusters along weakly-identified directions (e.g. `a` and `S` for
sirt_treatment, where the algebraic backsolve frequently produces wildly
different but well-fit values).

Outputs a textual summary that the report can quote.
"""
import csv
import math
import statistics
from collections import Counter, defaultdict
from pathlib import Path

REPRO = Path(__file__).resolve().parent
CSV_PATH = REPRO / "pool_dump.csv"

TRUTH = {
    "In(t)": 0.674, "Npop(t)": 0.208, "S(t)": 0.725, "Tr(t)": 0.109,
    "a": 0.473, "b": 0.734, "d": 0.378, "g": 0.775, "nu": 0.62,
}
AXES = list(TRUTH.keys())


def parse_float(s):
    try:
        return float(s)
    except ValueError:
        return float("nan")


def load_rows(path):
    rows = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for r in reader:
            row = {k: r[k] for k in r}
            for ax in AXES:
                row[ax] = parse_float(r[ax])
            row["err"] = parse_float(r["err"])
            row["i"] = int(r["i"])
            rows.append(row)
    return rows


def cluster(rows, threshold):
    """Replicate _polish_cluster_metadata: max-rel-distance with scale = max(|a|, |b|, 1)."""
    reps = []  # (idx, vec) tuples
    cluster_id = [0] * len(rows)
    for i, r in enumerate(rows):
        v = [r[ax] for ax in AXES]
        if any(not math.isfinite(x) for x in v):
            cluster_id[i] = 0
            continue
        merged = False
        for k, (rep_idx, rv) in enumerate(reps):
            d = 0.0
            for a, b in zip(v, rv):
                scale = max(abs(a), abs(b), 1.0)
                d = max(d, abs(a - b) / scale)
            if d <= threshold:
                cluster_id[i] = k + 1
                merged = True
                break
        if not merged:
            reps.append((i, v))
            cluster_id[i] = len(reps)
    return reps, cluster_id


def cluster_weighted(rows, threshold, weights):
    """Same as cluster() but per-axis weights so insensitive directions don't dominate."""
    reps = []
    cluster_id = [0] * len(rows)
    for i, r in enumerate(rows):
        v = [r[ax] for ax in AXES]
        if any(not math.isfinite(x) for x in v):
            cluster_id[i] = 0
            continue
        merged = False
        for k, (rep_idx, rv) in enumerate(reps):
            d_max = 0.0
            for ax, a, b, w in zip(AXES, v, rv, weights):
                scale = max(abs(a), abs(b), 1.0)
                d = w * abs(a - b) / scale
                d_max = max(d_max, d)
            if d_max <= threshold:
                cluster_id[i] = k + 1
                merged = True
                break
        if not merged:
            reps.append((i, v))
            cluster_id[i] = len(reps)
    return reps, cluster_id


def percentile(xs, q):
    s = sorted(xs)
    if not s:
        return float("nan")
    k = (len(s) - 1) * q
    f = math.floor(k); c = math.ceil(k)
    if f == c:
        return s[int(k)]
    return s[f] + (s[c] - s[f]) * (k - f)


def main():
    rows = load_rows(CSV_PATH)
    print(f"# Pool analysis — sirt_treatment_0_1em8")
    print(f"loaded {len(rows)} candidates")
    print()

    # ── Provenance breakdown ────────────────────────────────────────────────
    print("## Provenance breakdown")
    by_source = Counter(r["source_type"] for r in rows)
    by_rescue = Counter(r["rescue"] for r in rows)
    by_interp = Counter(r["interpolator"] for r in rows)
    print("source_type:", dict(by_source))
    print("rescue_path:", dict(by_rescue))
    print("interpolator: top 6 →", dict(by_interp.most_common(6)))
    print()

    # ── Per-axis spread ─────────────────────────────────────────────────────
    print("## Per-axis spread (truth, finite-min, finite-max, p50, p99, rel.spread, %good)")
    print(f"{'axis':<8} {'truth':>9} {'min':>14} {'max':>14} {'p50':>10} {'p99':>10} {'r.spread':>10} {'%good':>7}")
    for ax in AXES:
        vals = [r[ax] for r in rows if math.isfinite(r[ax])]
        truth = TRUTH[ax]
        if not vals:
            continue
        vmin, vmax = min(vals), max(vals)
        p50 = percentile(vals, 0.5)
        p99 = percentile(vals, 0.99)
        rspread = (vmax - vmin) / max(abs(truth), 1.0)
        ngood = sum(1 for v in vals if abs(v - truth) / max(abs(truth), 1.0) < 0.01)
        pct_good = 100.0 * ngood / len(vals)
        print(f"{ax:<8} {truth:9.4f} {vmin:14.4g} {vmax:14.4g} {p50:10.4g} {p99:10.4g} {rspread:10.4g} {pct_good:7.1f}")
    print()

    # ── Distance from truth (ranked) ────────────────────────────────────────
    print("## Distance from truth (per-axis rel-error histogram of all candidates)")
    print(f"{'axis':<8} {'p10':>10} {'p25':>10} {'p50':>10} {'p75':>10} {'p90':>10} {'p99':>10}")
    for ax in AXES:
        truth = TRUTH[ax]
        rels = [abs(r[ax] - truth) / max(abs(truth), 1.0) for r in rows if math.isfinite(r[ax])]
        if not rels:
            continue
        ps = [percentile(rels, q) for q in (0.10, 0.25, 0.50, 0.75, 0.90, 0.99)]
        print(f"{ax:<8} " + " ".join(f"{p:10.4g}" for p in ps))
    print()

    # ── Clustering threshold sweep ─────────────────────────────────────────
    print("## Clustering at varying max-rel-distance thresholds")
    print(f"{'threshold':>12} {'n_clusters':>12} {'reduction_factor':>18}")
    for thresh in [0.001, 0.005, 0.01, 0.02, 0.05, 0.10, 0.25, 0.50]:
        reps, _ = cluster(rows, thresh)
        red = len(rows) / max(len(reps), 1)
        print(f"{thresh:12.4f} {len(reps):12d} {red:18.2f}x")
    print()

    # ── Sensitivity-weighted clustering (heuristic weights) ────────────────
    # Weights: down-weight axes with the widest spread (likely insensitive
    # directions in the algebraic backsolve). A tighter implementation would
    # use IFT sensitivity, but the spread itself is a reasonable proxy here.
    print("## Sensitivity-weighted clustering (heuristic — w = 1 / log10(spread + 1.1))")
    spreads = {}
    for ax in AXES:
        vals = [r[ax] for r in rows if math.isfinite(r[ax])]
        if vals:
            truth = TRUTH[ax]
            spreads[ax] = (max(vals) - min(vals)) / max(abs(truth), 1.0)
        else:
            spreads[ax] = 0.0
    weights = [1.0 / max(math.log10(spreads[ax] + 1.1), 0.05) for ax in AXES]
    print("axes:", AXES)
    print("spread:", [f"{spreads[ax]:.3g}" for ax in AXES])
    print("weights:", [f"{w:.3g}" for w in weights])
    print(f"{'threshold':>12} {'n_clusters_uniform':>20} {'n_clusters_weighted':>22}")
    for thresh in [0.001, 0.01, 0.05, 0.10]:
        reps_u, _ = cluster(rows, thresh)
        reps_w, _ = cluster_weighted(rows, thresh, weights)
        print(f"{thresh:12.4f} {len(reps_u):20d} {len(reps_w):22d}")
    print()

    # ── Project-out-bad-axes clustering ────────────────────────────────────
    # Drop the wildest axes (a, S(t)) entirely and re-cluster — what does the
    # pool look like in the "well-determined" subspace?
    bad_axes = ["a", "S(t)"]
    keep_axes = [a for a in AXES if a not in bad_axes]
    print(f"## Clustering after dropping {bad_axes} entirely (i.e. only over {keep_axes})")
    def cluster_subspace(rows, threshold, axes):
        reps = []
        cluster_id = [0] * len(rows)
        for i, r in enumerate(rows):
            v = [r[ax] for ax in axes]
            if any(not math.isfinite(x) for x in v):
                cluster_id[i] = 0
                continue
            merged = False
            for k, (rep_idx, rv) in enumerate(reps):
                d = 0.0
                for a, b in zip(v, rv):
                    scale = max(abs(a), abs(b), 1.0)
                    d = max(d, abs(a - b) / scale)
                if d <= threshold:
                    cluster_id[i] = k + 1
                    merged = True
                    break
            if not merged:
                reps.append((i, v))
                cluster_id[i] = len(reps)
        return reps, cluster_id
    print(f"{'threshold':>12} {'n_clusters_subspace':>22}")
    for thresh in [0.001, 0.01, 0.05, 0.10]:
        reps_s, _ = cluster_subspace(rows, thresh, keep_axes)
        print(f"{thresh:12.4f} {len(reps_s):22d}")
    print()

    # ── Top-N by error ─────────────────────────────────────────────────────
    print("## Best 8 candidates by err")
    rows_sorted = sorted(rows, key=lambda r: r["err"] if math.isfinite(r["err"]) else float("inf"))
    print(f"{'rank':>5} {'err':>14} {'src':<14} {'rescue':<25} " + " ".join(f"{ax:>10}" for ax in AXES))
    for k, r in enumerate(rows_sorted[:8], 1):
        print(f"{k:5d} {r['err']:14.4g} {r['source_type'][:13]:<14} {r['rescue'][:24]:<25} " +
              " ".join(f"{r[ax]:10.4g}" for ax in AXES))
    print()
    print("## Worst 5 candidates by err (likely blown algebraic backsolves)")
    print(f"{'rank':>5} {'err':>14} {'src':<14} {'rescue':<25} " + " ".join(f"{ax:>10}" for ax in AXES))
    for k, r in enumerate(rows_sorted[-5:], len(rows_sorted) - 4):
        print(f"{k:5d} {r['err']:14.4g} {r['source_type'][:13]:<14} {r['rescue'][:24]:<25} " +
              " ".join(f"{r[ax]:10.4g}" for ax in AXES))
    print()

    # ── How many candidates are "near-truth" on identifiable axes ─────────
    print("## How many candidates are near-truth on the well-determined axes?")
    print("(close := |x - truth| / |truth| < 1%)")
    for axes_set in [["In(t)", "Npop(t)", "Tr(t)"],
                     ["In(t)", "Npop(t)", "Tr(t)", "g", "nu"],
                     AXES]:
        n = 0
        for r in rows:
            if all(math.isfinite(r[ax]) and abs(r[ax] - TRUTH[ax]) / max(abs(TRUTH[ax]), 1.0) < 0.01 for ax in axes_set):
                n += 1
        print(f"  near-truth on {axes_set!r}: {n}/{len(rows)} ({100.0*n/len(rows):.1f}%)")
    print()


if __name__ == "__main__":
    main()
