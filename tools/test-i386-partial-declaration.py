#!/usr/bin/env python3
"""Compare retained declarations after incomplete signatures and initializers."""
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
  for kind in range(4):
   good=f'PartialGood{mode}_{kind}';bad=f'PartialBad{mode}_{kind}'
   tail=[f'I64 {bad}(I64 x,Unknown y){{return x;}}',
         f'class {bad}{{I64 x;Unknown y;}};',
         f'I64 {bad}=unknown_initializer;',f'I64 {bad}(I64 x,'][kind]
   source=f'I64 {good}(){{return 42;}}'+tail
   probes=[good+';',f'HashFind("{bad}",Fs->hash_table,HTT_FUN|HTT_CLASS|HTT_GLBL_VAR)!=NULL;',f'PartialMetadata("{bad}",{kind});']
   result.append((mode,kind,source,probes,[0,23,42,1,1,1]))
 return result


def needle(kind):
 return 'Invalid lval' if kind==2 else 'Expecting type'


METADATA='\nI64 PartialMetadata(U8 *name,I64 kind)\n{\n CHashClass *entry=HashFind(name,Fs->hash_table,HTT_FUN|HTT_CLASS|HTT_GLBL_VAR);\n CHashFun *fun;CHashGlblVar *global;CMemberLst *member;\n if(!entry)return 0;\n if(kind==0 || kind==3){\n  fun=entry;member=fun->member_lst_and_root;\n  return fun->arg_cnt==0 && member &&\n   Bt(&fun->flags,Cf_EXTERN) && fun->exe_addr!=NULL;\n }\n if(kind==1)return entry->size==8 && entry->member_lst_and_root!=NULL;\n global=entry;return global->size==8 && global->data_addr!=NULL;\n}\n'

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path,nargs='?')
 p.add_argument('--original',action='store_true');p.add_argument('--out',type=Path,required=True)
 args=p.parse_args()
 if args.original==(args.disk is not None):p.error('Use either --original or a native disk')
 out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);frontier=ROOT/'tools/test-i386-declaration-frontier.py';wrapper=runpy.run_path(str(frontier))['WRAPPER']+METADATA
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[Path(__file__).resolve(),frontier,ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 if args.disk:paths.append(args.disk.resolve())
 pins={str(f):sha(f) for f in paths};report=dict(result='fail',input_sha256=pins,cases=cases(),scope='Earlier complete functions and incomplete function/class/global declarations remain visible after real parser failures, in both ExePutS flag modes, with actual answer and saved diagnostic documents. Original uses a precompiled immediate observer and Call, then unlinks the malformed entry without freeing unsafe metadata before the next compilation. Native additionally checks public lookup after further compilation; this is a safety/ownership policy, not equivalence to original dangling metadata. Does not qualify all incomplete metadata or lifetime behavior.')
 try:
  if args.original:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Definitions.HC').write_text(wrapper)
   source='''U0 PartialReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/Definitions.HC"
U0 PartialExportDocument(U8 *name)
{I64 size;U8 *text=DocSave(FrontierOutput,&size),*notice=MStrPrint("EXPORT %s %X %X\\n",name,text,size);PartialReport(notice);}
U0 PartialUnlink(CHash *entry)
{
 I64 i;CHash **link;
 for(i=0;i<=Fs->hash_table->mask;i++){
  link=&Fs->hash_table->body[i];
  while(*link){
   if(*link==entry){*link=entry->next;entry->next=NULL;return;}
   link=&(*link)->next;
  }
 }
}
U0 PartialObserveAll()
{
 I64 *rows=CAlloc(48*8),i=0,metadata;
 CHashFun *good;CHash *bad;
 while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
 PartialReport("ADAM SERVER READY\\n");
'''
   for mode,kind,text,probes,expected in cases():
    source+=f'FrontierRun({json.dumps(text)},{mode});rows[i++]=FrontierException;rows[i++]=FrontierAnswer;\n'
    source+=f'good=HashFind("PartialGood{mode}_{kind}",Fs->hash_table,HTT_FUN);bad=HashFind("PartialBad{mode}_{kind}",Fs->hash_table,HTT_FUN|HTT_CLASS|HTT_GLBL_VAR);metadata=PartialMetadata("PartialBad{mode}_{kind}",{kind});\n'
    source+='rows[i++]=Call(good->exe_addr);rows[i++]=bad!=NULL;rows[i++]=metadata;if(bad)PartialUnlink(bad);\n'
    source+='rows[i++]=FrontierDocument('+json.dumps(needle(kind))+');\n'
    source+='PartialExportDocument('+json.dumps('partial-'+str(mode)+'-'+str(kind)+'.DD')+');\n'

   source+='U8 *notice=MStrPrint("EXPORT partial.bin %X %X\\n",rows,48*8);PartialReport(notice);PartialReport("DONE original partial declaration\\n");}\nPartialObserveAll;\n'
   (overlay/'Once.HC').write_text(source)
   subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
   data=(out/'guest/partial.bin').read_bytes();report['records']=[list(struct.unpack_from('<6q',data,n*48)) for n in range(8)]
   if report['records']!=[c[-1] for c in cases()]:raise ValueError('Original partial declaration differs')
  else:
   working=out/'working.img';report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/PartialDeclaration.HC':wrapper.encode()})
   commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/PartialDeclaration.HC"',[])]
   for mode,kind,text,probes,expected in cases():
    commands.extend([(f'FrontierRun({json.dumps(text)},{mode});',[]),(f'FrontierException=={expected[0]} && FrontierAnswer==23;',['1']),
     *[(probe,[str(value)]) for probe,value in zip(probes,expected[2:-1])],(f'FrontierDocument({json.dumps(needle(kind))});',['1'])])
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
 if report['result']!='pass':raise ValueError('Partial declaration failed')


if __name__=='__main__':main()
