#!/usr/bin/env python3
"""Sample native instruction pointers during the first full Bible link lookup."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
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
    ap.add_argument('--duration', type=float, default=90)
    ap.add_argument('--pause-window-manager', action='store_true',
                    help='diagnostic only: suspend window refresh before the lookup')
    args = ap.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists() or args.interval <= 0 or args.duration <= 0:
        ap.error('Use a fresh output directory and positive interval and duration')
    fixture = ROOT/'tests/guest/i386-doc-bible-link/Contract.HC'
    inputs = [source, fixture, Path(__file__).resolve()] + [ROOT/p for p in (
        'tools/package-i386-native-image.py', 'tools/build-i386-kernel.py',
        'tools/profile-i386-boot.py', 'tools/test-i386-timeclock-welcome.py')]
    pins = {str(p): sha(p) for p in inputs}
    files = {'/Probe/BibleLink.HC': fixture.read_bytes()}
    out.mkdir(parents=True)
    working = out/'working.img'
    package = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    report = {'result':'running', 'input_sha256':pins,
              'scope':'QMP-paused statistical PC and stack samples during the first full Bible link; not a completion or timing qualification',
              'duration_seconds':args.duration, 'window_manager_suspended':args.pause_window_manager}
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
            begin=len(log.read_text()); submit('#include "C:/Probe/BibleLink.HC"')
            wait('COMMAND OK\n',start=begin); time.sleep(3)
            begin=len(log.read_text())
            if args.pause_window_manager:
                #Submit the lookup in the same command: after suspension the
                #window worker no longer drains keyboard input for a new line.
                submit("U0 TestPauseWM(){if(sys_winmgr_task!=adam_task)Suspend(sys_winmgr_task,TRUE);}TestPauseWM;if(DocBibleLinkContract!=15)throw('Bible',TRUE);")
            else:
                submit("if(DocBibleLinkContract!=15)throw('Bible',TRUE);")
            wait('BL first begin\n',start=begin)
            text=log.read_text()
            for prefix,module in [('RUNTIME','CompilerRuntime'),('FILES','FileRuntime'),('MEMORY','MemoryRuntime'),('CONSOLE','ConsoleRuntime')]:
                match=re.search(r'^'+prefix+r' ([0-9A-Fa-f]+) ',text,re.M)
                if not match: raise ValueError('Missing module address '+prefix)
                base=int(match[1],16)+8
                ranges[module]=symbols(modules[f'/Modules/I386/{module}.t32m'],base)
                if module=='ConsoleRuntime':console_base=base
            #WinMgr's update counter is the first field of the exported object.
            console=modules['/Modules/I386/ConsoleRuntime.t32m']
            _,record_count,records=struct.unpack_from('<III',console,16)
            offsets=[]
            for i in range(record_count):
                kind,offset,name,length=struct.unpack_from('<4I',console,records+16*i)
                if kind==3 and console[name:name+length]==b'winmgr':offsets.append(offset)
            if len(offsets)!=1:raise ValueError('Missing or ambiguous winmgr export')
            counter_address=console_base+offsets[0]
            def updates():
                command('stop')
                output=command('human-monitor-command',**{'command-line':f'xp /2wx 0x{counter_address:x}'})
                words=re.findall(r'0x([0-9A-Fa-f]{8})\b',output)
                if len(words)!=2:raise ValueError('Cannot read window update counter')
                value=int(words[0],16)|(int(words[1],16)<<32)
                command('cont')
                return value
            def symbol_at(address):
                for module,spans in ranges.items():
                    for lo,hi,name in spans:
                        if lo<=address<hi:return module+':'+name
                return 'unmapped'
            first_updates=updates();started=time.monotonic();deadline=started+args.duration
            while time.monotonic()<deadline:
                current=log.read_text()[begin:]
                if 'COMMAND ERROR\n' in current or 'FAIL native kernel' in current:
                    raise RuntimeError(current[-1000:])
                if 'BL first end\n' in current: break
                if proc.poll() is not None: raise RuntimeError('Guest stopped during Bible link')
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
            completed='BL first end\n' in log.read_text()[begin:]
            last_updates=updates();sample_seconds=time.monotonic()-started
            if last_updates<first_updates:raise ValueError('Window update counter went backwards')
            if args.pause_window_manager and last_updates!=first_updates:
                raise ValueError('Window manager continued updating')
            command('quit');proc.wait(timeout=15)
        if not samples: raise ValueError('No Bible link samples')
        if builder['mutated_file_contents'](working,set(files))!=files: raise ValueError('Guest fixture changed')
        counts=Counter(s['symbol'] for s in samples)
        stacks=Counter(' <- '.join([s['symbol']]+[c['symbol'] for c in s['callers']]) for s in samples)
        report.update(result='pass',link_completed=completed,samples=len(samples),
                      window_updates=last_updates-first_updates,
                      sampled_seconds=round(sample_seconds,3),
                      symbols=dict(counts.most_common()),stacks=dict(stacks.most_common()))
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
