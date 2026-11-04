#!/usr/bin/env python3
"""Inject real PS/2 key and mouse events and check public input timing/state."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]

def commands():
    history=['TempleOS i386','HolyC console','', ' '*33+'TempleOS V5.03','',' '*25+'Public Domain Operating System','','Help & Index, Quick Start: Cmd line','']
    def typed(source):
        line='> '+source
        return [line[i:i+80] for i in range(0,len(line)+1,80)]
    include='#include "C:/InputTimeContract.HC"'
    result=[(include,[])];history+=typed(include)
    for source,marker,events in [('InputKeyContract;','INPUT TIME key ready\n',[{'key':'a'}]),('InputMouseContract;','INPUT TIME mouse ready\n',[{'mouse_rel':[12,8]},{'wait_log':'INPUT TIME mouse checked\n'},{'key':'b'}])]:
        before=(history+typed(source))[-60:];after=(history+typed(source)+['1','> '])[-60:]
        result.append((source,['1'],dict(begin=marker,end=marker.replace("ready","done"),welcome_style=True,initial_rows=before,final_rows=after,preserve_history=True,events=events)))
        history+=typed(source)+['1']
    return result+[('6*7;',['42'])]

def reference(out):
    fixture=ROOT/'tests/guest/i386-input-event-time/Reference.HC'
    manifest=ROOT/'build/rebuild-test/result.json';snapshot=json.loads(manifest.read_text())
    if snapshot.get('result')!='pass':raise ValueError('Qualified original rebuild required')
    paths=[fixture,Path(__file__).resolve(),manifest]+[ROOT/p for p in ['Kernel/KbdMsEventTimeCore.HC','Kernel/SerialDev/Keyboard.HC','tools/build-iso.py','tools/guest-run.py']]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
        p=ROOT/'build/rebuild-test/overlay'/relative
        if sha(p)!=snapshot['generations'][-1][name]:raise ValueError('Rebuild binary mismatch')
        paths.append(p)
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Actual rebuilt-original event-time selection for zero, mouse-newer, equal-raw, keyboard-newer and mouse-between-raw-and-new-key counters, with saved/restored state and masked IRQs; not hardware events')
    try:
        overlay=out/'overlay';overlay.mkdir()
        suffix=b'\nU0 ITLog(U8*s){while(*s)OutU8(0xE9,*s++);}\nI64 it_mask=InputTimeReferenceContract;U8 *it_line=MStrPrint("INPUT TIME REFERENCE %d\\n",it_mask);ITLog(it_line);Free(it_line);ITLog("DONE input time reference\\n");\n'
        (overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix)
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        if 'INPUT TIME REFERENCE 31\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original decision cases failed')
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    if args.disk is None:
        return reference(out)
    fixture=ROOT/'tests/guest/i386-input-event-time/Contract.HC'
    paths=[args.disk.resolve(),Path(__file__).resolve(),fixture]+[ROOT/p for p in ['tools/i386-kernel-input.py','tools/build-i386-kernel.py','tools/package-i386-native-image.py','Kernel/FontStd.HC','Kernel/KbdMsEventTimeCore.HC','Kernel/KeyboardStateTypes.HH']]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Real PS/2 make/break count, public scan state/bitmaps and key timestamps; real mouse movement advances combined event time without changing keyboard timestamps; resumed console and exact pixels. Not all keyboard mappings, typematic, device failure or autocomplete qualification.')
    try:
        image=out/'working.img'
        runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions={'/InputTimeContract.HC':fixture.read_bytes()})
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](image,out/'behavior',ram_mib=64,accel='kvm',cpu='486,-fpu',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check=dict(status='ok',answers=[],pause_window_manager=False,commands=commands()))
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        if build['mutated_file_contents'](image,{'/InputTimeContract.HC'})['/InputTimeContract.HC']!=fixture.read_bytes():raise ValueError('Fixture changed')
        report['filesystem_integrity']=build['verify_mutated_volume'](image);report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
