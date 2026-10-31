#!/usr/bin/env python3
"""Sample native instruction pointers during Bible document cleanup."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path)
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--interval', type=float, default=.2)
    args = ap.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists() or args.interval <= 0:
        ap.error('Use a fresh output directory and a positive interval')
    fixture = ROOT/'tests/guest/i386-bible-load-profile/Contract.HC'
    bible = ROOT/'Misc/Bible.TXT'
    inputs = [source, fixture, bible, Path(__file__).resolve()] + [ROOT/p for p in (
        'tools/package-i386-native-image.py', 'tools/build-i386-kernel.py',
        'tools/profile-i386-boot.py', 'tools/test-i386-timeclock-welcome.py')]
    pins = {str(p): sha(p) for p in inputs}
    sample = b''.join(bible.read_bytes().splitlines(keepends=True)[:1200])
    files = {'/Probe/BibleProfile.HC': fixture.read_bytes(), '/Probe/Bible1200.TXT': sample}
    out.mkdir(parents=True)
    working = out/'working.img'
    package = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    report = {'result':'running', 'input_sha256':pins,
              'scope':'QMP-paused statistical PC and stack samples during 1200-line document cleanup; not a timing benchmark'}
    report['packaging'] = package['package'](source, working, additions=files)
    builder = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    names = ('Kernel','CompilerRuntime','FileRuntime','MemoryRuntime','ConsoleRuntime')
    paths = {f'/Modules/I386/{name}.t32m' for name in names}
    modules = builder['mutated_file_contents'](working, paths)
    symbols = runpy.run_path(str(ROOT/'tools/profile-i386-boot.py'))['symbols']
    ranges = {'Kernel':symbols(modules['/Modules/I386/Kernel.t32m'], 0x100008)}
    keys = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))
    plain, shifted = keys['PLAIN'], keys['SHIFTED']
    log = out/'debug.log'; log.write_text('')
    cmd = ['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486,-fpu',
           '-m','64','-nic','none','-drive',f'file={working},format=raw,if=ide',
           '-display','none','-no-reboot','-debugcon',f'file:{log}','-qmp','stdio']
    (out/'command.json').write_text(json.dumps(cmd,indent=2)+'\n')
    samples = []
    proc = None
    try:
        with (out/'qemu.log').open('wb') as stderr:
            proc = subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=stderr,bufsize=0)
            if not json.loads(proc.stdout.readline()):
                raise RuntimeError('Missing QMP greeting')
            def command(name, **arguments):
                proc.stdin.write((json.dumps({'execute':name,'arguments':arguments})+'\n').encode())
                while True:
                    line=proc.stdout.readline()
                    if not line: raise RuntimeError('QMP disconnected')
                    reply=json.loads(line)
                    if 'error' in reply: raise RuntimeError(str(reply['error']))
                    if 'return' in reply: return reply['return']
            def wait(marker, timeout=900, start=0):
                deadline=time.monotonic()+timeout
                while time.monotonic()<deadline and proc.poll() is None:
                    text=log.read_text()[start:]
                    if 'FAIL native kernel' in text or 'COMMAND ERROR\n' in text:
                        raise RuntimeError(text[-1000:])
                    if marker in text: return text
                    time.sleep(.1)
                raise TimeoutError('Timed out waiting for '+marker)
            def key(name,down):
                command('input-send-event',events=[{'type':'key','data':{'down':down,'key':{'type':'qcode','data':name}}}])
            def press(name): key(name,True); key(name,False)
            def submit(text):
                for ch in text:
                    shift=ch.isupper() or ch in shifted
                    name=plain.get(ch,ch.lower())
                    if shift:key('shift',True)
                    press(name)
                    if shift:key('shift',False)
                    time.sleep(.3)
                press('ret')
            command('qmp_capabilities')
            wait('DONE native kernel startup\n',timeout=180)
            time.sleep(5)
            begin=len(log.read_text()); submit('#include "C:/Probe/BibleProfile.HC"')
            wait('COMMAND OK\n',start=begin); time.sleep(3)
            begin=len(log.read_text()); submit('BibleProfile("C:/Probe/Bible1200.TXT",1200);')
            wait('BIBLE PROFILE 1200 find-end\n',start=begin)
            text=log.read_text()
            for prefix,module in [('RUNTIME','CompilerRuntime'),('FILES','FileRuntime'),('MEMORY','MemoryRuntime'),('CONSOLE','ConsoleRuntime')]:
                match=re.search(r'^'+prefix+r' ([0-9A-Fa-f]+) ',text,re.M)
                if not match: raise ValueError('Missing module address '+prefix)
                ranges[module]=symbols(modules[f'/Modules/I386/{module}.t32m'],int(match[1],16)+8)
            def symbol_at(address):
                for module,spans in ranges.items():
                    for lo,hi,name in spans:
                        if lo<=address<hi:return module+':'+name
                return 'unmapped'
            deadline=time.monotonic()+900
            while time.monotonic()<deadline:
                if 'BIBLE PROFILE 1200 free-end\n' in log.read_text()[begin:]: break
                if proc.poll() is not None: raise RuntimeError('Guest stopped during cleanup')
                command('stop')
                regs=command('human-monitor-command',**{'command-line':'info registers'})
                pc_match=re.search(r'\bEIP=([0-9A-Fa-f]+)',regs)
                frame_match=re.search(r'\bEBP=([0-9A-Fa-f]+)',regs)
                if not pc_match: raise ValueError('Missing instruction pointer')
                pc=int(pc_match[1],16); frame=int(frame_match[1],16) if frame_match else 0
                callers=[]
                for _ in range(5):
                    if not 0x1000<=frame<=64*1024*1024-8 or frame&3: break
                    words=re.findall(r'0x([0-9A-Fa-f]{8})\b',command('human-monitor-command',**{'command-line':f'xp /2wx 0x{frame:x}'}))
                    if len(words)!=2: break
                    parent,address=(int(word,16) for word in words)
                    callers.append({'pc':address,'symbol':symbol_at(address-1)})
                    if parent<=frame:break
                    frame=parent
                samples.append({'pc':pc,'symbol':symbol_at(pc),'callers':callers})
                command('cont');time.sleep(args.interval)
            else: raise TimeoutError('Cleanup did not finish')
            wait('COMMAND OK\n',start=begin)
            command('quit');proc.wait(timeout=15)
        if not samples: raise ValueError('No cleanup samples')
        if builder['mutated_file_contents'](working,set(files))!=files: raise ValueError('Guest fixture changed')
        counts=Counter(s['symbol'] for s in samples)
        stacks=Counter(' <- '.join([s['symbol']]+[c['symbol'] for c in s['callers']]) for s in samples)
        report.update(result='pass',samples=len(samples),symbols=dict(counts.most_common()),stacks=dict(stacks.most_common()))
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        if proc and proc.poll() is None: proc.kill();proc.wait()
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'samples.json').write_text(json.dumps(samples,indent=2)+'\n')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass': raise ValueError(report['error'])


if __name__=='__main__':main()
