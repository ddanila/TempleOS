#!/usr/bin/env python3
"""Check unresolved caller cleanup on child exit and explicit symbol deletion."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import struct
ROOT=Path(__file__).resolve().parents[1]


def definitions():
 return '''
I64 PendingState;
CTask *PendingChild;
extern I64 PendingTarget(I64 n=7);
U0 PendingCompile(U8 *source)
{try{ExePutS(source);PendingState=1;}catch{PendingState=-1;Fs->catch_except=TRUE;}}
Bool PendingStart()
{PendingState=0;PendingChild=Spawn(&PendingCompile,"I64 ChildPending(){return PendingTarget();}","pending",-1,Fs,8192);return PendingChild!=NULL;}
Bool PendingDone()
{I64 end=cnts.jiffies+5000;while(TaskValidate(PendingChild)&&cnts.jiffies<end)Yield;return !TaskValidate(PendingChild)&&PendingState==1;}
Bool PendingUnlinked()
{CHashFun *f=HashFind("PendingTarget",Fs->hash_table,HTT_FUN);return f && !f->ext_lst;}
I64 DeletedException,DeletedAnswer;
CDoc *DeletedOutput;
U0 DeletedRun()
{
 CDoc *old=Fs->put_doc;DeletedOutput=DocNew;Fs->put_doc=DeletedOutput;
 ExePutS("23;");DeletedException=0;
 try{ExePutS("DeletedCaller();");}catch{DeletedException=Fs->except_ch;Fs->catch_except=TRUE;}
 DeletedAnswer=Fs->answer;Fs->put_doc=old;
}
Bool DeletedCheck()
{I64 size;U8 *text=DocSave(DeletedOutput,&size);Bool ok=DeletedException=='UndefExt' && DeletedAnswer==23 && StrMatch("Undefined Extern",text)!=NULL;Free(text);DocDel(DeletedOutput);return ok;}
'''


def commands():
 return [('PendingStart;',['1']),('PendingDone;',['1']),('PendingUnlinked;',['1']),
  ('I64 PendingTarget(I64 n=7){return n+35;}',[]),('PendingTarget();',['42']),
  ('extern I64 DeletedTarget(I64 n=7);',[]),('I64 DeletedCaller(){return DeletedTarget();}',[]),
  ('HashRemDel(HashFind("DeletedTarget",Fs->hash_table,HTT_FUN),Fs->hash_table);',['1']),
  ('DeletedRun;',[]),('DeletedCheck;',['1']),
  ('I64 DeletedTarget(I64 n=7){return n+35;}',[]),('DeletedTarget();',['42']),
  ('DeletedRun;',[]),('DeletedCheck;',['1']),('6*7;',['42'])]


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path,nargs='?')
 p.add_argument('--original',action='store_true');p.add_argument('--ram-mib',type=int,choices=(8,64),default=8)
 p.add_argument('--out',type=Path,required=True);args=p.parse_args()
 if args.original==(args.disk is not None):p.error('Use either --original or a native disk')
 out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 if args.disk:paths.append(args.disk.resolve())
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,commands=commands(),scope='Original/native child compilation against inherited extern, child exit and later definition. Native additionally verifies explicit HashRemDel retires indirect descriptor borrows to the real UndefExt target, including after same-name replacement; that protects an unsafe deleted-descriptor dereference in the original and is a recorded architecture cleanup policy, not an original defined-behavior equivalence claim.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(definitions())
   source='''U0 LReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
LReport("ADAM SERVER READY\\n");
I64 *rows=CAlloc(5*8),i=0,value;
'''
   reference_commands=commands()[:5];report['commands']=reference_commands
   for text,expected in reference_commands:
    source+='value=ExePutS('+json.dumps(text)+');rows[i++]=value;\n'
   source+='U8 *export=MStrPrint("EXPORT lifecycle.bin %X %X\\n",rows,5*8);LReport(export);LReport("DONE extern lifecycle\\n");\n'
   (overlay/'Once.HC').write_text(source)
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   data=(out/'guest/lifecycle.bin').read_bytes();report['records']=list(struct.unpack('<5q',data))
   for value,(_,expected) in zip(report['records'],reference_commands):
    if expected and value!=int(expected[0]):raise ValueError('Original extern lifecycle differs')
  else:
   source=definitions();working=out/'working.img'
   report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/ExternLifecycle.HC':source.encode()})
   setup=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/ExternLifecycle.HC"',[])]
   report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=args.ram_mib,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':setup+commands(),'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Extern lifecycle failed')


if __name__=='__main__':main()
