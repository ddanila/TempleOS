#!/usr/bin/env python3
"""Check public task contract definitions with original TempleOS, without running workers."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=ROOT / 'build/i386-public-task-definitions')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    checker = ROOT / 'tools/test-i386-public-tasks.py'
    checker_hash = hashlib.sha256(checker.read_bytes()).hexdigest()
    contract = runpy.run_path(str(checker))['behavior_commands']()
    definitions = [source for source, _ in contract
                   if source.startswith(('class ', 'I64 ', 'Bool ', 'U0 ', 'CTaskLifeProbe *'))]
    #This is a compilation oracle. No task creation or worker execution.
    definitions = [source.replace('CAlloc(sizeof(CTaskLifeProbe))', '0') for source in definitions]
    source = '\n'.join(definitions) + '\n'
    overlay = out / 'overlay'
    overlay.mkdir(exist_ok=True)
    (overlay / 'Definitions.HC').write_text(source)
    (overlay / 'Once.HC').write_text('''U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
#include "T:/Definitions.HC"
Report("PASS original public task definitions\\n");
Report("DONE original task definitions\\n");
''')
    iso = out / 'original.iso'
    subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                    'build/rebuild-test/overlay', '--overlay', str(overlay),
                    '--output', str(iso)], cwd=ROOT, check=True)
    subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                    str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
    if 'PASS original public task definitions\n' not in (out / 'original/debug.log').read_text():
        raise ValueError('Missing original compiler verdict')
    if hashlib.sha256(checker.read_bytes()).hexdigest() != checker_hash:
        raise ValueError('Public contract changed during compilation oracle')
    report = {'result': 'pass', 'definitions': len(definitions),
              'contract_checker_sha256': checker_hash,
              'definitions_sha256': hashlib.sha256(source.encode()).hexdigest(),
              'scope': 'Original HolyC definition compilation only; task behaviors unexecuted'}
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(report)


if __name__ == '__main__':
    main()
