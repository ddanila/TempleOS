#!/usr/bin/env python3
"""Run a relocation-free guest-built 386 patch helper in Linux IA32 mode."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('module', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    module_path, out = args.module.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    inputs = [module_path, Path(__file__).resolve()]
    for name in ('as', 'ld', 'ndisasm'):
        path = shutil.which(name)
        if not path:
            raise ValueError('Missing host tool: ' + name)
        inputs.append(Path(path).resolve())
    pins = {str(p): sha(p) for p in inputs}
    report = {'result': 'running', 'input_sha256': pins,
              'scope': 'Extracted relocation-free 386 helper in Linux IA32 mode with synthetic records; not guest integration or 486 timing'}
    try:
        module = module_path.read_bytes()
        if len(module) < 32 or module[:4] != b'T32M':
            raise ValueError('Not a T32M module')
        total, code_bytes, count, records, strings = struct.unpack_from('<5I', module, 12)
        if total != len(module) or records != 32 + code_bytes or strings != records + count * 16 or strings > total:
            raise ValueError('Malformed module layout')
        entries, patches = [], []
        for i in range(count):
            kind, offset, name, length = struct.unpack_from('<4I', module, records + i * 16)
            if kind == 1:
                if name < strings or name + length > total:
                    raise ValueError('Malformed export')
                entries.append((offset, module[name:name + length].decode('ascii')))
            if kind in (2, 5, 6, 7):
                patches.append(offset)
        entries.sort()
        matches = [i for i, (_, name) in enumerate(entries) if name == 'I386ModuleWritePatched']
        if len(matches) != 1 or matches[0] + 1 >= len(entries):
            raise ValueError('Cannot bound patch helper')
        start, end = entries[matches[0]][0], entries[matches[0] + 1][0]
        if not 0 <= start < end <= code_bytes or any(start <= p < end for p in patches):
            raise ValueError('Helper contains a relocation or invalid bounds')
        helper = out / 'helper.bin'
        helper.write_bytes(module[32 + start:32 + end])
        disassembly = subprocess.check_output(['ndisasm', '-b', '32', str(helper)], text=True)
        if any(' call ' in line for line in disassembly.splitlines()):
            raise ValueError('Helper contains a call; standalone execution would need bindings')
        (out / 'helper.disasm').write_text(disassembly)
        asm = '''.section .data
.balign 4
header: .space 20
 .long 481
 .space 8
records: .space 7696
view: .long header,records,0,0,0
 .byte 0
 .space 512
canary: .long 0x13579bdf
.section .text
.global _start
_start:
 xor %esi,%esi
 lea records,%edi
fill:
 cmp $320,%esi
 jge filled
 movl $2,(%edi)
 imull $30,%esi,%eax
 addl $2,%eax
 movl %eax,4(%edi)
 addl $16,%edi
 incl %esi
 jmp fill
filled:
 movl $5,(%edi)
 movl $4094,4(%edi)
 movl $6,16(%edi)
 movl $8190,20(%edi)
 movl $7,32(%edi)
 movl $0xfffffffe,36(%edi)
 xor %esi,%esi
check:
 cmp $320,%esi
 jge done
 imull $30,%esi,%eax
 addl $2,%eax
 pushl $0
 pushl %eax
 pushl $0
 pushl $view
 call helper
 cmpl $1,%eax
 jne fail
 incl %esi
 jmp check
done:
 pushl $0
 pushl $2
 pushl $0
 pushl $view
 call helper
 cmpl $1,%eax
 jne fail
 pushl $0
 pushl $1
 pushl $0
 pushl $view
 call helper
 testl %eax,%eax
 jne fail
 cmpl $0x13579bdf,canary
 jne canary_fail
 xorl %ebx,%ebx
 jmp exit
fail:
 movl $1,%ebx
 jmp exit
canary_fail:
 movl $2,%ebx
exit:
 movl $1,%eax
 int $0x80
helper:
 .incbin "helper.bin"
'''
        # Requests cross page boundaries, go backwards and reach the U32 limit.
        boundary_checks = [(4094, 1), (4095, 1), (4096, 1), (4097, 1),
                           (8190, 1), (8191, 1), (8192, 1), (8193, 1),
                           (0xfffffffe, 1), (0xffffffff, 1), (0, 0),
                           (0xffffffff, 1)]
        checks = ''.join(f' pushl $0\n pushl ${offset}\n pushl $0\n pushl $view\n'
                         f' call helper\n cmpl ${expected},%eax\n jne fail\n'
                         for offset, expected in boundary_checks)
        asm = asm.replace('done:\n', 'done:\n' + checks)
        (out / 'probe.s').write_text(asm)
        subprocess.run(['as', '--32', '-o', 'probe.o', 'probe.s'], cwd=out, check=True)
        subprocess.run(['ld', '-m', 'elf_i386', '-o', 'probe', 'probe.o'], cwd=out, check=True)
        probe = subprocess.run([str(out / 'probe')], cwd=out, timeout=30)
        report['probe_exit_code'] = probe.returncode
        if probe.returncode == 2:
            raise ValueError('Bitmap canary changed')
        if probe.returncode:
            raise ValueError(f'Patch helper returned an unexpected result: {probe.returncode}')
        report.update(result='pass', helper_offset=start, helper_bytes=end-start,
                      helper_sha256=sha(helper), records=481, patch_checks=322 + len(boundary_checks))
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(Path(p).is_file() and sha(Path(p)) == h for p, h in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Execution inputs changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
