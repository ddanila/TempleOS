#!/usr/bin/env python3
"""Compare child definition shadowing of an inherited parent extern."""
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
I64 ShadowState,ShadowValue,ShadowException,ShadowAnswer;
CTask *ShadowChild;
CDoc *ShadowOutput;
extern I64 ShadowTarget(I64 a=7);
U0 ShadowCompile(U8 *source)
{try{ExePutS(source);ShadowValue=Fs->answer;ShadowState=1;}catch{ShadowState=-1;Fs->catch_except=TRUE;}}
Bool ShadowStart()
{ShadowState=ShadowValue=0;ShadowChild=Spawn(&ShadowCompile,"I64 ShadowTarget(I64 a=7){return a+35;}ShadowTarget();","shadow",-1,Fs,8192);return ShadowChild!=NULL;}
Bool ShadowDone()
{I64 end=cnts.jiffies+5000;while(TaskValidate(ShadowChild)&&cnts.jiffies<end)Yield;return !TaskValidate(ShadowChild)&&ShadowState==1;}
Bool ShadowParent()
{CHashFun *f=HashFind("ShadowTarget",Fs->hash_table,HTT_FUN);return ShadowValue==42 && f && Bt(&f->flags,Cf_EXTERN);}
U0 ShadowProbe()
{CDoc *old=Fs->put_doc;ShadowOutput=DocNew;Fs->put_doc=ShadowOutput;ExePutS("23;");ShadowException=0;try{ExePutS("ShadowTarget();");}catch{ShadowException=Fs->except_ch;Fs->catch_except=TRUE;}ShadowAnswer=Fs->answer;Fs->put_doc=old;}
Bool ShadowUndefined()
{I64 size;U8 *text=DocSave(ShadowOutput,&size);Bool ok=ShadowException=='UndefExt' && ShadowAnswer==23 && StrMatch("Undefined Extern",text)!=NULL;Free(text);DocDel(ShadowOutput);return ok;}
'''


def commands():
 return [('ShadowStart;',['1'],0),('ShadowDone;',['1'],0),('ShadowParent;',['1'],0),
  ('ShadowProbe;',[],0),('ShadowUndefined;',['1'],0),('6*7;',['42'],0)]


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
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,commands=commands(),scope='Actual child ExePutS defines and calls a same-name function while inheriting a parent extern. Child exits; parent descriptor must remain unresolved and a real parent call must throw UndefExt with answer 23 and a saved-document diagnostic. U0 raw returns unconstrained. Not arbitrary foreign explicit hash-context mutation or whole API qualification.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(definitions())
   source='''U0 LReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
LReport("ADAM SERVER READY\\n");
I64 *rows=CAlloc(6*8),i=0,value;
'''
   for text,expected,mode in commands():
    source+='value=ExePutS('+json.dumps(text)+f',0,{mode});rows[i++]=value;\n'
   source+='U8 *export=MStrPrint("EXPORT child-shadow.bin %X %X\\n",rows,6*8);LReport(export);LReport("DONE extern child shadow\\n");\n'
   (overlay/'Once.HC').write_text(source)
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   data=(out/'guest/child-shadow.bin').read_bytes();report['records']=list(struct.unpack('<6q',data))
   for record,(_,expected,_) in zip(report['records'],commands()):
    if expected and record!=int(expected[0]):raise ValueError('Original extern child shadow differs')
  else:
   source=definitions()+'\nI64 RTAnswer;\nU0 RTRun(U8 *s,I64 mode){ExePutS(s,0,mode);RTAnswer=Fs->answer;}\n';working=out/'working.img'
   report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/ExternChildShadow.HC':source.encode()})
   setup=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/ExternChildShadow.HC"',[])]
   native_commands=list(setup)
   for text,expected,mode in commands():
    native_commands.append((f'RTRun({json.dumps(text)},{mode});',[]))
    if expected:native_commands.append(('RTAnswer;',expected))
   native_commands.append(('6*7;',['42']))
   report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=args.ram_mib,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':native_commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Extern lifecycle failed')


if __name__=='__main__':main()
