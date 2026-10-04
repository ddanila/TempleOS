#!/usr/bin/env python3
"""Original/native public message posting, job metadata and wake flags."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def behavior_commands():
    definitions = [
        'Bool PostPop(CTask *t,I64 code,I64 a,I64 b){CJob *h=&t->srv_ctrl.next_waiting,*j=h->next;Bool ok;if(j==h)return FALSE;ok=j->job_code==JOBT_MSG&&j->msg_code==code&&j->aux1==a&&j->aux2==b&&j->ctrl==&t->srv_ctrl;QueRem(j);Free(j);return ok;}',
        'Bool PostFIFO(){I64 i;for(i=0;i<40;i++)Msg(MSG_CMD,i,~i);for(i=0;i<40;i++)if(!PostPop(Fs,MSG_CMD,i,~i))return FALSE;return Fs->srv_ctrl.next_waiting==(&Fs->srv_ctrl.next_waiting)(CJob *);}',
        'Bool PostPair(){Msg(MSG_KEY_DOWN_UP,51,52);return PostPop(Fs,MSG_KEY_DOWN,51,52)&&PostPop(Fs,MSG_KEY_UP,51,52);}',
        'Bool PostInvalid(){return !TaskMsg(NULL,NULL,MSG_CMD,1,2,0)&&!TaskMsg(Fs,0x80000000,MSG_CMD,1,2,0);}',
        'Bool PostMeta(){CJob *j=TaskMsg(Fs,Fs,MSG_CMD,0x100000001,-2,1<<JOBf_DONT_FILTER);Bool ok=j&&j->master_task==Fs&&MHeapCtrl(j)->mem_task!=Fs&&j->flags==1<<JOBf_DONT_FILTER;return ok&&PostPop(Fs,MSG_CMD,0x100000001,-2);}',
        'Bool PostWakeFlags(I64 f,I64 w){return Fs->task_flags==(f&~(1<<TASKf_IDLE|1<<TASKf_AWAITING_MSG))&&Fs->wake_jiffy==w;}',
        'Bool PostWake(){I64 f=Fs->task_flags,w=Fs->wake_jiffy;Bool ok;LBts(&Fs->task_flags,TASKf_IDLE);LBts(&Fs->task_flags,TASKf_AWAITING_MSG);PostMsg(Fs,MSG_CMD,61,62);ok=PostWakeFlags(f,w);Fs->task_flags=f;return ok&&PostPop(Fs,MSG_CMD,61,62);}',
    ]
    commands = [(source, []) for source in definitions]
    commands += [(name+';', ['1']) for name in ('PostFIFO','PostPair','PostInvalid','PostMeta','PostWake')]
    commands.append(('6*7;', ['42']))
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Posting contract exceeds the interactive line limit')
    return commands


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
    (out / 'result.json').unlink(missing_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker = sha(Path(__file__))
    commands = behavior_commands()
    if args.original:
        overlay = out / 'overlay'
        overlay.mkdir(exist_ok=True)
        source = '\n'.join(source for source, _ in commands[:7]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original public message posting\\n");
Bool ok=PostFIFO&&PostPair&&PostInvalid&&PostMeta&&PostWake;
if(ok)Report("PASS original public message posting\\n");
else Report("FAIL original public message posting\\n");
Report("DONE original public message posting\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original public message posting\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original public message verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': [('HashFind("MAlloc",Fs->hash_table,HTT_FUN)!=0;', ['1']),
                                                                       ('HashFind("TaskMsg",Fs->hash_table,HTT_FUN)!=0;', ['1'])] + commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Public message test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Public message checker changed during execution')
    report.update(checker_sha256=checker, cases=5,
                  scope='TaskMsg/PostMsg/Msg: 40-event FIFO, paired events, invalid task/master rejection, full-width metadata, system-heap ownership and idle/await wake flags; not scanning, routing or macro recording')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
