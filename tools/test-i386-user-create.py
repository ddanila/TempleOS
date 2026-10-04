#!/usr/bin/env python3
"""Original/native User creation, formatted startup command and child cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DEFINITIONS = [
    'CTask *UserProbeTask,*UserProbeCaller;I64 UserProbeSeen=0;',
    'Bool UserProbeHas(){CTask *end=(&Gs->seth_task->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=Gs->seth_task->next_child_task;I64 n=0;while(c&&c!=end&&n++<128){if(c==UserProbeTask)return TRUE;c=c->next_sibling_task;}return FALSE;}',
    'Bool UserProbeWait(){I64 end=cnts.jiffies+2000;while(UserProbeSeen!=42&&cnts.jiffies<end)Yield;return UserProbeSeen==42&&UserProbeCaller==UserProbeTask;}',
    'Bool UserProbeStart(Bool f){UserProbeSeen=0;UserProbeCaller=NULL;if(f)UserProbeTask=User("*(0x%X)(I64 *)=42;*(0x%X)(CTask **)=Fs;\\n",&UserProbeSeen,&UserProbeCaller);else UserProbeTask=User;return UserProbeTask!=NULL&&UserProbeTask!=Fs&&UserProbeHas;}',
    'Bool UserProbeStop(){Bool ok=Kill(UserProbeTask);WinFocus(Fs);return ok&&!UserProbeHas;}',
    'Bool UserProbePartial(){UserProbeSeen=0;UserProbeCaller=NULL;UserProbeTask=User("*(0x%X)(I64 *)=42;*(0x%X)(CTask **)=Fs;",&UserProbeSeen,&UserProbeCaller);return UserProbeTask!=NULL&&UserProbeTask!=Fs&&UserProbeHas;}',
    'Bool UserProbeIdle(){I64 end=cnts.jiffies+250;while(cnts.jiffies<end)Yield;return UserProbeSeen==0&&UserProbeCaller==NULL;}',
    'Bool UserProbeFlush(){XTalk(UserProbeTask,"\\n");return UserProbeWait;}',
    'Bool UserProbeModulo(){UserProbeSeen=0;UserProbeCaller=NULL;UserProbeTask=User("*(0x%X)(I64 *)=6*7%%%%50;*(0x%X)(CTask **)=Fs;\\n",&UserProbeSeen,&UserProbeCaller);return UserProbeTask!=NULL&&UserProbeHas;}',


    'U8 *UserProbeLongText(){U8 *s=MAlloc(1024);MemSet(s,32,512);StrPrint(s+512,"*(0x%X)(I64 *)=42;*(0x%X)(CTask **)=Fs;\\n",&UserProbeSeen,&UserProbeCaller);return s;}',
    'Bool UserProbeLong(){U8 *s=UserProbeLongText;UserProbeSeen=0;UserProbeCaller=NULL;UserProbeTask=User(s);Free(s);return UserProbeTask!=NULL&&UserProbeHas;}',
]

CASES = [('UserProbeStart(FALSE);', ['1']), ('UserProbeStop;', ['1']),
         ('UserProbeStart(TRUE);', ['1']), ('UserProbeWait;', ['1']),
         ('UserProbeStop;', ['1']),
         ('UserProbePartial;', ['1']), ('UserProbeIdle;', ['1']),
         ('UserProbeFlush;', ['1']), ('UserProbeStop;', ['1']),
         ('UserProbeModulo;', ['1']), ('UserProbeWait;', ['1']),
         ('UserProbeStop;', ['1']),
         ('UserProbeLong;', ['1']), ('UserProbeWait;', ['1']),
         ('UserProbeStop;', ['1']),
         ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == (args.disk is not None):
        parser.error('Specify either --original or an i386 disk')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker = sha(Path(__file__))
    report = dict(result='fail', checker_sha256=checker,
                  scope='User empty/formatted/partial startup, newline completion through XTalk, double-format percent escaping, startup input over 512 bytes, execution in child, child-list cleanup; not hotkeys, window layout or exhaustive resource recovery')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir(exist_ok=True)
            source = '\n'.join(DEFINITIONS) + '\n'
            (overlay / 'Definitions.HC').write_text(source)
            checks = '\n'.join(
                'if(ok&&(' + command[:-1] + ')!=' + expected[0] +
                '){ok=FALSE;Report("CASE ' + str(index) + '\\n");}'
                for index, (command, expected) in enumerate(CASES))
            (overlay / 'Once.HC').write_text(
                'U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}' + '\n' +
                '#include "T:/Definitions.HC"\nReport("START original User creation\\n");\n' +
                'Bool ok=TRUE;\n' + checks + '\n' +
                'if(ok)Report("PASS original User creation\\n");' +
                'else Report("FAIL original User creation\\n");\n' +
                'Report("DONE original User creation\\n");\n')
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                            'build/rebuild-test/overlay', '--overlay', str(overlay),
                            '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                            str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
            if 'PASS original User creation\n' not in (out / 'original/debug.log').read_text():
                raise ValueError('Missing original User verdict')
            report.update(platform='original x64 TempleOS',
                          definitions_sha256=hashlib.sha256(source.encode()).hexdigest())
        else:
            report['disk_sha256'] = sha(args.disk)
            commands = [('HashFind("User",Fs->hash_table,HTT_FUN)!=0;', ['1'])]
            commands += [(source, []) for source in DEFINITIONS] + CASES
            if any(len(source)>255 for source, _ in commands):
                raise ValueError('User fixture exceeds interactive line limit')
            runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
            report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
                qmp_stdio=True, startup_check={'status':'ok','answers':[], 'commands':commands})
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        if args.disk:
            report['source_disk_unchanged'] = sha(args.disk)==report.get('disk_sha256')
            if not report['source_disk_unchanged']:
                report.update(result='fail', error='Source disk changed')
        if sha(Path(__file__)) != checker:
            report.update(result='fail', error='Checker changed during execution')
        (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
