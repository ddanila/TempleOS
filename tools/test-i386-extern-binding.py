#!/usr/bin/env python3
"""Compare persistent extern identity, unresolved calls and late binding."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
ROOT=Path(__file__).resolve().parents[1]
WRAPPER='''
I64 FrontierException,FrontierAnswer;
CDoc *FrontierOutput;
U0 FrontierRun(U8 *source,I64 flags)
{
 CDoc *old=Fs->put_doc;
 if(FrontierOutput)DocDel(FrontierOutput);
 FrontierOutput=DocNew;Fs->put_doc=FrontierOutput;
 ExePutS("23;");FrontierException=0;
 try{ExePutS(source,0,flags);}catch{FrontierException=Fs->except_ch;Fs->catch_except=TRUE;}
 FrontierAnswer=Fs->answer;Fs->put_doc=old;
}
I64 FrontierDocument(U8 *needle)
{
 I64 size,result;U8 *text=DocSave(FrontierOutput,&size);
 if(needle)result=text && StrMatch(needle,text)!=NULL;
 else result=size==0;
 Free(text);return result;
}
'''


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path)
 p.add_argument('--reference',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
 args=p.parse_args();disk=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-extern-binding-reference/Once.HC'
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 reference=json.loads((ref/'result.json').read_text())
 keys=[k for k in reference.get('input_sha256',{}) if k.endswith('/i386-extern-binding-reference/Once.HC')]
 if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or len(reference.get('records',[]))!=16 or len(keys)!=1 or sha(fixture)!=reference['input_sha256'][keys[0]]:
  raise ValueError('Passing unchanged original sixteen-case binding reference required')
 source=WRAPPER+'\nCHashFun *BindingFirst[2];\n'
 commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/BindingInspect.HC"',[])]
 for mode in range(2):
  name=f'NativeBindingTarget{mode}';caller=f'NativeBindingCaller{mode}'
  sources=[f'extern I64 {name}(I64 a=7);',f'I64 {caller}(){{return {name}();}}',caller+'();',f'I64 {name}(I64 a=7){{return a+90;}}',caller+'();',f'I64 {name}(I64 a=7){{return 101;}}',caller+'();',name+'();']
  for kind,text in enumerate(sources):
   row=reference['records'][mode*8+kind]
   commands.append((f'FrontierRun({json.dumps(text)},{mode});',[]))
   commands.append((f'FrontierException=={row[1]} && FrontierAnswer=={row[2]};',['1']))
   if kind==0:commands.append((f'(BindingFirst[{mode}]=HashFind("{name}",Fs->hash_table,HTT_FUN))!=NULL;',['1']))
   else:commands.append((f'(HashFind("{name}",Fs->hash_table,HTT_FUN)==BindingFirst[{mode}])=={row[4]};',['1']))
   diagnostic='Undefined Extern' if kind==2 else 'Unused var' if kind==5 else None
   commands.append((f'FrontierDocument({json.dumps(diagnostic) if diagnostic else "NULL"});',['1']))
 commands.extend([('DocDel(FrontierOutput);',[]),('6*7;',['42'])])
 if any(len(c[0])>255 for c in commands):raise ValueError('Input exceeds native buffer')
 paths=[disk,ref/'result.json',fixture,Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 pins={str(f):sha(f) for f in paths};out.mkdir(parents=True);working=out/'working.img'
 report=dict(result='fail',input_sha256=pins,commands=commands,scope='All sixteen original persistent extern/caller/definition/shadowing cases in both flags, integer defaults, actual UndefinedExtern and unused-argument documents. Descriptor identity and answers checked without replacement routines. 8 MiB KVM 486,-fpu/live WinMgr exact pixels; string-default lifetime and other APIs remain separate.')
 try:
  report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](disk,working,additions={'/Probe/BindingInspect.HC':source.encode()})
  report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Extern binding failed')


if __name__=='__main__':main()
