#!/usr/bin/env python3
"""Original/native public message ordering, filtering, paired events and task delivery."""
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
        'Bool MsgCtrl(CTask *t=NULL){CJobCtrl *c;if(!t)t=Fs;c=&t->srv_ctrl;return !c->flags&&c->next_waiting==(&c->next_waiting)(CJob *)&&c->last_waiting==c->next_waiting&&c->next_done==(&c->next_done)(CJob *)&&c->last_done==c->next_done;}',
        'Bool MsgFIFO(){I64 i,a,b;FlushMsgs;for(i=0;i<40;i++)Msg(MSG_CMD,i,~i);for(i=0;i<40;i++){if(ScanMsg(&a,&b)!=MSG_CMD||a!=i||b!=~i)return FALSE;}return ScanMsg(&a,&b)==0&&a==0&&b==0;}',
        'Bool MsgMask(){I64 a,b;FlushMsgs;Msg(MSG_CMD,11,12);Msg(MSG_KEY_DOWN,21,22);Msg(MSG_CMD,31,32);return ScanMsg(&a,&b,1<<MSG_KEY_DOWN)==MSG_KEY_DOWN&&a==21&&b==22&&ScanMsg(&a,&b)==MSG_CMD&&a==31&&b==32&&ScanMsg==0;}',
        'Bool MsgPair(){I64 a,b;FlushMsgs;Msg(-MSG_KEY_DOWN,41,42);return ScanMsg(&a,&b)==MSG_KEY_DOWN&&a==41&&b==42&&ScanMsg(&a,&b)==MSG_KEY_UP&&a==41&&b==42&&ScanMsg==0;}',
        'Bool MsgFlush(){I64 a=99,b=99;FlushMsgs;Msg(MSG_CMD,1,2);Msg(MSG_CMD,3,4);return FlushMsgs==2&&ScanMsg(&a,&b)==0&&a==0&&b==0;}',
        'I64 MsgWorkerResult=0;',
        'U0 MsgWorker(U8 *data){I64 a,b;if(!MsgCtrl){MsgWorkerResult=-2;return;}if(GetMsg(&a,&b)==MSG_CMD&&a==51&&b==52)MsgWorkerResult=1;else MsgWorkerResult=-1;}',
        'Bool MsgTask(){CTask *t;I64 end;t=Spawn(&MsgWorker,0,"Messages",-1,Fs,8192);if(!t)return FALSE;Yield;PostMsg(t,MSG_CMD,51,52);end=cnts.jiffies+2000;while(!MsgWorkerResult&&cnts.jiffies<end)Yield;return MsgWorkerResult==1;}',
        'class CMsgRoute{CTask *a,*b;I64 retired;Bool done;};',
        'CMsgRoute *MsgRoute=CAlloc(sizeof(CMsgRoute));',
        'U0 MsgRouteWorker(U8 *data){while(!MsgRoute->done)Yield;MsgRoute->retired++;}',
        'Bool MsgRouteStart(){MsgRoute->a=Spawn(&MsgRouteWorker,0,"RouteA",-1,Fs,8192);MsgRoute->b=Spawn(&MsgRouteWorker,0,"RouteB",-1,Fs,8192);return MsgRoute->a&&MsgRoute->b;}',
        'U0 MsgRouteLink(){CTask *a=MsgRoute->a,*b=MsgRoute->b;a->next_input_filter_task=a->last_input_filter_task=b;b->next_input_filter_task=b->last_input_filter_task=a;LBts(&a->task_flags,TASKf_FILTER_INPUT);LBts(&b->task_flags,TASKf_INPUT_FILTER_TASK);}',
        'Bool MsgRouteRead(CTask *t,I64 x,I64 y){I64 a,b;return ScanMsg(&a,&b,~1,t)==MSG_CMD&&a==x&&b==y&&ScanMsg(NULL,NULL,~1,t)==0;}',
        'Bool MsgFilter(){PostMsg(MsgRoute->a,MSG_CMD,61,62);return MsgRouteRead(MsgRoute->b,61,62)&&ScanMsg(NULL,NULL,~1,MsgRoute->a)==0;}',
        'Bool MsgBypass(){PostMsg(MsgRoute->a,MSG_CMD,71,72,1<<JOBf_DONT_FILTER);return MsgRouteRead(MsgRoute->a,71,72)&&ScanMsg(NULL,NULL,~1,MsgRoute->b)==0;}',
        'Bool MsgBackward(){PostMsg(MsgRoute->b,MSG_CMD,81,82);return MsgRouteRead(MsgRoute->a,81,82)&&ScanMsg(NULL,NULL,~1,MsgRoute->b)==0;}',
        'U0 MsgRouteUnlink(){CTask *a=MsgRoute->a,*b=MsgRoute->b;LBtr(&a->task_flags,TASKf_FILTER_INPUT);LBtr(&b->task_flags,TASKf_INPUT_FILTER_TASK);a->next_input_filter_task=a->last_input_filter_task=a;b->next_input_filter_task=b->last_input_filter_task=b;}',
        'Bool MsgRouteStop(){I64 end=cnts.jiffies+2000;MsgRouteUnlink;MsgRoute->done=TRUE;while(MsgRoute->retired!=2&&cnts.jiffies<end)Yield;return MsgRoute->retired==2;}',
        'U0 MsgPopupLink(){MsgRouteUnlink;MsgRoute->a->popup_task=MsgRoute->b;MsgRoute->b->parent_task=MsgRoute->a;}',
        'Bool MsgPopupFall(){MsgRouteUnlink;PostMsg(MsgRoute->a,MSG_CMD,91,92);MsgPopupLink;return MsgRouteRead(MsgRoute->b,91,92);}',
        'Bool MsgPopupReject(){PostMsg(MsgRoute->a,MSG_CMD,101,102);return ScanMsg(NULL,NULL,~1,MsgRoute->a)==0&&ScanMsg(NULL,NULL,~1,MsgRoute->b)==0;}',
        'Bool MsgPopupOwn(){PostMsg(MsgRoute->b,MSG_CMD,111,112);return MsgRouteRead(MsgRoute->b,111,112);}',
        'Bool MsgPopupWoke(){CTask *a=MsgRoute->a,*b=MsgRoute->b;Bool ok=!Bt(&a->task_flags,TASKf_AWAITING_MSG)&&!Bt(&b->task_flags,TASKf_AWAITING_MSG);LBtr(&a->task_flags,TASKf_FILTER_INPUT);return ok&&MsgRouteRead(b,121,122);}',
        'Bool MsgPopupWake(){CTask *a=MsgRoute->a,*b=MsgRoute->b;LBts(&a->task_flags,TASKf_FILTER_INPUT);LBts(&a->task_flags,TASKf_AWAITING_MSG);LBts(&b->task_flags,TASKf_AWAITING_MSG);PostMsg(a,MSG_CMD,121,122,1<<JOBf_DONT_FILTER);return MsgPopupWoke;}',
        'U0 MsgPopupUnlink(){MsgRoute->a->popup_task=NULL;MsgRoute->b->parent_task=Fs;}',
        'CJob *MsgCallJob;',
        'I64 MsgCall(U8 *data){return 42;}',
        'U0 MsgCallQueue(){MsgCallJob=CAlloc(sizeof(CJob));MsgCallJob->ctrl=&Fs->srv_ctrl;MsgCallJob->job_code=JOBT_CALL;MsgCallJob->addr=&MsgCall;QueIns(MsgCallJob,Fs->srv_ctrl.last_waiting);}',
        'Bool MsgCallDone(){return Fs->srv_ctrl.next_done==MsgCallJob&&MsgCallJob->res==42&&Bt(&MsgCallJob->flags,JOBf_DISPATCHED)&&Bt(&MsgCallJob->flags,JOBf_DONE);}',
        'Bool MsgCallScan(){I64 a,b;FlushMsgs;MsgCallQueue;Msg(MSG_CMD,131,132);return ScanMsg(&a,&b)==MSG_CMD&&a==131&&b==132&&MsgCallDone;}',
        'U0 MsgCallFree(){QueRem(MsgCallJob);Free(MsgCallJob);}',
    ]
    commands = [(source, []) for source in definitions]
    commands += [(name+';', ['1']) for name in ('MsgCtrl','MsgFIFO','MsgMask','MsgPair','MsgFlush','MsgTask')]
    commands += [('MsgRouteStart;', ['1']), ('MsgRouteLink;', []), ('MsgFilter;', ['1']),
                 ('MsgBypass;', ['1']), ('MsgBackward;', ['1']), ('MsgPopupFall;', ['1']), ('MsgPopupReject;', ['1']),
                 ('MsgPopupOwn;', ['1']), ('MsgPopupWake;', ['1']), ('MsgPopupUnlink;', []), ('MsgRouteStop;', ['1']),
                 ('Free(MsgRoute);', [])]
    commands += [('MsgCallScan;', ['1']), ('MsgCallFree;', [])]
    commands.append(('6*7;', ['42']))
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Message contract exceeds the interactive line limit')
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
        source = '\n'.join(source for source, _ in commands[:32]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original public messages\\n");
Bool ok=MsgCtrl&&MsgFIFO&&MsgMask&&MsgPair&&MsgFlush&&MsgTask;
if(ok){ok=MsgRouteStart;if(ok){MsgRouteLink;ok=MsgFilter&&MsgBypass&&MsgBackward&&MsgPopupFall&&MsgPopupReject&&MsgPopupOwn&&MsgPopupWake;MsgPopupUnlink;if(!MsgRouteStop)ok=FALSE;}}
Free(MsgRoute);
if(ok){ok=MsgCallScan;MsgCallFree;}
if(ok)Report("PASS original public messages\\n");
else Report("FAIL original public messages\\n");
Report("DONE original public messages\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original public messages\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original public message verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': [('HashFind("MAlloc",Fs->hash_table,HTT_FUN)!=0;', ['1']),
                                                                       ('HashFind("Msg",Fs->hash_table,HTT_FUN)!=0;', ['1'])] + commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Public message test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Public message checker changed during execution')
    report.update(checker_sha256=checker, cases=14,
                  scope='Public messages: root/child empty job rings/flags, 40-event FIFO, destructive mask filtering, negative-code down/up pair, FlushMsgs count and empty outputs, PostMsg/GetMsg child delivery; forward input-filter routing, DONT_FILTER bypass and backward filter posting; popup parent fallback, parent-post rejection, own delivery and popup wake flags; CALL job dispatch/completion before message scan; not EXE_STR/SPAWN jobs, macro recording or allocation recovery')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
