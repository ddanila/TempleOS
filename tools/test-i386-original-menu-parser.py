#!/usr/bin/env python3
"""Check original menu parsing, lookup and heap recovery."""
import argparse
import hashlib
import json
import re
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--shared-core', action='store_true', help='Compile current shared menu bodies')
    args = parser.parse_args()
    if args.out.exists(): parser.error('Use a fresh output directory')
    out = args.out.resolve(); overlay = out/'overlay'; overlay.mkdir(parents=True)
    core = ROOT/'Adam/Menu.HC'
    fixture = ROOT/'tests/guest/i386-menu-parser/Contract.HC'
    shared = ROOT/'Adam/MenuParseCore.HC'
    files = [Path(__file__).resolve(), core, shared, ROOT/'Adam/MenuParseServices.HH', fixture, ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py', ROOT/'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C', ROOT/'build/rebuild-test/overlay/Compiler/Compiler.BIN']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, shared_core=args.shared_core,  
                  scope='Original or current shared MenuNew/MenuEntryFind/MenuDel: nested entries, arguments, flags, owner, absent lookup and exact caller heap recovery; not MenuFile, faults or action dispatch')
    try:
        source = fixture.read_bytes()
        if args.shared_core:
            source = shared.read_bytes() + source
            names = (b'MenuSubEntryFind', b'MenuEntryFind', b'MenuNewSub', b'MenuNew', b'MenuFile', b'MenuDelSub', b'MenuDel', b'MenuBuildCore', b'MenuParseOriginalLex', b'MenuParseOriginalInteger', b'MenuParseOriginalExcept')
            source = re.sub(rb'\b(?:'+b'|'.join(names)+rb')\b', lambda match: b'MPShared'+match.group(), source)
        source += b'\nU0 JRReport(U8 *s){while(*s)OutU8(0xE9,*s++); }\n'
        source += b'I64 jr_mask=JRContract;U8 *jr_line=MStrPrint("OBS menu parse mask %d\\n",jr_mask);JRReport(jr_line);Free(jr_line);\n'
        source += b'JRReport("DONE menu parse\\n");\n'
        (overlay/'Once.HC').write_bytes(source)
        iso = out/'original.iso'
        subprocess.run([sys.executable, str(ROOT/'tools/build-iso.py'), '--overlay', str(ROOT/'build/rebuild-test/overlay'), '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(iso), '--out', str(out/'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
        log = (out/'behavior/debug.log').read_text()
        report['observations'] = [line for line in log.splitlines() if line.startswith('OBS menu parse')]
        if 'OBS menu parse mask 63\n' not in log or 'DONE menu parse\n' not in log:
            raise ValueError('Original menu parse contract did not pass')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error)); raise
    finally:
        changed = [p for p,h in pins.items() if sha(Path(p)) != h]
        if changed: report.update(result='fail', changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass': raise RuntimeError('Menu parse oracle inputs changed')

if __name__ == '__main__': main()
