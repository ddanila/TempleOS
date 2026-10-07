#!/usr/bin/env python3
"""Check original string scanning needed by bound DolDoc form fields."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'tests/guest/i386-str-scan/Contract.HC'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--cleanup', action='store_true', help='Check missing-argument exception, exact task heap and compiler-control links')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == bool(args.disk):
        parser.error('Choose --original or a native disk')
    fixture = FIXTURE.with_name('Cleanup.HC') if args.cleanup else FIXTURE
    expected = 7 if args.cleanup else 255
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    files = [Path(__file__).resolve(), fixture]
    if args.original:
        files += [ROOT / p for p in ('Adam/DolDoc/DocPlain.HC', 'Adam/DolDoc/DocDollarServices.HH', 'Adam/DolDoc/DocDollarFlagsCore.HC', 'Adam/DolDoc/DocDollarParseCore.HC', 'Compiler/LexLib.HC', 'Compiler/PrsExp.HC', 'Kernel/StrScan.HC', 'Kernel/StrScanCore.HC', 'Kernel/StringUtilCore.HC', 'Kernel/StringAllocUtilCore.HC', 'Kernel/StringUtilFlags.HH', 'Kernel/CharBitmaps.HC', 'tools/build-iso.py', 'tools/guest-run.py')]
    else:
        files += [args.disk.resolve(), ROOT / 'tools/i386-kernel-input.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, scope='String scanning: decimal and string field prefixes, hexadecimal, binary, F64, dynamic width with source remainder, list matching and an explicit date with whitespace; no malformed-input or allocation-fault coverage')
    if args.original:
        report['original_binding'] = 'Compile current shared scanner under Oracle names and call it directly; boot-kernel scanner binding not used'
    if args.cleanup:
        report['scope'] = 'Ten missing-argument Scan exceptions, exact task data heap recovery and unchanged compiler control links; no allocation faults or cancellation'
    report['expected_mask'] = expected
    (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir()
            core = (ROOT / 'Kernel/StrScanCore.HC').read_bytes()
            for name in ('StrScan', 'Str2I64', 'Str2F64', 'Str2Date'):
                core = core.replace((name+'(').encode(), ('Oracle'+name+'(').encode())
            (overlay / 'Kernel').mkdir()
            (overlay / 'Kernel/OracleScanner.HC').write_bytes(core)
            report['oracle_source_sha256'] = hashlib.sha256(core).hexdigest()
            source = '#include "/Kernel/OracleScanner.HC"\n' + fixture.read_text().replace('StrScan(', 'OracleStrScan(') + '\nU0 DPReport(U8 *s){while(*s)OutU8(0xE9,*s++); }\n'
            source += 'I64 dp_mask=StringScanContract;U8 *dp_line=MStrPrint("OBS string scan mask %d\\n",dp_mask);DPReport(dp_line);Free(dp_line);\n'
            if args.cleanup:
                source += 'dp_line=MStrPrint("OBS cleanup heap delta %d\\n",ss_cleanup_delta);DPReport(dp_line);Free(dp_line);\n'
            source += f'if(dp_mask=={expected})DPReport("PASS original string scan\\n");else DPReport("FAIL original string scan\\n");\nDPReport("DONE string scan\\n");\n'
            (overlay / 'Once.HC').write_text(source)
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', 'build/rebuild-test/overlay', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out / 'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
            log = (out / 'behavior/debug.log').read_text()
            if f'OBS string scan mask {expected}\n' not in log or 'PASS original string scan\n' not in log:
                raise ValueError(f'Original string-scan contract did not return mask {expected}')
        else:
            disk = out / 'working.img'
            shutil.copyfile(args.disk, disk)
            commands = [('HashFind("StrScan",Fs->hash_table,~0)!=NULL;', ['1'])]
            source = fixture.read_text()
            commands += [(f'U8 *ss_source=CAlloc({len(source)+1});', []),
                         ('U0 SSTransfer(I64 offset,U8 *text,I64 size){MemCpy(ss_source+offset,text,size);}', [])]
            for offset in range(0, len(source), 80):
                chunk = source[offset:offset+80]
                command = f'SSTransfer({offset},{json.dumps(chunk)},{len(chunk)});'
                if len(command)>255:
                    raise ValueError('Fixture transfer exceeds console command capacity')
                commands.append((command, []))
            commands += [(f'FileWrite("C:/ScanContract.HC",ss_source,{len(source)})>0;', ['1']),
                         ('Free(ss_source);', []), ('#include "C:/ScanContract.HC"', []),
                         ('StringScanContract;', [str(expected)]), ('6*7;', ['42'])]
            report['behavior'] = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input'](disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False, startup_check={'status':'ok', 'answers':[], 'commands':commands})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [p for p, digest in pins.items() if sha(Path(p)) != digest]
        if changed:
            report.update(result='fail', error='String-scan contract inputs changed', changed_inputs=changed)
        (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise RuntimeError(report['error'])


if __name__ == '__main__':
    main()
