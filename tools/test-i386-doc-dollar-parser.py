#!/usr/bin/env python3
"""Check original DolDoc expressions before adapting their native compiler services."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'tests/guest/i386-doc-dollar/Contract.HC'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--fields', action='store_true', help='Check bound name/repeat formatting, scanning and exact task heap recovery')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--printed-fields', action='store_true', help='Ten DocPrint-bound field/button cycles with exact caller heap recovery')
    args = parser.parse_args()
    if args.fields and args.printed_fields:
        parser.error('Choose one field fixture')
    if args.original == bool(args.disk):
        parser.error('Choose --original or a native disk')
    fixture = FIXTURE.with_name('PrintedFields.HC') if args.printed_fields else FIXTURE.with_name('Fields.HC') if args.fields else FIXTURE
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    files = [Path(__file__).resolve(), fixture]
    if args.original:
        files += [ROOT / p for p in ('Adam/DolDoc/DocPutS.HC', 'Adam/DolDoc/DocPutSCore.HC', 'Adam/DolDoc/DocPlain.HC', 'Adam/DolDoc/DocDollarServices.HH', 'Adam/DolDoc/DocFormDataCore.HC', 'Adam/DolDoc/DocDollarFlagsCore.HC', 'Adam/DolDoc/DocDollarParseCore.HC', 'Compiler/LexLib.HC', 'Compiler/PrsExp.HC', 'tools/build-iso.py', 'tools/guest-run.py')]
    else:
        files += [args.disk.resolve(), ROOT / 'tools/i386-kernel-input.py', ROOT / 'tools/build-i386-kernel.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, scope='Nested DolDoc parsing: precedence, STR_LEN, integer conversion from F64, adjacent strings, task globals, raw F64 bits and function calls; no malformed-input, allocation-fault or chooser coverage')
    if args.fields:
        report['scope'] = 'Original DA name/repeat grammar, bound values, formatting, refresh, string/integer scanning with terminator restoration, deletion and exact task data heap; no chooser interaction or allocation faults'
    if args.printed_fields:
        report['scope'] = 'Ten DocPrint-bound name/repeat and button cycles, format/refresh/scan-back, exact caller task data heap; no chooser, shared compiler heap or allocator fault coverage'
    (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir()
            source = fixture.read_text() + '\nU0 DPReport(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
            source += ('I64 dp_mask=63,dp_i;for(dp_i=0;dp_i<10;dp_i++)dp_mask&=DollarParserContract;' if args.printed_fields else 'I64 dp_mask=DollarParserContract;') + 'U8 *dp_line=MStrPrint("OBS dollar parser mask %d\\n",dp_mask);DPReport(dp_line);Free(dp_line);\n'
            source += 'if(dp_mask==63)DPReport("PASS original dollar parser\\n");else DPReport("FAIL original dollar parser\\n");\nDPReport("DONE dollar parser\\n");\n'
            (overlay / 'Once.HC').write_text(source)
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', 'build/rebuild-test/overlay', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out / 'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
            log = (out / 'behavior/debug.log').read_text()
            if 'OBS dollar parser mask 63\n' not in log or 'PASS original dollar parser\n' not in log:
                raise ValueError('Original parser contract did not pass all six checks')
        else:
            disk = out / 'working.img'
            shutil.copyfile(args.disk, disk)
            commands = [('HashFind("PrsDollarCmd",Fs->hash_table,~0)!=NULL;', ['1'])]
            source = fixture.read_text()
            commands += [(f'U8 *dp_source=CAlloc({len(source)+1});', []),
                         ('U0 DPTransfer(I64 offset,U8 *text,I64 size){MemCpy(dp_source+offset,text,size);}', [])]
            for offset in range(0, len(source), 60):
                chunk = source[offset:offset+60]
                command = f'DPTransfer({offset},{json.dumps(chunk.replace(chr(36), chr(36)*2))},{len(chunk)});'
                if len(command)>255:
                    raise ValueError('Parser fixture transfer exceeds console capacity')
                commands.append((command, []))
            commands += [(f'FileWrite("C:/DollarContract.HC",dp_source,{len(source)})>0;', ['1']),
                         ('Free(dp_source);', []), ('#include "C:/DollarContract.HC"', []),
                         ('DollarParserContract;', ['63'])]
            if args.printed_fields:
                commands += [('DollarParserContract;', ['63']) for _ in range(9)]
            commands += [('6*7;', ['42'])]
            report['behavior'] = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input'](disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False, startup_check={'status':'ok', 'answers':[], 'commands':commands})
        if not args.original:
            saved = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk, {'/DollarContract.HC'}).get('/DollarContract.HC')
            report['guest_fixture_sha256'] = hashlib.sha256(saved).hexdigest() if saved is not None else None
            if saved != fixture.read_bytes():
                raise ValueError('Guest fixture differs byte-for-byte from the pinned source')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [p for p, digest in pins.items() if sha(Path(p)) != digest]
        if changed:
            report.update(result='fail', error='Parser contract inputs changed', changed_inputs=changed)
        (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise RuntimeError(report['error'])


if __name__ == '__main__':
    main()
