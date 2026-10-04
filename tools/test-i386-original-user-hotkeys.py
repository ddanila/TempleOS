#!/usr/bin/env python3
"""Original TempleOS keyboard decoder oracle for User creation shortcuts."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CASES = [('ctrl-alt-t', 0x14, True, False),
         ('ctrl-alt-escape', 1, True, False),
         ('plain-t', 0x14, False, False),
         ('plain-escape', 1, False, False),
         ('ctrl-alt-shift-t', 0x14, True, True),
         ('ctrl-alt-shift-escape', 1, True, True)]
SOURCE = '''class CHkDecoder{U0 (*decode)(U8 raw,Bool in_irq,U8 *last_raw,I64 *last_sc);};
CHkDecoder HkDecoder;
U8 HkLastRaw=0;I64 HkLastScan=0;
U0 HkReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 HkScan(U8 raw){(*HkDecoder.decode)(raw,FALSE,&HkLastRaw,&HkLastScan);}
I64 HkCount(){CTask *end=(&Gs->seth_task->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=Gs->seth_task->next_child_task;I64 n=0;while(c&&c!=end&&n<128){n++;c=c->next_sibling_task;}return n;}
Bool HkRun(I64 scan,Bool modifiers,Bool shift){
 I64 before=HkCount;CTask *last=Gs->seth_task->last_child_task,*previous=last->last_sibling_task,*created;Bool ok;
 if(before<0||before>=128)return FALSE;
 if(shift)HkScan(0x2A);if(modifiers){HkScan(0x1D);HkScan(0x38);}
 HkScan(scan);HkScan(scan|0x80);
 if(modifiers){HkScan(0xB8);HkScan(0x9D);}if(shift)HkScan(0xAA);
 created=last->last_sibling_task;
 if(modifiers&&!shift){ok=HkCount==before+1&&created!=previous;if(ok)ok=Kill(created);WinFocus(Fs);return ok&&HkCount==before;}
 return HkCount==before;
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    overlay = out / 'overlay'
    overlay.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker = sha(Path(__file__))
    checks = ''.join(
        f'if(ok&&!HkRun({scan},{str(modifiers).upper()},{str(shift).upper()}))'
        f'{{ok=FALSE;HkReport("FAIL {name}\\n");}}\n'
        for name, scan, modifiers, shift in CASES)
    source = SOURCE + 'HkReport("START original creation hotkeys\\n");\nCHashSrcSym *decoder=HashFind("KbdBuildSC",Gs->seth_task->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);Bool ok=decoder!=NULL;\nif(ok){if(decoder->type&HTT_FUN)HkDecoder.decode=decoder(CHashFun *)->exe_addr;else HkDecoder.decode=decoder(CHashExport *)->val;}else HkReport("FAIL decoder availability\\n");\n' + checks
    source += 'if(ok)HkReport("PASS original creation hotkeys\\n");HkReport("DONE original creation hotkeys\\n");\n'
    (overlay / 'Once.HC').write_text(source)
    report = {'result': 'fail', 'checker_sha256': checker,
              'source_sha256': hashlib.sha256(source.encode()).hexdigest(),
              'cases': [case[0] for case in CASES],
              'scope': 'Original KbdBuildSC non-IRQ make/break decoding, Ctrl-Alt-T/Esc User creation and child-list cleanup, plain/shift rejection; not QEMU hardware delivery, focus, typematic or port implementation'}
    try:
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original creation hotkeys\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original creation-hotkey verdict')
        if sha(Path(__file__)) != checker:
            raise ValueError('Checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
