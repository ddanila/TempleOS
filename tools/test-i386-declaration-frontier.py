#!/usr/bin/env python3
"""Check original compound declarations, failed headers and UndefinedExtern state."""
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
 fixture=ROOT/'tests/guest/i386-declaration-frontier-reference/Once.HC'
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();reference=json.loads((ref/'result.json').read_text())
 keys=[k for k in reference.get('input_sha256',{}) if k.endswith('/i386-declaration-frontier-reference/Once.HC')]
 if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or len(reference.get('records',[]))!=10 or len(keys)!=1 or sha(fixture)!=reference['input_sha256'][keys[0]]:
  raise ValueError('Passing unchanged original ten-case frontier reference required')
 original=fixture.read_text();inspector=original[original.index('I64 FrontierHeader('):original.index('U0 DeclarationFrontier()')]
 source=inspector+WRAPPER;commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/FrontierInspect.HC"',[])]
 for mode in range(2):
  for kind in range(5):
   name=['NativeFrontierThrow','NativeFrontierParse','NativeFrontierLost','NativeFrontierHeader','NativeFrontierHeader'][kind]+str(mode)
   if kind==0:text=f'{{I64 {name}(){{return 99;}}41;throw(\'Delib\',TRUE);}}';probe=name+';';expected='99';diagnostic=None
   elif kind==1:text=f'{{I64 {name}(){{return 99;}}Unknown frontier_bad;}}';probe=name+';';expected='99';diagnostic='Undefined identifier'
   elif kind==2:text=f'{{U8 *{name}="bad";throw(\'Delib\',TRUE);}}';probe=name+'[1];';expected='97';diagnostic=None
   elif kind==3:text=f'I64 {name}(I64 a=7,U8 *s="AZ"){{return frontier_missing;}}';probe=f'FrontierHeader("{name}");';expected='127';diagnostic='Invalid lval'
   else:text=name+'();';probe=f'FrontierHeader("{name}");';expected='127';diagnostic='Undefined Extern'
   exception="'Delib'" if kind in (0,2) else "'UndefExt'" if kind==4 else '0'
   commands.extend([(f'FrontierRun({json.dumps(text)},{mode});',[]),
    (f'FrontierException=={exception} && FrontierAnswer==23;',['1']),
    (f'HashFind("{name}",Fs->hash_table,HTT_FUN|HTT_GLBL_VAR)!=NULL;',['1']),
    (probe,[expected]),(f'FrontierDocument({json.dumps(diagnostic) if diagnostic else "NULL"});',['1'])])
 commands.extend([('DocDel(FrontierOutput);',[]),('6*7;',['42'])])
 if any(len(c[0])>255 for c in commands):raise ValueError('Input exceeds native buffer')
 paths=[disk,ref/'result.json',fixture,Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py',ROOT/'tools/build-i386-kernel.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 pins={str(f):sha(f) for f in paths};out.mkdir(parents=True);working=out/'working.img'
 report=dict(result='fail',input_sha256=pins,commands=commands,inspector_sha256=hashlib.sha256(source.encode()).hexdigest(),
  scope='All ten original-derived default/command-line frontier cases: compound-statement function/global persistence, failed header/default-argument/real UndefinedExtern target, unresolved exception and actual put-document diagnostic routing. 8 MiB KVM 486,-fpu/live WinMgr, exact visible pixels plus real saved-document message predicates; not full diagnostic byte/style parity or all APIs.')
 try:
  report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](disk,working,additions={'/Probe/FrontierInspect.HC':source.encode()})
  report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Declaration frontier failed')


if __name__=='__main__':main()
