"""Independently check the returned Bruno fit using the exact linear ODE solution."""
import argparse
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy.linalg import expm


def trajectory(parameters, initial, times):
    kb2, kc1, kc2, kc4 = [parameters[k] for k in ("kb2", "kc1", "kc2", "kc4")]
    # Original physical equations for condition model1_data4, in the order below.
    matrix = np.array([[-kc1-kc2, 0, 0], [kc1, -kb2, 0], [kc2, 0, -kc4]])
    vector = np.array([initial[k] for k in ("bcry(t)", "b10(t)", "ohb10(t)")])
    return np.array([expm(matrix*t) @ vector for t in times])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, default=Path(__file__).resolve().parent / "evidence")
    args = parser.parse_args()
    root = args.evidence
    record = json.loads((root / "bruno_201.json").read_text())
    data = json.loads((root / "bruno_201.data.json").read_text())
    times = np.array(data["times"])
    measured = np.column_stack([s["values"] for s in data["signals"]])
    assert [s["expression"] for s in data["signals"]] == ["bcry(t)", "b10(t)", "ohb10(t)"]
    definition = record["model_definition"]
    clean = trajectory(definition["generating_parameters"], definition["generating_initial_states"], times)
    best = record["ranked_results"][0]
    fitted = trajectory(best["parameters"], best["states"], times)
    scales = np.max(np.abs(measured), axis=0)
    generator_error = np.max(np.abs(clean-measured), axis=0) / scales
    fit_error = np.max(np.abs(fitted-measured), axis=0) / scales
    assert np.max(generator_error) < 1e-9
    assert np.max(fit_error) < 1e-9
    result = {"method": "scipy.linalg.expm on physical three-state ODE; no optimization",
              "max_relative_signal_error_generator_vs_julia": generator_error.tolist(),
              "max_relative_signal_error_returned_candidate_vs_data": fit_error.tolist(),
              "max_parameter_relative_error": max(best["recovery"][k]["relative_error"] for k in best["parameters"]),
              "max_ic_absolute_error": max(best["recovery"][k]["absolute_error"] for k in best["states"])}
    (root / "bruno_201.independent_check.json").write_text(json.dumps(result, indent=2) + "\n")
    fig, axes = plt.subplots(2, 3, figsize=(10, 5.5), sharex="col", layout="constrained")
    for j, label in enumerate(("bcry", "b10", "ohb10")):
        axes[0,j].plot(times, measured[:,j], color="#246a96", label="201 simulated samples")
        axes[0,j].plot(times[::8], fitted[::8,j], "o", fillstyle="none", color="#c55b32", ms=4,
                       label="Returned algebraic candidate")
        axes[0,j].set_title(label)
        axes[1,j].plot(times, fitted[:,j]-measured[:,j], color="#c55b32")
        axes[1,j].ticklabel_format(axis="y", style="sci", scilimits=(0,0))
        axes[1,j].set_xlabel("Time (minutes)")
        for ax in axes[:,j]:
            ax.spines[["top","right"]].set_visible(False)
            ax.grid(alpha=0.15)
    axes[0,0].set_ylabel("Concentration (original units)")
    axes[1,0].set_ylabel("Candidate − simulated data")
    axes[0,0].legend(fontsize=8)
    fig.suptitle("Bruno, one experiment: dense clean data and the returned first-ranked fit")
    fig.savefig(root / "bruno_201.png", dpi=170)
    fig.savefig(root / "bruno_201.pdf")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
