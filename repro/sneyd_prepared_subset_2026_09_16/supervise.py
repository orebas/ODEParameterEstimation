#!/usr/bin/env python3
"""Bound selection or HC using a clock that starts after package loading."""
import argparse
import json
import os
from pathlib import Path
import signal
import shutil
import subprocess
import time


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode",choices=("select","solve"))
    parser.add_argument("system",type=Path)
    parser.add_argument("output",type=Path)
    parser.add_argument("--selection",type=Path)
    parser.add_argument("--case",choices=("moderate","nominal"),default="nominal")
    parser.add_argument("--seconds",type=float,default=1800)
    parser.add_argument("--compile",choices=("all","none"),default="all")
    args=parser.parse_args()
    if args.seconds<=0:parser.error("--seconds must be positive")
    if args.mode=="solve" and not args.selection:parser.error("solve needs --selection")
    out=args.output.resolve();out.mkdir(parents=True,exist_ok=False)
    worker=Path(__file__).with_name(args.mode+".jl")
    source=out/"source";source.mkdir()
    shutil.copyfile(worker,source/worker.name)
    shutil.copyfile(Path(__file__),source/Path(__file__).name)
    command=["julia","--startup-file=no","--compiled-modules=existing",str(worker),
             str(args.system.resolve()),str(out)]
    if args.mode=="solve":command.extend((str(args.selection.resolve()),args.case,str(args.seconds),args.compile))
    env=os.environ.copy()
    env.setdefault("JULIA_DEPOT_PATH","/tmp/odepe-sneyd-manual-depot:/home/orebas/.julia")
    for key in ("JULIA_NUM_THREADS","OPENBLAS_NUM_THREADS","OMP_NUM_THREADS","MKL_NUM_THREADS"):
        env[key]="1"
    started=time.monotonic();operation_started=None;last_profile=started
    report={"command":command,"operation_seconds_cap":args.seconds,
            "loading_seconds_cap":600,"profile_signals":[]}
    with (out/"worker.log").open("w") as log:
        process=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,env=env,start_new_session=True)
        report["pid"]=process.pid
        try:
            while process.poll() is None:
                path=out/"result.json"
                checkpoint=json.loads(path.read_text()) if path.exists() else {}
                now=time.monotonic()
                if operation_started is None and checkpoint.get("operation_started_ns"):
                    operation_started=checkpoint["operation_started_ns"]/1e9
                    if not started<=operation_started<=now:raise RuntimeError("Monotonic clocks disagree")
                elapsed=now-(operation_started if operation_started is not None else started)
                cap=args.seconds if operation_started is not None else 600
                if elapsed>=cap:
                    report.update(status="timeout",last_stage=checkpoint.get("status"),operation_elapsed_seconds=elapsed)
                    break
                if checkpoint.get("profile_ready") and now-last_profile>=60:
                    os.kill(process.pid,signal.SIGUSR1)
                    report["profile_signals"].append(now-started);last_profile=now
                time.sleep(1)
        finally:
            if process.poll() is None:
                os.killpg(process.pid,signal.SIGINT)
                try:process.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid,signal.SIGTERM)
                    try:process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid,signal.SIGKILL);process.wait()
    final_path=out/"result.json"
    final=json.loads(final_path.read_text()) if final_path.exists() else {}
    report.setdefault("status",final.get("status","worker_failed"))
    report.update(returncode=process.returncode,elapsed_seconds=time.monotonic()-started)
    (out/"supervisor.json").write_text(json.dumps(report,indent=2)+"\n")
    print("END",args.mode,report["status"],flush=True)


if __name__=="__main__":main()
