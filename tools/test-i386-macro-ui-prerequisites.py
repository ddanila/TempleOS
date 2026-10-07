#!/usr/bin/env python3
"""Require original macro menu and insert services in the installed guest."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('#include "/Kernel/SymbolTypes.HH"', []), ('I64 MUPrereq(){I64 m=0;if(HashFind("EdMacroUtil",Fs->hash_table,~0))m|=1;if(HashFind("PopUpMacroMenu",Fs->hash_table,~0))m|=2;if(HashFind("EdInsCapturedMacro",Fs->hash_table,~0))m|=4;return m;}', []), ('MUPrereq;', ['7']), ('6*7;', ['42'])]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  scope='Prerequisite: original EdMacroUtil, PopUpMacroMenu and EdInsCapturedMacro ordinary symbols (mask 1/2/4); not functional menu, recording or keyboard shortcut behavior')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Macro-playback fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro-playback prerequisites failed'))


if __name__ == '__main__':
    main()
