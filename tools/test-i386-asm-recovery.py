#!/usr/bin/env python3
"""Check native assembly operand bytes and recovery after an invalid constant."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    validator = ROOT / 'tools/build-i386-kernel.py'
    checker_hash, validator_hash, source_hash = sha(Path(__file__)), sha(validator), sha(args.disk)
    candidate = out / 'candidate.img'
    if candidate == args.disk.resolve():
        raise ValueError('Test output would overwrite the input disk')
    shutil.copyfile(args.disk, candidate)
    commands = [
        ('CDoc *bad_doc=DocNew("C:/Probe/BadAsm.HC",Fs);', []),
        ('U8 *bad_text="public U0 BadAsm(){asm{TEST ECX,1/0}}";', []),
        ('U0 BadFill(){I64 i;for(i=0;bad_text[i];i++)DocPutKey(bad_doc,bad_text[i]);}', []),
        ('BadFill;', []),
        ('DocWrite(bad_doc);', ['1']),
        ('DocDel(bad_doc);', []),
        ('I386BuildModule("C:/Probe/BadAsm.HC","C:/Probe/BadAsm.t32m")>0;', ['0']),
        ('I386BuildModule("C:/Kernel/I386/AsmOperandFixture.HC","C:/Probe/GoodAsm.t32m")>0;', ['1']),
        ('6*7;', ['42']),
    ]
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    behavior = runner(candidate, out / 'behavior', snapshot=False, ram_mib=16,
                      accel=args.accel, cpu='486,-fpu', qmp_stdio=True, startup_timeout=180,
                      startup_check={'status': 'ok', 'answers': [], 'commands': commands})
    build = runpy.run_path(str(validator))
    fixture = build['verify_native_operand_asm_module'](candidate, '/Probe/GoodAsm.t32m')
    if build['mutated_file_contents'](candidate, {'/Probe/BadAsm.t32m'}):
        raise ValueError('Rejected assembly published an output module')
    if sha(args.disk) != source_hash or sha(Path(__file__)) != checker_hash or sha(validator) != validator_hash:
        raise ValueError('Input disk or checker changed during execution')
    report = {'result': 'pass', 'behavior': behavior, 'fixture': fixture,
              'source_disk_sha256': source_hash, 'checker_sha256': checker_hash,
              'validator_sha256': validator_hash, 'source_disk_unchanged': True,
              'scope': 'Exact assembly operand bytes and zero-divisor rejection followed by successful compilation; not all compiler error paths'}
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
