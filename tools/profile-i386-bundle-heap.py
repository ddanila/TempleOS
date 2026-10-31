#!/usr/bin/env python3
"""Sample bootstrap heap counters during the native bundle diagnostic."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--ram-mib',type=int,choices=(8,16),default=16)
    ap.add_argument('--interval',type=float,default=.25)
    args=ap.parse_args();disk=args.disk.resolve();out=args.out.resolve()
    if out.exists() or args.interval<=0:ap.error('Use a fresh output directory and positive interval')
    inputs=[disk,Path(__file__).resolve(),ROOT/'tools/build-i386-kernel.py']
    pins={str(p):sha(p) for p in inputs}
    read=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
    module=read(disk,{'/Modules/I386/Kernel.t32m'})['/Modules/I386/Kernel.t32m']
    _,count,records=struct.unpack_from('<III',module,16)
    offsets=[]
    for i in range(count):
        kind,offset,name,length=struct.unpack_from('<4I',module,records+16*i)
        if kind==3 and module[name:name+length]==b'kernel_heap':offsets.append(offset)
    if len(offsets)!=1:raise ValueError('Kernel heap export is missing or ambiguous')
    address=0x100008+offsets[0]
    out.mkdir(parents=True);log=out/'debug.log';log.write_text('')
    cmd=['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486,-fpu',
         '-m',str(args.ram_mib),'-nic','none','-snapshot','-drive',f'file={disk},format=raw,if=ide',
         '-display','none','-no-reboot','-debugcon',f'file:{log}','-qmp','stdio']
    (out/'command.json').write_text(json.dumps(cmd,indent=2)+'\n')
    report={'result':'running','input_sha256':pins,'ram_mib':args.ram_mib,
            'scope':'QMP-paused bootstrap heap counter samples during root diagnostic bundle compilation; not timing qualification'}
    samples=[];proc=None
    try:
        with (out/'qemu.log').open('wb') as stderr:
            proc=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=stderr,bufsize=0)
            if not json.loads(proc.stdout.readline()):raise RuntimeError('Missing QMP greeting')
            def command(name,**arguments):
                proc.stdin.write((json.dumps({'execute':name,'arguments':arguments})+'\n').encode())
                while True:
                    line=proc.stdout.readline()
                    if not line:raise RuntimeError('QMP disconnected')
                    reply=json.loads(line)
                    if 'error' in reply:raise RuntimeError(str(reply['error']))
                    if 'return' in reply:return reply['return']
            command('qmp_capabilities');deadline=time.monotonic()+1200
            start_marker='NATIVE PACKER 0000000000000000 '
            end_marker='NATIVE BUNDLE 0000000000000000 '
            while time.monotonic()<deadline and proc.poll() is None:
                text=log.read_text(errors='replace')
                if 'FAIL native kernel' in text:raise RuntimeError(text[-1500:])
                if start_marker in text:break
                time.sleep(.1)
            else:raise TimeoutError('Bundle start marker not reached')
            started=time.monotonic()
            while time.monotonic()<deadline and proc.poll() is None:
                text=log.read_text(errors='replace')
                if 'FAIL native kernel' in text:raise RuntimeError(text[-1500:])
                done=end_marker in text
                command('stop')
                output=command('human-monitor-command',**{'command-line':f'xp /6wx 0x{address:x}'})
                words=re.findall(r'0x([0-9A-Fa-f]{8})\b',output)
                if len(words)!=6:raise ValueError('Could not read heap counters: '+output)
                base,size,used,peak,allocations,signature=(int(word,16) for word in words)
                if signature!=0x48323349 or not base or used>peak or peak>size:raise ValueError('Invalid heap counter snapshot')
                samples.append({'seconds':round(time.monotonic()-started,3),'size':size,'used':used,'peak':peak,'allocations':allocations,'done':done})
                command('cont')
                if done:break
                time.sleep(args.interval)
            else:raise TimeoutError('Bundle completion marker not reached')
            command('quit');proc.wait(timeout=15)
        if not samples or not samples[-1]['done']:raise ValueError('Incomplete bundle sample')
        report.update(result='pass',samples=len(samples),heap_address=address,
                      first=samples[0],max_used=max(s['used'] for s in samples),
                      max_allocations=max(s['allocations'] for s in samples),last=samples[-1])
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        if proc and proc.poll() is None:proc.kill();proc.wait()
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'samples.json').write_text(json.dumps(samples,indent=2)+'\n')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])


if __name__=='__main__':main()
