"""Retain immutable completed research runs with lossless, deterministic compression."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source",type=Path)
    parser.add_argument("destination",type=Path)
    args = parser.parse_args()
    assert (args.source/"supervisor.json").is_file(), "Only retain a completed worker"
    assert not args.destination.exists(), "Use a fresh destination"
    args.destination.mkdir(parents=True)
    manifest = {"source_directory":str(args.source.resolve()),"files":[],"skipped":[]}
    for path in sorted(args.source.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(args.source)
        if path.suffix not in {".json",".jl",".py",".log",".txt",".csv"}:
            manifest["skipped"].append({"path":str(relative),"bytes":path.stat().st_size})
            continue
        data = path.read_bytes()
        compressed = gzip.compress(data,mtime=0)
        assert gzip.decompress(compressed) == data
        target = args.destination / (str(relative)+".gz")
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(compressed)
        manifest["files"].append({"path":str(target.relative_to(args.destination)),
            "source_sha256":hashlib.sha256(data).hexdigest(),
            "compressed_sha256":hashlib.sha256(compressed).hexdigest(),
            "source_bytes":len(data),"compressed_bytes":len(compressed)})
    (args.destination/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print(json.dumps({"destination":str(args.destination),"files":len(manifest["files"]),
                      "compressed_bytes":sum(f["compressed_bytes"] for f in manifest["files"])}))


if __name__ == "__main__":
    main()
