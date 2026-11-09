#!/usr/bin/env python3
"""Compare original quoted document entries through nested includes and ExeDoc roots."""
import argparse,hashlib,json,runpy,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
CASES=['$LK,"link",A="MN:MSG_CMD"$','$TX+UL,"underlined"$','$TX,"metadata",A="auxiliary"$',
 '$AN,"anchor"$','$CM,LE=0,RE=0$','$BT,"button",LE=1$','$CB-P,"check"$','$TR,"tree"$',
 '$LK,"a\\\"b",A="FI:::/Doc/Asm.DD"$','$LK,"a\\x24b",A="MN:MSG_CMD"$',
 '$RED$','$FG,15$','$BG,3$','$FD,2$','$BD,4$','$PL,66$','$LM,3$','$RM,70$','$ID,-2$',
 '$WW,0$','$HL,1$','$BK,1$','$IV,1$','$UL,1$','$SX,-3$','$SY,-2$','$SY,0$','$$CL$$','$PB$',
 '$CU$','$MK$','$CR$','$TB$','$$', '$LK,"long_'+('L'*1200)+'",A="MN:MSG_CMD"$']
def source(prefix):return ''.join(f'U8 *{prefix}{i}(){{return "P {case} S";}}\n' for i,case in enumerate(CASES)).encode()
def names():return [f'{mode}-{i:02}.bin' for mode in ['include','root'] for i in range(len(CASES))]+['root-clear.bin']
def verify(out,reference=None):
 if (out/'root-clear.bin').read_bytes()!=b'P $CL$ S\0':raise ValueError('Constructed root CLEAR entry differs')
 for i in range(len(CASES)):
  a=(out/f'include-{i:02}.bin').read_bytes();b=(out/f'root-{i:02}.bin').read_bytes()
  if not a.startswith(b'P ') or not a.endswith(b' S\0') or b'$ER' in a or a!=b:raise ValueError('Entry/root validity differs: '+repr((i,a,b)))
  if reference and a!=(reference/f'include-{i:02}.bin').read_bytes():raise ValueError('Original quoted entry differs: '+repr((i,CASES[i],a,(reference/f'include-{i:02}.bin').read_bytes())))
 for i,v in {0:b'P $LK,"link",A="MN:MSG_CMD"$ S\0',1:b'P underlined S\0',27:b'P $CL$ S\0',29:b'P  S\0',30:b'P  S\0',31:b'P \n S\0',32:b'P \t S\0',33:b'P $ S\0',34:b'P '+CASES[34].encode()+b' S\0'}.items():
  if (out/f'include-{i:02}.bin').read_bytes()!=v:raise ValueError('Independent literal expectation differs: '+repr((i,(out/f'include-{i:02}.bin').read_bytes(),v)))
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original')
 paths=[Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.disk:
  r=json.loads((a.reference/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'] and r['cases']==CASES;verify(a.reference);paths += [a.disk.resolve(),a.reference/'result.json']+[a.reference/n for n in names()]
 drive='C' if a.disk else 'T';files={'/Probe/MatrixChild.HC':source('DMInclude'),'/Probe/MatrixRoot.HC':source('DMRoot')}
 files['/Probe/MatrixMain.HC']=f'#include "{drive}:/Probe/MatrixChild.HC"\n'.encode()
 code=f'#include "{drive}:/Probe/MatrixMain.HC"\n'+'''U0 DMLog(U8*s){while(*s)OutU8(0xE9,*s++);}
U0 DMExport(U8 *name,U8 *value){U8*s=MStrPrint("EXPORT %s %X %X\\n",name,value,StrLen(value)+1);DMLog(s);Free(s);}
'''
 code+=''.join(f'DMExport("include-{i:02}.bin",DMInclude{i});\n' for i in range(len(CASES)))
 code+=f'U0 DMCompileRoot(){{CDoc*d=DocRead("{drive}:/Probe/MatrixRoot.HC",DOCF_DBL_DOLLARS);ExeDoc(d,CCF_JUST_LOAD);DocDel(d);}}\nDMCompileRoot;\n'
 code+=''.join(f'DMExport("root-{i:02}.bin",DMRoot{i});\n' for i in range(len(CASES)))+'''U0 DMRawClear(){CDoc*d=DocNew("RawClear.HC");CDocEntry*e;
DocPrint(d,"U8 *DMRawValue(){return \\\"P ");
e=DocEntryNewBase(d,DOCT_CLEAR);DocInsEntry(d,e);
DocPrint(d," S\\\";}\\n");ExeDoc(d,CCF_JUST_LOAD);DocDel(d);}
DMRawClear;
DMExport("root-clear.bin",DMRawValue);
DMLog("DM DONE\\n");
'''
 files['/Probe/MatrixRun.HC']=code.encode();out.mkdir();pins={str(p):sha(p) for p in paths};(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',cases=CASES,input_sha256=pins,scope='35 original-calibrated quoted entry cases through nested includes and ExeDoc roots, plus a constructed root CLEAR entry without source-recalc deletion; exact paired bytes including NUL, independent link/text/marker/cursor/newline/tab/dollar expectations. Not every command/flag/bin/snapshot/cancellation/OOM/resource or full C1-C5 qualification.')
 for n,v in files.items():p=out/('files'+n);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(v)
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions=files);before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   for n,v in files.items():p=overlay/n.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(v)
   (overlay/'Once.HC').write_text('#include "T:/Probe/MatrixRun.HC"\n');image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:g.wait('DONE native kernel startup\n');g.type('#include "C:/Probe/MatrixRun.HC"');g.press('ret')
  g.wait('DM DONE\n',300)
  for n in names():(out/n).write_bytes((g.out/n).read_bytes())
  verify(out,a.reference if a.disk else None)
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report.update(result='pass',entry_results=len(names()))
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
