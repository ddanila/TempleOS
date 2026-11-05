#!/usr/bin/env python3
"""Compare original extern callers through a live executable-address slot."""
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
CHashFun *RTBound;
U8 *RTOld;
U0 RTSave(U8 *name,U8 *replacement)
{RTBound=HashFind(name,Fs->hash_table,HTT_FUN);RTOld=RTBound->exe_addr;RTBound->exe_addr=HashFind(replacement,Fs->hash_table,HTT_FUN)(CHashFun *)->exe_addr;}
U0 RTRestore(){RTBound->exe_addr=RTOld;}
I64 RTShadow(U8 *name){return HashFind(name,Fs->hash_table,HTT_FUN)!=RTBound;}
'''


def commands():
 result=[]
 for mode in range(2):
  name=f'RTTarget{mode}';caller=f'RTCaller{mode}';replacement=f'RTReplacement{mode}'
  cases=[(f'extern I64 {name}(I64 a=7);',[]),(f'I64 {caller}(){{return {name}();}}',[]),
   (f'I64 {name}(I64 a=7){{return a+90;}}',[]),(f'I64 {replacement}(I64 a=7){{return a+94;}}',[]),
   (caller+'();',['97']),(f'RTSave("{name}","{replacement}");',[]),(caller+'();',['101']),
   ('RTRestore;',[]),(caller+'();',['97']),(f'I64 {name}(I64 a=7){{return a+100;}}',[]),
   (caller+'();',['97']),(name+'();',['107']),(f'RTShadow("{name}");',['1'])]
  result.extend((text,expected,mode) for text,expected in cases)
 return result


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
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,commands=commands(),scope='Actual extern caller, first definition, safe same-signature executable-slot redirection/restoration and later name shadowing in both flag modes. Only defined numeric returns are asserted; U0 raw ExePutS return bits are not specified. Original or native 486,-fpu/live WinMgr; not whole API qualification.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(definitions())
   source='''U0 LReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
LReport("ADAM SERVER READY\\n");
I64 *rows=CAlloc(26*8),i=0,value;
'''
   for text,expected,mode in commands():
    source+='value=ExePutS('+json.dumps(text)+f',0,{mode});rows[i++]=value;\n'
   source+='U8 *export=MStrPrint("EXPORT retarget.bin %X %X\\n",rows,26*8);LReport(export);LReport("DONE extern retarget\\n");\n'
   (overlay/'Once.HC').write_text(source)
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   data=(out/'guest/retarget.bin').read_bytes();report['records']=list(struct.unpack('<26q',data))
   for record,(_,expected,_) in zip(report['records'],commands()):
    if expected and record!=int(expected[0]):raise ValueError('Original extern retarget differs')
  else:
   source=definitions()+'\nI64 RTAnswer;\nU0 RTRun(U8 *s,I64 mode){ExePutS(s,0,mode);RTAnswer=Fs->answer;}\n';working=out/'working.img'
   report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/ExternRetarget.HC':source.encode()})
   setup=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/ExternRetarget.HC"',[])]
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
