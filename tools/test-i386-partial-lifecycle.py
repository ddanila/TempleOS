#!/usr/bin/env python3
"""Verify safe native partial metadata after compiler reuse and child-task exit."""
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
 paths=[Path(__file__).resolve(),helper,args.disk.resolve(),ROOT/'tools/i386-kernel-input.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
 source=api['METADATA']+'\nI64 PartialChildState;\n'
 for label,values in [('Sources',[c[2] for c in cases]),('Good',[f'PartialGood{c[0]}_{c[1]};' for c in cases]),('Bad',[f'PartialBad{c[0]}_{c[1]}' for c in cases])]:
  source+='U8 *PartialChild'+label+'[8]={'+','.join(json.dumps(v) for v in values)+'};\n'
 source+='''
U0 PartialChild(U8 *argument)
{
 I64 index=argument(I64),i;
 CDoc *old=Fs->put_doc,*doc=DocNew;
 CHashFun *fun;CMemberLst *member;
 Fs->put_doc=doc;PartialChildState=-1;
 try{
  ExePutS("23;");ExePutS(PartialChildSources[index],0,index/4);
  for(i=0;i<8;i++)ExePutS("6*7;");
  if(ExePutS(PartialChildGood[index])==42 && PartialMetadata(PartialChildBad[index],index%4)){
   PartialChildState=1;
   if(index%4==0 || index%4==3){
    fun=HashFind(PartialChildBad[index],Fs->hash_table,HTT_FUN);
    member=fun->member_lst_and_root;
    if(!member || !member->str || StrCmp(member->str,"x") ||
       !member->member_class || member->member_class->size!=8)PartialChildState=-2;
   }
  }
 }catch{Fs->catch_except=TRUE;PartialChildState=-3;}
 Fs->put_doc=old;DocDel(doc);
}
Bool PartialChildStart(I64 index)
{
 CTask *child;I64 end;
 PartialChildState=0;child=Spawn(&PartialChild,index(U8 *),"partial",-1,Fs,8192);
 if(!child)return FALSE;
 end=cnts.jiffies+10000;
 while(TaskValidate(child) && cnts.jiffies<end)Yield;
 return !TaskValidate(child) && PartialChildState==1;
}
Bool PartialChildRepeat(I64 index)
{
 I64 used=Fs->data_heap->bp->used_u8s,allocated=Fs->data_heap->bp->alloced_u8s;
 return PartialChildStart(index) && Fs->data_heap->bp->used_u8s==used &&
  Fs->data_heap->bp->alloced_u8s==allocated;
}
'''
 commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "/Kernel/SymbolTypes.HH"',[]),('#include "C:/Probe/PartialLifetime.HC"',[]),('PartialChildStart(0);',['1'])]
 commands += [(f'PartialChildRepeat({i});',['1']) for i in range(8)]
 commands += [('6*7;',['42'])]
 report=dict(result='fail',input_sha256=pins,commands=commands,scope='Native ownership safety after incomplete function/class/global declarations: eight further compilations, actual earlier function call, retained parameter-name/type access, natural child exit and exact shared arena used/allocated recovery after warmup. This is not original dangling-metadata equivalence or full API qualification.')
 try:
  working=out/'working.img';report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),working,additions={'/Probe/PartialLifetime.HC':source.encode()})
  report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Partial declaration ownership failed')


if __name__=='__main__':main()
