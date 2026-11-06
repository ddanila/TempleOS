#!/usr/bin/env python3
"""Compare note/octave conversion over the entire I8 domain and signed boundaries."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import struct

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def expected_bytes():
    values=[]
    for ona in range(-128,128):
        octave=abs(ona)//12 * (-1 if ona<0 else 1)
        note=ona-octave*12
        values.extend((note,octave-(note<3)))
    def pitch(note,octave):return (octave+(note<3))*12+note
    values.extend(pitch(n,o) for n in range(-12,25) for o in range(-12,13))
    values.extend(pitch(n,4) for n in range(-12,25))
    notes=[-(1<<63),-13,-1,0,2,3,12,(1<<63)-1]
    octaves=[-(1<<63),(1<<63)-1,-1,0,4,10,(1<<63)-1,-(1<<63)]
    values.extend(pitch(n,o) for n,o in zip(notes,octaves))
    assert len(values)==1482
    return bytes(v&255 for v in values)

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-note-conversion/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='All 256 signed Ona values, 925 note/octave pairs, default octave and eight I64 boundary pairs. Independent 1482-byte oracle; not frequency, playback or whole Psalmody qualification.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/NoteConversion.HC':fixture.read_bytes()})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'NoteConversion.HC').write_bytes(fixture.read_bytes())
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "::/NoteConversion.HC"\nNKCheck();\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/NoteConversion.HC"');g.command('NKCheck();')
        g.wait('NOTE CONVERSION DONE\n')
        expected={'notes.bin':expected_bytes()}
        for name,want in expected.items():
            actual=(g.out/name).read_bytes();(out/name).write_bytes(actual)
            if actual!=want:raise ValueError(name+' differs from independent byte oracle')
        if args.disk:g.command('6*7;');g.result_pixels()
        report.update(result='pass',cases_checked=1,
                      table_sha256={n:hashlib.sha256(v).hexdigest() for n,v in expected.items()})
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
