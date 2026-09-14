"""Run at most three captured polynomial systems with separate mixed-volume limits."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('systems',type=Path)
    parser.add_argument('output',type=Path)
    parser.add_argument('--sizes',nargs='+',type=int,default=[85,75,55])
    parser.add_argument('--seconds',type=float,default=180)
    args=parser.parse_args()
    if not 1<=len(args.sizes)<=3: parser.error('Use one to three systems')
    args.output.mkdir(parents=True,exist_ok=False)
    env=os.environ.copy()
    for key in ('JULIA_NUM_THREADS','OPENBLAS_NUM_THREADS','OMP_NUM_THREADS','MKL_NUM_THREADS'): env[key]='1'
    workers=[]
    try:
        for n in args.sizes:
            output=args.output/f'mv_{n}.json'
            log=(args.output/f'mv_{n}.log').open('w')
            command=['julia','--startup-file=no','--compiled-modules=existing',
                     str(Path(__file__).with_name('measure_polynomial_system.jl').resolve()),
                     str((args.systems/f'system_{n:02d}.json').resolve()),str(output.resolve())]
            process=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,env=env,start_new_session=True)
            workers.append({'n':n,'process':process,'output':output,'log':log,
                            'report':{'command':command,'pid':process.pid,'stage_seconds_cap':args.seconds,'load_seconds_cap':180},
                            'started':time.monotonic(),'profile':time.monotonic()})
        while workers:
            for w in list(workers):
                p=w['process'];record=json.loads(w['output'].read_text()) if w['output'].exists() else {}
                stage=record.get('operation_started_unix')
                elapsed=time.time()-stage if stage else time.monotonic()-w['started']
                if p.poll() is None and elapsed>(args.seconds if stage else 180):
                    w['report']['status']='timeout'
                    os.killpg(p.pid,signal.SIGINT)
                    try: p.wait(timeout=15)
                    except subprocess.TimeoutExpired:
                        os.killpg(p.pid,signal.SIGKILL);p.wait()
                if p.poll() is not None:
                    w['report'].update(returncode=p.returncode,wall_seconds=time.monotonic()-w['started'])
                    final=json.loads(w['output'].read_text()) if w['output'].exists() else {}
                    w['report'].setdefault('status',final.get('status','worker_failed'))
                    (args.output/f"mv_{w['n']}.supervisor.json").write_text(json.dumps(w['report'],indent=2)+'\n')
                    print('END',w['n'],w['report']['status'],final.get('mixed_volume'),flush=True)
                    w['log'].close();workers.remove(w)
                elif stage and time.monotonic()-w['profile']>60:
                    os.kill(p.pid,signal.SIGUSR1);w['profile']=time.monotonic()
            time.sleep(1)
    finally:
        for w in workers:
            p=w['process']
            if p.poll() is None:
                os.killpg(p.pid,signal.SIGTERM)
                try: p.wait(timeout=10)
                except subprocess.TimeoutExpired: os.killpg(p.pid,signal.SIGKILL);p.wait()
            w['log'].close()


if __name__=='__main__': main()
