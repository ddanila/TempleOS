#!/usr/bin/env python3
"""Compare physical F3/Shift-F3 search through original-body editor sessions."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-doc-find-keys/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    prelude=ROOT/'tests/guest/i386-doc-find-editor/Prelude.HC';paths.append(prelude)
    if fixture.read_bytes().count(b'DocPutKey(')!=2:raise ValueError('Unexpected fixture call sites')
    source=prelude.read_bytes()+fixture.read_bytes().replace(b'DocPutKey(',b'FNPhysicalKey(')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Ten F3 action cases (direction, case/whole-label options, no match, selected/filtered entries, incoming lock and Alt suppression) plus six metadata/modifier cases; exact search record, cursor/text, description, roles/locks and caller heap. Eight physical F3/Shift-F3 cases run through focused DocEd(DOF_DONT_HOME); the two Alt suppression cases and metadata remain direct API calls because default Home plug-ins consume physical Alt-F3 as colour insertion. Observer waits for editor readiness and a nonconsuming callback confirms actual key delivery. No find-prompt, visual or default-editor qualification.')
    (out/'fixture.HC').write_bytes(source)
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/DocFindKeys.HC': source}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+source+b'\nFNCheck;\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/DocFindKeys.HC"')
            g.type('FNCheck;');g.press('ret')
        for i in range(8):
            g.wait(f'FIND EDITOR ARMED {i}\n')
            if i==3:g.key('shift',True)
            g.press('f3')
            if i==3:g.key('shift',False)
            g.wait(f'FIND EDITOR RECEIVED {i}\n');g.screenshot(f'search-{i}')
            g.press('esc')
        g.wait('DOC FIND KEYS DONE\n')
        for name in ('find-key-actions.bin','find-key-metadata.bin','find-key-positions.bin'):
            (out/name).write_bytes((g.out/name).read_bytes())
        report['actions']=list(struct.unpack('<10q',(out/'find-key-actions.bin').read_bytes()))
        report['metadata']=list(struct.unpack('<6q',(out/'find-key-metadata.bin').read_bytes()))
        report['positions']=list(struct.unpack('<30q',(out/'find-key-positions.bin').read_bytes()))
        if args.disk:
            g.wait('COMMAND OK\n',start=g.log.read_text().index('INPUT LINE FNCheck;'))
            g.command('6*7;')
            report['arithmetic_pixels'] = g.result_pixels()
        g.close()
        g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        expected=[0,5,1,0,12,1,0,21,1,0,16,0,0,0,1,1,0,1,1,0,1,0,5,1,0,0,0,0,0,0]
        if report['actions']!=[127]*10 or report['metadata']!=[127]*6 or report['positions']!=expected:
            raise ValueError('Find-key dispatch differs: '+repr((report['actions'],report['metadata'],report['positions'])))
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        if g:
            try:
                g.close()
            except Exception as exc:
                report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__ == '__main__':
    main()
