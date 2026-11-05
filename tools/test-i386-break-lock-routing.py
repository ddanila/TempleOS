#!/usr/bin/env python3
"""Compare public pending-break Shift-Esc routing and first task entry."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
ROOT=Path(__file__).resolve().parents[1]
EXPECTED=[1,1,0,1,0,0,1,1,1,1,1]+[1,1,0,1,1,0,1,1,1,0,1,1]+[1,1,0,1,1,0]


def definitions():
 return '\nI64 RoutingPhase,RoutingException,RoutingSeen,RoutingArg1,RoutingArg2,RoutingFlags,RoutingAfter,RoutingFreshEntered;\nBool RoutingStop;\nU0 RoutingWorker(U8 *data)\n{\n I64 code;\n FlushMsgs;if(data)RoutingPhase=-1;else RoutingPhase=1;\n try{\n  while(!RoutingStop){\n   Yield;code=ScanMsg(&RoutingArg1,&RoutingArg2,1<<MSG_KEY_DOWN);\n   if(code==MSG_KEY_DOWN){RoutingSeen=1;RoutingAfter=1;break;}\n  }\n }catch{RoutingException=Fs->except_ch;Fs->catch_except=TRUE;}\n RoutingFlags=Fs->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK);\n RoutingPhase=2;\n}\nU0 RoutingFresh(U8 *data)\n{if(data)RoutingFreshEntered=2;else RoutingFreshEntered=1;}\nI64 *BreakLockRows()\n{\n I64 *rows=CAlloc(ROWS*8),i=0,arg1=0,arg2=0,exception=0,after=0,result=0,code,end;\n I64 mask=1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK|1<<TASKf_BREAK_TO_SHIFT_ESC|\n  1<<TASKf_FILTER_INPUT|1<<TASKf_INPUT_FILTER_TASK,saved=Fs->task_flags&mask,flags=GetRFlags;\n CTask *child;\n FlushMsgs;Fs->task_flags&=~mask;Bts(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC);\n rows[i++]=BreakLock;Bts(&Fs->task_flags,TASKf_PENDING_BREAK);\n try{result=BreakUnlock;after=1;}catch{exception=Fs->except_ch;Fs->catch_except=TRUE;}\n rows[i++]=result;rows[i++]=exception;rows[i++]=after;\n rows[i++]=Bt(&Fs->task_flags,TASKf_BREAK_LOCKED);rows[i++]=Bt(&Fs->task_flags,TASKf_PENDING_BREAK);\n code=ScanMsg(&arg1,&arg2,1<<MSG_KEY_DOWN);rows[i++]=code==MSG_KEY_DOWN;\n rows[i++]=arg1==CH_SHIFT_ESC;rows[i++]=arg2==0x20100000201;\n rows[i++]=ScanMsg(NULL,NULL,1<<MSG_KEY_DOWN)==0;rows[i++]=(GetRFlags&512)==(flags&512);\n RoutingStop=FALSE;RoutingPhase=RoutingException=RoutingSeen=RoutingArg1=RoutingArg2=RoutingFlags=RoutingAfter=0;\n child=Spawn(&RoutingWorker,NULL,"shift break",Gs->num,Fs,8192);\n if(!child)return rows;\n end=cnts.jiffies+5000;while(!RoutingPhase && cnts.jiffies<end)Yield;\n rows[i++]=RoutingPhase==1;Suspend(child,TRUE);\n child->task_flags&=~mask;Bts(&child->task_flags,TASKf_BREAK_TO_SHIFT_ESC);\n BreakLock(child);Bts(&child->task_flags,TASKf_PENDING_BREAK);\n rows[i++]=BreakUnlock(child);rows[i++]=Bt(&child->task_flags,TASKf_PENDING_BREAK);rows[i++]=IsSuspended(child);\n Suspend(child,FALSE);\n end=cnts.jiffies+5000;while(TaskValidate(child) && cnts.jiffies<end)Yield;\n rows[i++]=!TaskValidate(child);rows[i++]=RoutingException;rows[i++]=RoutingSeen;\n rows[i++]=RoutingArg1==CH_SHIFT_ESC;rows[i++]=RoutingArg2==0x20100000201;\n rows[i++]=RoutingFlags;rows[i++]=RoutingAfter;rows[i++]=(GetRFlags&512)==(flags&512);\n if(TaskValidate(child)){RoutingStop=TRUE;Kill(child);}\n RoutingFreshEntered=0;child=Spawn(&RoutingFresh,NULL,"fresh shift",Gs->num,Fs,8192,0);\n if(!child)return rows;\n rows[i++]=RoutingFreshEntered==0;child->task_flags&=~mask;Bts(&child->task_flags,TASKf_BREAK_TO_SHIFT_ESC);\n BreakLock(child);Bts(&child->task_flags,TASKf_PENDING_BREAK);\n rows[i++]=BreakUnlock(child);rows[i++]=Bt(&child->task_flags,TASKf_PENDING_BREAK);\n rows[i++]=child->rip==(&Break+0)(U64);TaskQueIns(child);\n end=cnts.jiffies+5000;while(TaskValidate(child) && cnts.jiffies<end)Yield;\n rows[i++]=!TaskValidate(child);rows[i++]=RoutingFreshEntered;\n if(TaskValidate(child))Kill(child);\n Fs->task_flags=Fs->task_flags&~mask|saved;\n return rows;\n}\n'.replace('ROWS',str(len(EXPECTED)))


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path,nargs='?');p.add_argument('--original',action='store_true');p.add_argument('--out',type=Path,required=True);args=p.parse_args()
 if args.original==(args.disk is not None):p.error('Use either --original or a native disk')
 out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 if args.disk:paths.append(args.disk.resolve())
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',expected=EXPECTED,input_sha256=pins,scope='Actual public pending-break routing with Shift-Esc enabled: current and suspended foreign tasks, exact key message/scan code, IRQ preservation and immediate flags; fresh unqueued task RIP replacement must exit without entering displaced user code. Other foreign kernel wait classes remain unqualified.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(definitions())
   source='''U0 BLReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
BLReport("ADAM SERVER READY\\n");
I64 *rows=BreakLockRows;U8 *notice=MStrPrint("EXPORT break-routing.bin %X %X\\n",rows,ROWS*8);BLReport(notice);BLReport("DONE original break routing\\n");
'''
   (overlay/'Once.HC').write_text(source.replace('ROWS',str(len(EXPECTED))))
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   report['records']=list(struct.unpack(f'<{len(EXPECTED)}q',(out/'guest/break-routing.bin').read_bytes()))
   if report['records']!=EXPECTED:raise ValueError('Original public break-lock behavior differs')
  else:
   source=definitions()+'\nI64 BreakRoutingStage;\nI64 BreakRoutingExpected[ROWS]={' + ','.join(map(str,EXPECTED)) + '};\nBool BreakRoutingCheck(){I64 *rows=BreakLockRows,i;Bool ok=TRUE;for(i=0;i<ROWS;i++)if(rows[i]!=BreakRoutingExpected[i]){BreakRoutingStage=i;ok=FALSE;break;}Free(rows);return ok;}\n'
   source=source.replace('ROWS',str(len(EXPECTED)))
   commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/BreakRouting.HC"',[]),('BreakRoutingCheck;',['1']),('6*7;',['42'])]
   report['commands']=commands;working=out/'working.img';report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/BreakRouting.HC':source.encode()})
   report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Public break-lock comparison failed')


if __name__=='__main__':main()
