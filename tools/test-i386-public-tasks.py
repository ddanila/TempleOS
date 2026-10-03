#!/usr/bin/env python3
"""Public Spawn/Exit lifecycle contract, independent of private scheduler APIs."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

ROOT = Path(__file__).resolve().parents[1]
PUBLIC = runpy.run_path(str(ROOT / 'tools/test-i386-required-services.py'))
REQUIRED = ('Spawn', 'Exit', 'Yield', 'Sleep', 'TaskQueIns')


def assess_presence(log):
    values = {}
    for name in PUBLIC['CONTROLS'] + REQUIRED:
        found = re.findall(r'^M7 SERVICE ' + name + r' ([01])$', log, re.M)
        if len(found) != 1:
            return {'result': 'invalid', 'reason': f'Missing or repeated observation: {name}'}
        values[name] = int(found[0])
    if any(values[name] != 1 for name in PUBLIC['CONTROLS']):
        return {'result': 'invalid', 'reason': 'Public lookup controls failed'}
    missing = [name for name in REQUIRED if not values[name]]
    return {'result': 'fail' if missing else 'pass', 'missing': missing, 'functions': values}


def behavior_commands():
    commands = [
        ('class CTaskLifeProbe{CTask *parent,*child;I64 stage,errors,explicit_exit;};', []),
        ('I64 LifeParentVisible=39;', []),
        ('Bool LifeEmpty(CTask *t){return t->next_child_task==(&t->next_child_task)(U8 *)-offset(CTask.next_sibling_task)&&t->last_child_task==t->next_child_task;}', []),
        ('Bool LifeHeaps(CTask *t,CTask *p){return t->code_heap&&t->data_heap&&t->data_heap!=p->data_heap&&t->data_heap->mem_task==t&&t->code_heap->mem_task==t&&t->data_heap->bp==p->data_heap->bp;}', []),
        ('Bool LifeCwd(CTask *t,CTask *p){return t->cur_dv==p->cur_dv&&t->cur_dir&&t->cur_dir!=p->cur_dir&&!StrCmp(t->cur_dir,p->cur_dir);}', []),
        ('Bool LifeSymbols(CTask *t,CTask *p){return t->hash_table!=p->hash_table&&t->hash_table->next==p->hash_table&&HashFind("LifeParentVisible",t->hash_table,HTT_GLBL_VAR)!=0;}', []),
        ('U0 LifeWork(U8 *data){CTaskLifeProbe *p=data;p->stage=1;if(Fs!=p->child||Fs->parent_task!=p->parent||!LifeHeaps(Fs,p->parent)||!LifeCwd(Fs,p->parent)||!LifeSymbols(Fs,p->parent))p->errors|=1;MAlloc(2048);Sleep(10);p->stage=2;}', []),
        ('U0 LifeExit(U8 *data){CTaskLifeProbe *p=data;LifeWork(data);Exit;p->stage=3;}', []),
        ('CTaskLifeProbe *LifeState=CAlloc(sizeof(CTaskLifeProbe));', []),
        ('Bool LifeRecord(){CTask *t=LifeState->child;return t->addr==t&&t->task_signature==TASK_SIGNATURE_VAL&&t->task_num>0&&t->gs==Fs->gs&&t->stk->stk_size==8192&&!StrCmp(t->task_name,"Life")&&!StrCmp(t->task_title,"Life");}', []),
        ('Bool LifeChild(){CTask *t=LifeState->child;return Fs->next_child_task==t&&Fs->last_child_task==t&&t->last_sibling_task->next_sibling_task==t&&t->next_sibling_task->last_sibling_task==t;}', []),
        ('Bool LifeStart(Bool quit){CTaskLifeProbe *p=LifeState;p->parent=Fs;p->stage=p->errors=0;p->child=Spawn(quit?&LifeExit:&LifeWork,p,"Life",-1,Fs,8192);return p->child&&LifeRecord&&LifeChild;}', []),
        ('Bool LifeFinish(){I64 end=cnts.jiffies+2000;while(!LifeEmpty(Fs)&&cnts.jiffies<end)Yield;return LifeEmpty(Fs)&&LifeState->stage==2&&!LifeState->errors;}', []),
        ('LifeEmpty(Fs);', ['1']),
        ('LifeStart(FALSE);', ['1']),
        ('LifeFinish;', ['1']),
        ('LifeStart(TRUE);', ['1']),
        ('LifeFinish;', ['1']),
        ('Bool LifeRepeat(){I64 i,n=Fs->data_heap->bp->used_u8s,r=Fs->data_heap->bp->alloced_u8s;for(i=0;i<20;i++)if(!LifeStart(i&1)||!LifeFinish||Fs->data_heap->bp->used_u8s!=n)return FALSE;return Fs->data_heap->bp->alloced_u8s==r;}', []),
        ('LifeRepeat;', ['1']),
        ('Bool LifeHas(CTask *p,CTask *t){CTask *end=(&p->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=p->next_child_task;I64 n=0;while(c&&c!=end&&n++<128){if(c==t)return TRUE;c=c->next_sibling_task;}return FALSE;}', []),
        ('U0 LifeDefaultWork(U8 *data){CTaskLifeProbe *p=data;if(Fs!=p->child||Fs->parent_task!=Gs->seth_task||!LifeHeaps(Fs,p->parent)||!LifeCwd(Fs,p->parent))p->errors=1;MAlloc(2048);p->stage=2;}', []),
        ('Bool LifeDefaultRecord(){CTask *t=LifeState->child;return t&&t->stk->stk_size==MEM_DFT_STK&&!StrCmp(t->task_name,"Unnamed Task")&&!StrCmp(t->task_title,t->task_name);}', []),
        ('Bool LifeDefaultStart(){CTaskLifeProbe *p=LifeState;p->parent=Gs->seth_task;p->stage=p->errors=0;if(!p->parent)return FALSE;p->child=Spawn(&LifeDefaultWork,p);return LifeDefaultRecord;}', []),
        ('Bool LifeDefaultFinish(){CTaskLifeProbe *p=LifeState;I64 end=cnts.jiffies+2000;while(LifeHas(p->parent,p->child)&&cnts.jiffies<end)Yield;return !LifeHas(p->parent,p->child)&&p->stage==2&&!p->errors;}', []),
        ('LifeDefaultStart;', ['1']),
        ('LifeDefaultFinish;', ['1']),
        ('U0 LifeNestedLeaf(U8 *data){CTaskLifeProbe *p=data;if(Fs!=p->child||Fs->parent_task!=p->parent||!LifeHeaps(Fs,p->parent)||!LifeSymbols(Fs,p->parent))p->errors|=4;MAlloc(2048);p->stage=2;}', []),
        ('Bool LifeNestedRecord(){CTask *t=LifeState->child;return t&&t->parent_task==LifeState->parent&&t->hash_table->next==LifeState->parent->hash_table&&LifeHas(LifeState->parent,t);}', []),
        ('U0 LifeNestedCreator(U8 *data){CTaskLifeProbe *p=data;p->child=Spawn(&LifeNestedLeaf,p,"Nested",-1,p->parent,8192);if(!LifeNestedRecord)p->errors|=2;}', []),
        ('Bool LifeNestedStart(){CTaskLifeProbe *p=LifeState;p->parent=Fs;p->stage=p->errors=0;p->child=0;return Spawn(&LifeNestedCreator,p,"Creator",-1,Fs,8192)!=0;}', []),
        ('LifeNestedStart;', ['1']),
        ('LifeFinish;', ['1']),
        ('Bool LifePendingStart(){CTaskLifeProbe *p=LifeState;p->parent=Fs;p->stage=p->errors=0;p->child=Spawn(&LifeWork,p,"Pending",-1,Fs,8192,0);return p->child&&p->child->next_task==p->child&&p->child->last_task==p->child&&!LifeHas(Fs,p->child);}', []),
        ('Bool LifePendingIdle(){I64 i;for(i=0;i<20;i++)Yield;return !LifeState->stage&&!LifeState->errors&&!LifeHas(Fs,LifeState->child);}', []),
        ('U0 LifePendingActivate(){TaskQueIns(LifeState->child);}', []),
        ('Bool LifePendingFinish(){I64 i,end=cnts.jiffies+2000;while(LifeState->stage!=2&&cnts.jiffies<end)Yield;for(i=0;i<20;i++)Yield;return LifeState->stage==2&&!LifeState->errors&&LifeEmpty(Fs);}', []),
        ('Bool LifePendingRun(){I64 n=Fs->data_heap->bp->used_u8s,r=Fs->data_heap->bp->alloced_u8s;if(!LifePendingStart||!LifePendingIdle)return FALSE;LifePendingActivate;return LifePendingFinish&&Fs->data_heap->bp->used_u8s==n&&Fs->data_heap->bp->alloced_u8s==r;}', []),
        ('LifePendingRun;', ['1']),
        ('Bool LifePendingRepeat(){I64 i;for(i=0;i<20;i++)if(!LifePendingRun)return FALSE;return TRUE;}', []),
        ('LifePendingRepeat;', ['1']),
        ('Free(LifeState);', []),
        ('6*7;', ['42']),
    ]
    if any(len(command.encode('ascii')) > 255 for command, _ in commands):
        raise ValueError('Public task contract exceeds the interactive line limit')
    return commands


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk_hash = sha(args.disk)
    checker_hash = sha(Path(__file__))
    publication_hash = sha(ROOT / 'tools/test-i386-required-services.py')
    commands = behavior_commands()
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    presence = runner(args.disk, out / 'presence', cpu='486,-fpu', qmp_stdio=True,
                      startup_check={'status': 'ok', 'answers': [], 'commands':
                                     PUBLIC['observation_commands'](PUBLIC['CONTROLS'] + REQUIRED)})
    report = assess_presence((out / 'presence/debug.log').read_text())
    report.update(cpu='486,-fpu', ram_mib=8, accel='tcg', disk_sha256=disk_hash,
                  presence_console=presence, checker_sha256=checker_hash,
                  publication_checker_sha256=publication_hash,
                  scope='Public task creation, explicit exit, entry return and reclamation; not multiple terminals')
    if report['result'] == 'pass':
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                                    startup_check={'status': 'ok', 'answers': [], 'commands': commands})
    if sha(args.disk) != disk_hash:
        raise ValueError('Task test changed source disk')
    if sha(Path(__file__)) != checker_hash or sha(ROOT / 'tools/test-i386-required-services.py') != publication_hash:
        raise ValueError('Task test checker changed during the run')
    report['source_disk_unchanged'] = True
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report['result'] == 'pass' else 1 if report['result'] == 'fail' else 2)


if __name__ == '__main__':
    main()
