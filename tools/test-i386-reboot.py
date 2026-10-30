#!/usr/bin/env python3
"""Check guest-initiated reboot in a disposable QEMU VM."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[1]

def native_reboot(image,out):
    log=out/'debug.log';cmd=['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486,-fpu','-m','64','-nic','none','-drive',f'file={image},format=raw,if=ide','-display','none','-no-reboot','-debugcon',f'file:{log}','-qmp','stdio']
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,bufsize=1)
    events=[]
    def call(name,**args):
        p.stdin.write(json.dumps({'execute':name,'arguments':args})+'\n');p.stdin.flush()
        while True:
            line=p.stdout.readline()
            if not line:raise RuntimeError('QEMU closed QMP')
            reply=json.loads(line)
            if 'event' in reply:events.append(reply)
            if 'error' in reply:raise RuntimeError(str(reply['error']))
            if 'return' in reply:return reply['return']
    def key(name,down):
        call('input-send-event',events=[{'type':'key','data':{'down':down,'key':{'type':'qcode','data':name}}}])
    def press(name):key(name,True);key(name,False)
    try:
        json.loads(p.stdout.readline());call('qmp_capabilities');deadline=time.monotonic()+180
        while time.monotonic()<deadline:
            if p.poll() is not None:raise ValueError('Guest exited before command')
            if log.exists() and 'DONE native kernel startup\n' in log.read_text():break
            time.sleep(.1)
        else:raise TimeoutError('Native guest did not reach console')
        time.sleep(5);key('shift',True);press('r');key('shift',False);time.sleep(.3)
        for name in ('e','b','o','o','t','semicolon'):
            press(name);time.sleep(.3)
        try:press('ret')
        except (BrokenPipeError,RuntimeError):pass
        deadline=time.monotonic()+60
        while p.poll() is None and time.monotonic()<deadline:
            if 'COMMAND ERROR\n' in log.read_text():raise ValueError('Native Reboot command rejected')
            time.sleep(.1)
        if p.poll() is None:raise TimeoutError('Native guest did not reset')
        code=p.returncode;text=log.read_text()
        for line in p.stdout:
            event=json.loads(line)
            if 'event' in event:events.append(event)
        if code!=0 or 'INPUT LINE Reboot;\n' not in text:raise ValueError('Native guest did not reset after Reboot command')
        if not any(e.get('event')=='SHUTDOWN' and e.get('data',{}).get('reason')=='guest-reset' for e in events):raise ValueError('QMP did not report guest reset')
        return code,events
    finally:
        if p.poll() is None:p.terminate();p.wait(timeout=5)

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);fixture=ROOT/'tests/guest/i386-reboot/Once.HC'
    inputs=[Path(__file__).resolve(),fixture]+[ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py')]
    if args.disk:inputs.append(args.disk.resolve())
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(result='running',input_sha256={str(p):sha(p) for p in inputs},scope='Guest invokes Reboot in a disposable QEMU PC with no-reboot; not physical hardware or SMP qualification')
    try:
        if args.disk:
            image=out/'working.img';shutil.copyfile(args.disk,image);report['qemu_exit'],report['qmp_events']=native_reboot(image,out)
        else:
            ref=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'));overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=ref['restore_reference'](overlay);(overlay/'Once.HC').write_bytes(fixture.read_bytes())
            iso=out/'original.iso';subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            log=out/'debug.log'
            cmd=['qemu-system-x86_64','-machine','pc','-accel','tcg','-cpu','max','-m','2048','-smp','2','-nic','none','-drive',f'file={iso},format=raw,media=cdrom,if=ide,index=2','-boot','d','-display','none','-no-reboot','-debugcon',f'file:{log}','-global','isa-debugcon.iobase=0xe9']
            result=subprocess.run(cmd,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,timeout=120)
            text=log.read_text();report['qemu_exit']=result.returncode
            if result.returncode!=0 or 'REBOOT REFERENCE START\n' not in text or 'REBOOT RETURNED\n' in text:raise ValueError('Original guest did not reset as expected')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
