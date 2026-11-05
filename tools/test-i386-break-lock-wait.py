#!/usr/bin/env python3
"""Compare public pending-break delivery across Sleep and GetMsg waits."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
ROOT=Path(__file__).resolve().parents[1]
EXPECTED=[1,1,1,0,1,1,1,1,0,1,0,0,1,0]*2


def definitions():
 return '\nI64 WaitPhase,WaitException,WaitAfter,WaitWake,WaitRemaining,WaitFlags,WaitIF,WaitCode;\nU0 BreakWaitChild(U8 *data)\n{\n I64 mode=data(I64),a=0,b=0;\n FlushMsgs;\n try{\n  WaitPhase=1;\n  if(mode)WaitCode=GetMsg(&a,&b,1<<MSG_KEY_DOWN);\n  else Sleep(100);\n  WaitAfter=1;\n }catch{WaitException=Fs->except_ch;Fs->catch_except=TRUE;}\n WaitWake=Fs->wake_jiffy==0;\n WaitRemaining=ScanMsg(NULL,NULL,1<<MSG_KEY_DOWN);\n WaitFlags=Fs->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK|1<<TASKf_AWAITING_MSG);\n WaitIF=(GetRFlags&512)!=0;WaitPhase=2;\n}\nI64 *BreakLockRows()\n{\n I64 *rows=CAlloc(ROWS*8),i=0,mode,end;CTask *child;\n for(mode=0;mode<2;mode++){\n  WaitPhase=WaitException=WaitAfter=WaitWake=WaitRemaining=WaitFlags=WaitIF=WaitCode=0;\n  child=Spawn(&BreakWaitChild,mode(U8 *),"break wait",Gs->num,Fs,8192);\n  if(!child)return rows;\n  end=cnts.jiffies+5000;while(!WaitPhase && cnts.jiffies<end)Yield;\n  rows[i++]=WaitPhase==1;Suspend(child,TRUE);\n  rows[i++]=BreakLock(child);Bts(&child->task_flags,TASKf_PENDING_BREAK);\n  rows[i++]=BreakUnlock(child);rows[i++]=Bt(&child->task_flags,TASKf_PENDING_BREAK);\n  rows[i++]=IsSuspended(child);\n  if(mode)PostMsg(child,MSG_KEY_DOWN,\'Q\',0x10);\n  rows[i++]=IsSuspended(child);Suspend(child,FALSE);\n  end=cnts.jiffies+5000;while(TaskValidate(child) && cnts.jiffies<end)Yield;\n  rows[i++]=!TaskValidate(child);rows[i++]=WaitException==\'Break\';rows[i++]=WaitAfter;\n  rows[i++]=WaitWake;rows[i++]=WaitRemaining;rows[i++]=WaitFlags;rows[i++]=WaitIF;rows[i++]=WaitCode;\n  if(TaskValidate(child))Kill(child);\n }\n return rows;\n}\n'.replace('ROWS',str(len(EXPECTED)))


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path,nargs='?');p.add_argument('--original',action='store_true');p.add_argument('--out',type=Path,required=True);args=p.parse_args()
 if args.original==(args.disk is not None):p.error('Use either --original or a native disk')
 out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 if args.disk:paths.append(args.disk.resolve())
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',expected=EXPECTED,input_sha256=pins,scope='Actual public Sleep/GetMsg waits, foreign pending unlock while suspended, event wakeup, real Break caught before post-wait code, zero wake/pending/await flags and flushed key message. Does not qualify ATA/file/provider waits or every foreign resource case.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(definitions())
   source='''U0 BLReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
BLReport("ADAM SERVER READY\\n");
I64 *rows=BreakLockRows;U8 *notice=MStrPrint("EXPORT break-wait.bin %X %X\\n",rows,ROWS*8);BLReport(notice);BLReport("DONE original break wait\\n");
'''
   (overlay/'Once.HC').write_text(source.replace('ROWS',str(len(EXPECTED))))
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   report['records']=list(struct.unpack(f'<{len(EXPECTED)}q',(out/'guest/break-wait.bin').read_bytes()))
   if report['records']!=EXPECTED:raise ValueError('Original public break-lock behavior differs')
  else:
   source=definitions()+'\nI64 BreakWaitStage;\nI64 BreakWaitExpected[ROWS]={' + ','.join(map(str,EXPECTED)) + '};\nBool BreakWaitCheck(){I64 *rows=BreakLockRows,i;Bool ok=TRUE;for(i=0;i<ROWS;i++)if(rows[i]!=BreakWaitExpected[i]){BreakWaitStage=i;ok=FALSE;break;}Free(rows);return ok;}\n'
   source=source.replace('ROWS',str(len(EXPECTED)))
   commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/BreakWait.HC"',[]),('BreakWaitCheck;',['1']),('6*7;',['42'])]
   report['commands']=commands;working=out/'working.img';report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/BreakWait.HC':source.encode()})
   report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Public break-lock comparison failed')


if __name__=='__main__':main()
