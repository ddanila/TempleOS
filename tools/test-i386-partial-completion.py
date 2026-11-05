#!/usr/bin/env python3
"""Verify native completion and earlier bindings after real partial declarations."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
ROOT=Path(__file__).resolve().parents[1]


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path);p.add_argument('--out',type=Path,required=True);args=p.parse_args()
 out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);helper=ROOT/'tools/test-i386-partial-declaration.py';api=runpy.run_path(str(helper));cases=api['cases']()
 paths=[Path(__file__).resolve(),helper,ROOT/'tools/test-i386-declaration-frontier.py',args.disk.resolve(),ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
 source=runpy.run_path(str(ROOT/'tools/test-i386-declaration-frontier.py'))['WRAPPER']+'\nI64 RepairStage;\n'
 arrays={key:[] for key in ['Sources','Good','Bad','Definitions','Calls','Keep','OldCalls','Set','Unresolved']}
 for mode,kind,text,probes,expected in cases:
  good=f'PartialGood{mode}_{kind}';bad=f'PartialBad{mode}_{kind}';caller=f'RepairKeep{mode}_{kind}'
  values=dict(Sources=text,Good=good+';',Bad=bad,Set=bad+'=1;',Unresolved=bad+'();')
  if kind in (0,3):
   values.update(Definitions=f'I64 {bad}(I64 x){{return x+41;}}',Calls=bad+'(1);',Keep='',OldCalls='')
  elif kind==1:
   values.update(Definitions=f'class {bad}{{I64 x,y;}};',Calls=f'sizeof({bad});',Keep=f'I64 {caller}(){{return sizeof({bad});}}',OldCalls=caller+';')
  else:
   values.update(Definitions=f'I64 {bad}=42;',Calls=bad+';',Keep=f'I64 {caller}(){{return {bad};}}',OldCalls=caller+';')
  for key in arrays:arrays[key].append(values[key])
 for key,values in arrays.items():source+='U8 *Repair'+key+'[8]={'+','.join(json.dumps(v) for v in values)+'};\n'
 source+='''
Bool RepairCase(I64 index)
{
 I64 kind=index%4,mode=index/4,value;
 CHashFun *function;CHashClass *type;CHashGlblVar *global;
 RepairStage=1;FrontierRun(RepairSources[index],mode);
 if(FrontierException || FrontierAnswer!=23 || FrontierDocument(NULL))return FALSE;
 RepairStage=2;
 if(kind==0 || kind==3){
  function=HashFind(RepairBad[index],Fs->hash_table,HTT_FUN);
  if(!function || !Bt(&function->flags,Cf_EXTERN))return FALSE;
  FrontierRun(RepairUnresolved[index],mode);
  if(FrontierException!='UndefExt' || FrontierAnswer!=23 || !FrontierDocument("Undefined Extern"))return FALSE;
 }else{
  if(kind==1){type=HashFind(RepairBad[index],Fs->hash_table,HTT_CLASS);if(!type || type->size!=8)return FALSE;}
  else{global=HashFind(RepairBad[index],Fs->hash_table,HTT_GLBL_VAR);if(!global || ExePutS(RepairSet[index])!=1)return FALSE;}
  FrontierRun(RepairKeep[index],mode);
  if(FrontierException || FrontierAnswer!=23 || !FrontierDocument(NULL))return FALSE;
 }
 RepairStage=3;FrontierRun(RepairDefinitions[index],mode);
 if(FrontierException || FrontierAnswer!=23 || !FrontierDocument(NULL))return FALSE;
 RepairStage=4;
 if(kind==0 || kind==3){
  if(HashFind(RepairBad[index],Fs->hash_table,HTT_FUN)!=function ||
     Bt(&function->flags,Cf_EXTERN) || function->arg_cnt!=1)return FALSE;
 }else if(kind==1){
  if(HashFind(RepairBad[index],Fs->hash_table,HTT_CLASS)==type || type->size!=8 || ExePutS(RepairOldCalls[index])!=8)return FALSE;
 }else{
  if(HashFind(RepairBad[index],Fs->hash_table,HTT_GLBL_VAR)==global ||
     *global->data_addr(I64 *)!=1 || ExePutS(RepairOldCalls[index])!=1)return FALSE;
 }
 RepairStage=5;value=ExePutS(RepairCalls[index]);
 if(kind==1){if(value!=16)return FALSE;}else if(value!=42)return FALSE;
 RepairStage=6;return ExePutS(RepairGood[index])==42;
}
'''
 commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/PartialCompletion.HC"',[])]
 commands += [(f'RepairCase({i});',['1']) for i in range(8)]
 commands += [('DocDel(FrontierOutput);FrontierOutput=NULL;',['0x0']),('6*7;',['42'])]
 report=dict(result='fail',input_sha256=pins,commands=commands,scope='Native owned partial declarations followed by real Undefined Extern calls, valid definitions, stable function descriptor completion and earlier class/global caller bindings. Both ExePutS modes and real saved diagnostics. This intentionally protects unsafe original partial metadata; not a post-error original lifetime equivalence claim or full API qualification.')
 try:
  working=out/'working.img';report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/PartialCompletion.HC':source.encode()})
  report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Partial declaration completion failed')


if __name__=='__main__':main()
