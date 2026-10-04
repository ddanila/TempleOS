#!/usr/bin/env python3
"""Black-box VGA contract for INT3/BPT native assembly encoding without executing traps."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [
        ('U0 AsmInt3(){asm { NOP INT3 NOP }}', []),
        ('U0 AsmBpt(){asm { NOP BPT NOP }}', []),
        ('Bool AsmBreakBytes(U8 *code){I64 i;for(i=0;i<128;i++)if(code[i]==0x90&&code[i+1]==0xCC&&code[i+2]==0x90)return TRUE;return FALSE;}', []),
        ('AsmBreakBytes((&AsmInt3+0)(U64));', ['1']),
        ('AsmBreakBytes((&AsmBpt+0)(U64));', ['1']),
        ('6*7;', ['42']),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk,
                  scope='Native INT3 and BPT compilation, emitted NOP/0xCC/NOP bytes and shell recovery; no trap execution or debugger qualification')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
        if sha(Path(__file__)) != checker:
            raise ValueError('Breakpoint assembly checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Breakpoint assembly check modified source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
