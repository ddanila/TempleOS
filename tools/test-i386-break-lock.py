#!/usr/bin/env python3
"""Compare public BreakLock/BreakUnlock state transitions and exception delivery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
ROOT=Path(__file__).resolve().parents[1]
EXPECTED=[0,0,1,0,1,1,0,0,1,1,1,0,0,0]+[1,0,0,1,1,1,0,0]+[1,1,0,1,1,1,0,0]+[1,0,1,0,1,0]


def definitions():
 return '''
I64 BreakChildPhase,BreakChildException,BreakChildAfter,BreakChildFlags;
Bool BreakChildStop;
U0 BreakLockChild(U8 *data)
{
 if(data)BreakChildPhase=-1;else BreakChildPhase=1;
 try{while(!BreakChildStop)Yield;BreakChildAfter=1;}
 catch{BreakChildException=Fs->except_ch;Fs->catch_except=TRUE;}
 BreakChildFlags=Fs->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK);
 BreakChildPhase=2;
}
I64 *BreakLockRows()
{
 I64 *rows=CAlloc(ROWS*8),i=0,exception=0,after=0,locked,end;
 I64 mask=1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK,saved=Fs->task_flags&mask;
 CTask *child;CTask descriptor;
 rows[i++]=saved;
 Fs->task_flags&=~mask;
 rows[i++]=BreakUnlock;
 rows[i++]=BreakLock;
 rows[i++]=BreakLock;
 rows[i++]=Bt(&Fs->task_flags,TASKf_BREAK_LOCKED);
 rows[i++]=BreakUnlock;
 rows[i++]=Bt(&Fs->task_flags,TASKf_BREAK_LOCKED);
 rows[i++]=BreakUnlock;
 rows[i++]=BreakLock(Fs);
 rows[i++]=BreakUnlock(Fs);
 BreakLock;Bts(&Fs->task_flags,TASKf_PENDING_BREAK);
 try{BreakUnlock;after=1;}catch{exception=Fs->except_ch;Fs->catch_except=TRUE;}
 rows[i++]=exception=='Break';rows[i++]=after;
 rows[i++]=Bt(&Fs->task_flags,TASKf_BREAK_LOCKED);
 rows[i++]=Bt(&Fs->task_flags,TASKf_PENDING_BREAK);
 for(locked=0;locked<2;locked++){
  BreakChildStop=FALSE;BreakChildPhase=BreakChildException=BreakChildAfter=BreakChildFlags=0;
  child=Spawn(&BreakLockChild,NULL,"break lock",Gs->num,Fs,8192);
  if(!child)return rows;
  end=cnts.jiffies+5000;while(!BreakChildPhase && cnts.jiffies<end)Yield;
  rows[i++]=BreakChildPhase==1;
  Suspend(child,TRUE);
  if(locked)BreakLock(child);else BreakUnlock(child);
  Bts(&child->task_flags,TASKf_PENDING_BREAK);
  rows[i++]=BreakUnlock(child);
  rows[i++]=Bt(&child->task_flags,TASKf_PENDING_BREAK);
  rows[i++]=IsSuspended(child);
  Suspend(child,FALSE);
  end=cnts.jiffies+5000;while(TaskValidate(child) && cnts.jiffies<end)Yield;
  rows[i++]=!TaskValidate(child);
  rows[i++]=BreakChildException=='Break';rows[i++]=BreakChildAfter;rows[i++]=BreakChildFlags;
  if(TaskValidate(child)){BreakChildStop=TRUE;Kill(child);}
 }
 MemSet(&descriptor,0,sizeof(descriptor));
 rows[i++]=BreakLock(&descriptor);rows[i++]=BreakLock(&descriptor);
 Bts(&descriptor.task_flags,TASKf_PENDING_BREAK);
 rows[i++]=BreakUnlock(&descriptor);
 rows[i++]=Bt(&descriptor.task_flags,TASKf_PENDING_BREAK);
 rows[i++]=descriptor.rip==(&Break+0)(U64);
 rows[i++]=Bt(&descriptor.task_flags,TASKf_BREAK_LOCKED);
 Fs->task_flags=Fs->task_flags&~mask|saved;
 return rows;
}
'''.replace('ROWS',str(len(EXPECTED)))


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path,nargs='?');p.add_argument('--original',action='store_true');p.add_argument('--out',type=Path,required=True);args=p.parse_args()
 if args.original==(args.disk is not None):p.error('Use either --original or a native disk')
 out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 if args.disk:paths.append(args.disk.resolve())
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',expected=EXPECTED,input_sha256=pins,scope='Public lock/unlock return values, default/explicit current task, synchronous current pending Break, suspended foreign targets with initially locked/unlocked state, immediate pending-bit clearing, preserved suspension, real child Break catch and task exit. Also checks standalone writable CTask flags and Break RIP without treating the descriptor as private native storage. Does not qualify Shift-Esc routing, every foreign kernel wait or all public API behavior.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(definitions())
   source='''U0 BLReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
BLReport("ADAM SERVER READY\\n");
I64 *rows=BreakLockRows;U8 *notice=MStrPrint("EXPORT break-lock.bin %X %X\\n",rows,ROWS*8);BLReport(notice);BLReport("DONE original break lock\\n");
'''
   (overlay/'Once.HC').write_text(source.replace('ROWS',str(len(EXPECTED))))
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   report['records']=list(struct.unpack(f'<{len(EXPECTED)}q',(out/'guest/break-lock.bin').read_bytes()))
   if report['records']!=EXPECTED:raise ValueError('Original public break-lock behavior differs')
  else:
   source=definitions()+'\nI64 BreakLockStage;\nI64 BreakLockExpected[ROWS]={' + ','.join(map(str,EXPECTED)) + '};\nBool BreakLockCheck(){I64 *rows=BreakLockRows,i;Bool ok=TRUE;for(i=0;i<ROWS;i++)if(rows[i]!=BreakLockExpected[i]){BreakLockStage=i;ok=FALSE;break;}Free(rows);return ok;}\n'
   source=source.replace('ROWS',str(len(EXPECTED)))
   commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/BreakLock.HC"',[]),('BreakLockCheck;',['1']),('6*7;',['42'])]
   report['commands']=commands;working=out/'working.img';report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/BreakLock.HC':source.encode()})
   report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Public break-lock comparison failed')


if __name__=='__main__':main()
