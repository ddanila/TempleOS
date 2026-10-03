#!/usr/bin/env python3
"""Compile and execute loader-required inline assembly using the guest compiler."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    # The NOP span exceeds the former 256-byte block limit and makes the
    # forward jump require a rel32 displacement.
    source = ('I64 NativeAsmIndex(){U32 value=0;U8 byte=7;asm {'
              'MOV EAX,3 MOV U32 &value[EBP],EAX '
              'ADD U32 &value[EBP],5 SUB U32 &value[EBP],1 '
              'MOV EDX,2 ADD U32 &value[EBP],EDX '
              'LEA ECX,U32 &byte[EBP] MOVZX EDX,U8 [ECX] '
              'PUSH EDX MOV EAX,1 SHL EAX,5 SUB EAX,EDX POP EDX '
              'ADD EAX,EDX AND EAX,255 ADD EAX,U32 &value[EBP] '
              'TEST EAX,EAX JZ I32 @@bad CMP EAX,41 JNE I32 @@bad '
              'JMP I32 @@done @@bad: MOV EAX,0 ' + 'NOP ' * 270 +
              '@@done: MOV U32 &value[EBP],EAX }return value;}'
              "I64 NativeAsmChars(){U32 value=0;U8 byte=0;asm {"
              "MOV EAX,0x536B7354 CMP EAX,'TskS' JNE I32 @@charbad "
              "MOV U32 &value[EBP],'TskS' MOV U8 &byte[EBP],'x' "
              "JMP I32 @@chardone @@charbad: MOV U32 &value[EBP],0 "
              "@@chardone: }return value==0x536B7354&&byte==120;}")
    # Stage a source file through bounded console commands; the prompt accepts
    # at most 255 bytes per input line.
    result = [(f'U8 *native_asm_source=CAlloc({len(source)+1});', [])]
    for offset in range(0, len(source), 160):
        chunk = json.dumps(source[offset:offset+160]).replace('@', chr(92) + 'x40')
        result.append((f'U0 AsmChunk{offset}(){{StrCpy(native_asm_source+{offset},{chunk});}}AsmChunk{offset};', []))
    result.extend([
        ('CDoc *native_asm_doc=DocNew("C:/NativeAsm.HC",Fs);', []),
        (f'I64 AsmEntry(){{CDocEntry *e=DocEntryNewTag(native_asm_doc,&native_asm_doc->head,native_asm_source);e->type=DOCT_TEXT;DocInsEntry(native_asm_doc,e);return StrLen(e->tag)=={len(source)};}}AsmEntry;', ['1']),
        ('DocWrite(native_asm_doc);', ['1']),
        ('DocDel(native_asm_doc);Free(native_asm_source);', []),
        ('#include "C:/NativeAsm.HC"', []),
        ('NativeAsmIndex;', ['41']), ('NativeAsmChars;', ['1']), ('6*7;', ['42']),
    ])
    assert all(len(command) <= 255 for command, _ in result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    report_path = args.out / 'result.json'
    report_path.unlink(missing_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    before = sha(args.disk)
    report = dict(result='fail', disk_sha256=before, cpu='486,-fpu', ram_mib=8,
                  accel='tcg', checker_sha256=sha(Path(__file__)),
                  scope='Guest-compiled inline assembly; loader-required forms, character immediates and blocks over 256 bytes')
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    try:
        report['console'] = runner(args.disk, args.out / 'console', cpu='486,-fpu',
                                   qmp_stdio=True, startup_check={
                                       'status': 'ok', 'answers': [], 'commands': commands()})
        report['result'] = 'pass'
    except Exception as exc:
        report['error'] = str(exc)
    report['source_disk_unchanged'] = sha(args.disk) == before
    if not report['source_disk_unchanged']:
        report['result'] = 'fail'
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report['result'] == 'pass' else 1)


if __name__ == '__main__':
    main()
