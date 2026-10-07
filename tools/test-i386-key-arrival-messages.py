#!/usr/bin/env python3
"""Check keyboard arrival timestamps through private and public message consumption."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(routing=False, macro=False):
    result = [
        ('#include "/Kernel/SymbolTypes.HH"', []),
        ('HashFind("I386PostKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM)!=0&&HashFind("I386ScanKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM)!=0;', ['1']),
        ('CHashExport *arrival_post=HashFind("I386PostKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM),*arrival_scan=HashFind("I386ScanKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM);', []),
        ('U0 (*ap)(CTask *t,I64 c,I64 a,I64 b,I64 f,I64 j)=arrival_post->val;', []),
        ('I64 (*ks)(I64 *a,I64 *b,I64 m,CTask *t,I64 *j)=arrival_scan->val;', []),
        ('I64 ka,kb,kj;', []),
        ('ap(Fs,2,65,123,0,100);Sleep(1500);I64 kc=ks(&ka,&kb,4,Fs,&kj);kc==2&&ka==65&&kb==123&&kj==100;', ['1']),
        ('PostMsg(Fs,2,66,321);I64 kd=ks(&ka,&kb,4,Fs,&kj);kd==2&&ka==66&&kb==321&&kj==-1;', ['1']),
        ('ap(Fs,2,67,234,0,200);I64 ke=ScanMsg(&ka,&kb,4);ke==2&&ka==67&&kb==234;', ['1']),
        ('I64 KH(){I64 f=GetRFlags,b;SetRFlags(f&~512);FlushMsgs;b=adam_task->data_heap->used_u8s;ap(Fs,2,65,0,0,100);ks(&ka,&kb,4,Fs,&kj);SetRFlags(f);return adam_task->data_heap->used_u8s==b;}', []),
        ('KH;', ['1']), ('KH;', ['1']), ('(GetRFlags&512)!=0;', ['1']), ('6*7;', ['42'])]


    if routing:
        prefixes=('class CMsgRoute{','CMsgRoute *MsgRoute=',
                  'U0 MsgRouteWorker(','Bool MsgRouteStart(',
                  'U0 MsgRouteLink(','U0 MsgRouteUnlink(','Bool MsgRouteStop(')
        definitions=runpy.run_path(str(ROOT/'tools/test-i386-public-messages.py'))['behavior_commands']()
        selected=[row for row in definitions if row[0].startswith(prefixes)]
        if len(selected)!=len(prefixes):
            raise ValueError('Public route setup definitions changed')
        result += selected
        result += [('Bool TimedRouteRead(CTask *t,I64 j){I64 a,b,k;return ks(&a,&b,4,t,&k)==2&&a==65&&b==123&&k==j&&ks(0,0,~1,t,0)==0;}', []),
                   ('MsgRouteStart;', ['1']), ('MsgRouteLink;', []),
                   ('ap(MsgRoute->a,2,65,123,0,777);TimedRouteRead(MsgRoute->b,777);', ['1']),
                   ('ap(MsgRoute->a,2,65,123,1<<JOBf_DONT_FILTER,888);TimedRouteRead(MsgRoute->a,888);', ['1']),
                   ('ap(MsgRoute->b,2,65,123,0,999);TimedRouteRead(MsgRoute->a,999);', ['1']),
                   ('MsgRouteStop;', ['1']), ('Free(MsgRoute);', []), ('6*7;', ['42'])]
    if macro:
        result += [
            ('Bool AMEmpty(){return sys_macro_head.next==&sys_macro_head&&sys_macro_head.last==&sys_macro_head;}', []),
            ('AMEmpty;', ['1']),
            ('U0 AMRecord(){LBts(&sys_semas[SEMA_RECORD_MACRO],0);ap(Fs,2,65,123,0,777);LBtr(&sys_semas[SEMA_RECORD_MACRO],0);}', []),
            ('AMRecord;ks(&ka,&kb,4,Fs,&kj)==2&&ka==65&&kb==123&&kj==777;', ['1']),
            ('CJob *am_job=sys_macro_head.next;am_job!=&sys_macro_head&&am_job->next==&sys_macro_head&&am_job->last==&sys_macro_head&&am_job->msg_code==2&&am_job->aux1==65&&am_job->aux2==123;', ['1']),
            ('PostMsg(Fs,am_job->msg_code,am_job->aux1,am_job->aux2);ks(&ka,&kb,4,Fs,&kj)==2&&ka==65&&kb==123&&kj==-1;', ['1']),
            ('QueRem(am_job);Free(am_job);AMEmpty;', ['1']),
            ('(GetRFlags&512)!=0;', ['1']), ('6*7;', ['42'])]

    if any(len(source.encode('ascii'))>255 for source,*_ in result):
        raise ValueError('Timed message contract exceeds interactive line limit')
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--writable-copy',action='store_true',help='Run on a fresh disk copy without QEMU snapshot temporary files')
    parser.add_argument('--routing',action='store_true',help='Also check timestamps across public input-filter routes')
    parser.add_argument('--macro',action='store_true',help='Check normal recording copy and public replay timestamp fallback')
    args=parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
    helper=ROOT/'tools/i386-kernel-input.py'
    paths=[args.disk,helper,Path(__file__)]
    if args.routing:paths.append(ROOT/'tools/test-i386-public-messages.py')
    inputs={str(path.resolve()):sha(path) for path in paths}
    report=dict(result='running',input_sha256=inputs,
                scope='Timed message survives 1500ms delay; public PostMsg fallback, public ScanMsg arguments, exact root heap cleanup twice and IF restore; not all keyboard/filter/macro behavior')
    if args.routing:
        report['scope'] += '; also timed forward filter, bypass and backward routing with worker retirement'
    if args.macro:
        report['scope'] += '; also normal macro recording payload/ring, timed original delivery, public replay fallback and cleanup; not macro playback scheduling'
    disk=args.disk
    if args.writable_copy:
        disk=args.out/'working.img'
        shutil.copyfile(args.disk,disk)
    report['disk_policy']='writable copy' if args.writable_copy else 'QEMU snapshot'
    try:
        report['behavior']=runpy.run_path(str(helper))['run_input'](
            disk,args.out/'behavior',cpu='486,-fpu',qmp_stdio=True,
            snapshot=not args.writable_copy,
            startup_check={'status':'ok','answers':[],'commands':commands(args.routing,args.macro)})
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if any(sha(Path(p))!=digest for p,digest in inputs.items()):
            report.update(result='fail',error='Arrival-message fixture inputs changed')
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
