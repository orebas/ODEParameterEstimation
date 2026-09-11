"""Record the isolated Julia stack and compare it with the untouched global stack."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tomllib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--environment", type=Path, default=Path("/tmp/odepe-petab-pilot-env"))
    parser.add_argument("--global-environment", type=Path,
                        default=Path.home() / ".julia/environments/v1.13")
    args = parser.parse_args()
    output = Path(__file__).resolve().parent
    root_project = tomllib.loads((output.parent.parent / "Project.toml").read_text())
    before_bytes = (args.global_environment / "Manifest.toml").read_bytes()
    after_bytes = (args.environment / "Manifest.toml").read_bytes()
    before = tomllib.loads(before_bytes.decode())["deps"]
    after = tomllib.loads(after_bytes.decode())["deps"]
    changes = []
    for name in sorted(before.keys() & after.keys()):
        old, new = before[name][0], after[name][0]
        if old.get("version") != new.get("version") or old.get("path") != new.get("path"):
            changes.append(dict(name=name, before=old.get("version"), after=new.get("version"),
                                before_path=old.get("path"), after_path=new.get("path")))
    core_changes = [change for change in changes if change["name"] in root_project["deps"]]
    if core_changes:
        raise SystemExit(f"Core dependency versions/sources changed: {core_changes}")
    development = {}
    for name, entries in after.items():
        path = entries[0].get("path")
        if not path:
            continue
        def git(*arguments):
            return subprocess.check_output(["git", "-C", path, *arguments], text=True).strip()
        development[name] = dict(path=path, commit=git("rev-parse", "HEAD"),
                                 tree=git("rev-parse", "HEAD^{tree}"),
                                 dirty=bool(git("status", "--porcelain")))
    report = dict(recorded_at=datetime.now(timezone.utc).isoformat(),
        note="Manifest/Project snapshots are evidence of this run; absolute development paths need updating on another host. setup.jl uses the caller's existing core stack.",
        global_manifest_sha256=hashlib.sha256(before_bytes).hexdigest(),
        pilot_manifest_sha256=hashlib.sha256(after_bytes).hexdigest(),
        changed_shared_packages=changes, core_direct_changes=core_changes,
        added_packages=sorted(after.keys() - before.keys()), development_sources=development)
    (output / "environment.json").write_text(json.dumps(report, indent=2) + "\n")
    (output / "Manifest.lock.toml").write_bytes(after_bytes)
    (output / "Project.lock.toml").write_bytes((args.environment / "Project.toml").read_bytes())
    print(json.dumps(dict(changed=changes, core_direct_changes=core_changes), indent=2))


if __name__ == "__main__":
    main()
