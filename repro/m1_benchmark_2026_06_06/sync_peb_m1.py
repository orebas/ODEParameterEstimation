#!/usr/bin/env python3
"""Generate ParameterEstimationBenchmark M=1 configs and wire branch-completion control.

This script is intentionally idempotent. It reads the existing quoll-broad
systems/config files, writes M=1 benchmark variants, and updates the PEB ODEPE
templates so config files can set ODEPE_BRANCH_COMPLETION=false.
"""

from __future__ import annotations

import argparse
import json
from copy import deepcopy
from pathlib import Path


DROP_SYSTEMS = {
    "latent_subpopulation_branch",
    "receptor_subtype_binding_branch",
}

REPLACEMENTS = {
    "biohydrogenation": {
        "name": "biohydrogenation_m1",
        "measurements": {"y3": "0.5*x6"},
        "reason": "add x6 observable to remove biohydrogenation sign/compensation branch",
    },
    "daisy_mamil4": {
        "name": "daisy_mamil4_m1",
        "measurements": {"y4": "1.2*x3"},
        "reason": "add one channel-specific observable to break x3/x4 channel swap",
    },
    "seir": {
        "name": "seir_m1",
        "measurements": {"y3": "20.0*E"},
        "reason": "add exposed-compartment observable to break SEIR hyperbola branch",
    },
    "slow_fast": {
        "name": "slow_fast_m1",
        "measurements": {"y5": "0.9990000000000001*eB"},
        "reason": "add eB observable to remove slow-fast swap/rescaling branch",
    },
}

KNOWN_BASE_M1 = {
    "aircraft_pitch",
    "bicycle_model",
    "boost_converter",
    "brusselator",
    "crauste",
    "cstr",
    "daisy_mamil3",
    "dc_motor",
    "fitzhugh_nagumo",
    "flexible_arm",
    "forced_lotka_volterra",
    "harmonic_oscillator",
    "hiv",
    "lotka_volterra",
    "mass_spring_damper",
    "quadrotor",
    "repressilator",
    "sirt_treatment",
    "vanderpol",
    "latent_subpopulation_observed_control",
    "receptor_subtype_binding_observed_control",
}

SMOKE_SYSTEMS = {
    "lotka_volterra",
    "biohydrogenation_m1",
    "daisy_mamil4_m1",
    "seir_m1",
    "slow_fast_m1",
    "receptor_subtype_binding_observed_control",
}


def load_json(path: Path):
    with path.open() as io:
        return json.load(io)


def write_json(path: Path, data, dry_run: bool) -> None:
    if dry_run:
        print(f"would write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as io:
        json.dump(data, io, indent=2)
        io.write("\n")
    print(f"wrote {path}")


def ordered_measurements(system: dict) -> dict:
    return {name: system["measurements"][name] for name in system["measurement_variables"]}


def mark_m1(system: dict, reason: str, algebraic_m: int = 1, physical_m: int = 1) -> dict:
    system["m1_policy"] = "bounded_physical"
    system["algebraic_multiplicity"] = algebraic_m
    system["physical_multiplicity_positive_bounds"] = physical_m
    system["modification_reason"] = reason
    return system


def replacement_system(system: dict, spec: dict) -> dict:
    out = deepcopy(system)
    out["original_name"] = system["name"]
    out["name"] = spec["name"]
    measurements = ordered_measurements(out)
    measurements.update(spec["measurements"])
    out["measurements"] = measurements
    out["measurement_variables"] = list(measurements)
    return mark_m1(out, spec["reason"])


def build_m1_systems(quoll_broad: dict) -> dict:
    out = []
    for system in quoll_broad["systems"]:
        name = system["name"]
        if name in DROP_SYSTEMS:
            continue
        if name in REPLACEMENTS:
            out.append(replacement_system(system, REPLACEMENTS[name]))
        elif name in KNOWN_BASE_M1:
            out.append(mark_m1(deepcopy(system), "unchanged algebraic M=1 system"))
        else:
            raise RuntimeError(f"unclassified system in quoll broad input: {name}")

    names = [system["name"] for system in out]
    if len(names) != len(set(names)):
        raise RuntimeError("duplicate system names in generated M=1 config")
    return {"systems": out}


def build_metadata(systems: dict) -> dict:
    replacements = {
        spec["name"]: {
            "original_name": original,
            "added_measurements": spec["measurements"],
            "reason": spec["reason"],
        }
        for original, spec in REPLACEMENTS.items()
    }
    return {
        "m1_policy": "bounded_physical",
        "bounds": [1e-5, 10.0],
        "system_count": len(systems["systems"]),
        "dropped_branch_systems": sorted(DROP_SYSTEMS),
        "replacements": replacements,
        "branch_completion": False,
        "notes": [
            "Original branchful models are left unchanged in ODEPE/PEB source and omitted from this M=1 config.",
            "biohydrogenation and slow_fast use conservative M=1 observable variants rather than relying on bound-filtered branches.",
        ],
    }


def build_config(base_config: dict) -> dict:
    out = deepcopy(base_config)
    out["ODEPE_BRANCH_COMPLETION"] = "false"
    return out


def update_generate_scripts(peb_root: Path, dry_run: bool) -> None:
    path = peb_root / "src" / "generate_scripts.py"
    text = path.read_text()
    if '"ODEPE_BRANCH_COMPLETION"' not in text:
        text = text.replace(
            '    "ODEPE_POLISH": "true",\n',
            '    "ODEPE_POLISH": "true",\n    "ODEPE_BRANCH_COMPLETION": "true",\n',
        )
    if dry_run:
        print(f"would update {path}")
    else:
        path.write_text(text)
        print(f"updated {path}")


def update_template(path: Path, dry_run: bool) -> None:
    text = path.read_text()
    if "branch_completion =" not in text:
        text = text.replace(
            "    use_si_template = true,\n",
            "    use_si_template = true,\n    branch_completion = {{ODEPE_BRANCH_COMPLETION}},\n",
            1,
        )
    if dry_run:
        print(f"would update {path}")
    else:
        path.write_text(text)
        print(f"updated {path}")


def sync(peb_root: Path, dry_run: bool) -> None:
    config_dir = peb_root / "config"
    systems = build_m1_systems(load_json(config_dir / "systems_quoll_broad.json"))
    smoke = {"systems": [system for system in systems["systems"] if system["name"] in SMOKE_SYSTEMS]}

    write_json(config_dir / "systems_m1_broad.json", systems, dry_run)
    write_json(config_dir / "systems_m1_smoke.json", smoke, dry_run)
    write_json(config_dir / "branch_metadata_m1.json", build_metadata(systems), dry_run)
    write_json(config_dir / "config_m1_broad.json", build_config(load_json(config_dir / "config_quoll_broad.json")), dry_run)
    write_json(config_dir / "config_m1_smoke.json", build_config(load_json(config_dir / "config_quoll_smoke.json")), dry_run)

    update_generate_scripts(peb_root, dry_run)
    for template in [
        "julia_template_for_estimation_odepe.jl",
        "julia_template_for_estimation_odepe_multipoint.jl",
        "julia_template_for_estimation_odepe_v2.jl",
    ]:
        update_template(peb_root / "templates" / template, dry_run)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--peb-root",
        type=Path,
        default=Path("/home/orebas/ParameterEstimationBenchmark-local"),
        help="Path to the ParameterEstimationBenchmark checkout.",
    )
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    sync(args.peb_root.resolve(), args.dry_run)


if __name__ == "__main__":
    main()
