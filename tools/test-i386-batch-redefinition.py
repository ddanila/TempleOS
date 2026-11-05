#!/usr/bin/env python3
"""Compare same-input redefinition and earlier compiled bindings."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
ROOT=Path(__file__).resolve().parents[1]


def cases():
 result=[]
 for mode in range(2):
  for kind in range(6):
   name=f'BatchValue{mode}_{kind}';caller=f'BatchCaller{mode}_{kind}'
   if kind in (0,3,4):
    source=f'{{I64 {name}(){{return 1;}}I64 {caller}(){{return {name};}}I64 {name}(){{return 2;}}'
    if kind==3:source+="throw('Delib',TRUE);"
    if kind==4:source+="23;"
    source+='}';probes=[name+';',caller+';'];values=[2,1]
   elif kind in (1,5):
    source=f'{{I64 {name}=1;I64 {caller}(){{return {name};}}I64 {name}=2;'+('23;' if kind==5 else '')+'}';probes=[name+';',caller+';'];values=[2,1]
   else:
    source=f'{{class {name}{{I64 a;}};I64 {caller}(){{return sizeof({name});}}class {name}{{I64 a,b;}};}}';probes=[f'sizeof({name});',caller+';'];values=[16,8]
   result.append((mode,kind,source,probes,[int.from_bytes(b'Delib','little') if kind==3 else 0,23,*values,1]))
 return result


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path,nargs='?')
 p.add_argument('--original',action='store_true');p.add_argument('--out',type=Path,required=True)
 args=p.parse_args()
 if args.original==(args.disk is not None):p.error('Use either --original or a native disk')
 out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);frontier=ROOT/'tools/test-i386-declaration-frontier.py';wrapper=runpy.run_path(str(frontier))['WRAPPER']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),frontier,ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 if args.disk:paths.append(args.disk.resolve())
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,cases=cases(),scope='Same compound input redefines functions/globals/classes while earlier compiled callers retain old bindings; completed duplicate functions survive a later real throw. Both ExePutS flag modes, actual answer and saved-document checks; not unfinished sibling recovery or all API qualification.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(wrapper)
   source='''U0 BatchReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
U0 BatchExportDocument(U8 *name){I64 size;U8 *text=DocSave(FrontierOutput,&size),*notice=MStrPrint("EXPORT %s %X %X\\n",name,text,size);BatchReport(notice);}
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
BatchReport("ADAM SERVER READY\\n");
I64 *rows=CAlloc(60*8),i=0;
'''
   for mode,kind,text,probes,expected in cases():
    source+=f'FrontierRun({json.dumps(text)},{mode});rows[i++]=FrontierException;rows[i++]=FrontierAnswer;\n'
    for probe in probes:source+='rows[i++]=ExePutS('+json.dumps(probe)+');\n'
    source+='rows[i++]=FrontierDocument('+('\"Missing expression\"' if kind in (0,1) else 'NULL')+');\n'
    source+='BatchExportDocument('+json.dumps('batch-'+str(mode)+'-'+str(kind)+'.DD')+');\n'
   source+='U8 *notice=MStrPrint("EXPORT batch.bin %X %X\\n",rows,60*8);BatchReport(notice);BatchReport("DONE original batch redefinition\\n");\n'
   (overlay/'Once.HC').write_text(source)
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   data=(out/'guest/batch.bin').read_bytes();report['records']=[list(struct.unpack_from('<5q',data,n*40)) for n in range(12)]
   if report['records']!=[c[-1] for c in cases()]:raise ValueError('Original same-input redefinition differs')
  else:
   working=out/'working.img';report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/BatchRedefinition.HC':wrapper.encode()})
   commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "C:/Probe/BatchRedefinition.HC"',[])]
   for mode,kind,text,probes,expected in cases():
    commands.extend([(f'FrontierRun({json.dumps(text)},{mode});',[]),(f'FrontierException=={expected[0]} && FrontierAnswer==23;',['1']),
     (probes[0],[str(expected[2])]),(probes[1],[str(expected[3])]),(f'FrontierDocument({json.dumps("Missing expression") if kind in (0,1) else "NULL"});',['1'])])
   commands.extend([('DocDel(FrontierOutput);',[]),('6*7;',['42'])])
   if any(len(s)>255 for s,_ in commands):raise ValueError('Source exceeds native line limit')
   report['commands']=commands
   report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Batch redefinition failed')


if __name__=='__main__':main()
