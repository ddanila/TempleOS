#!/usr/bin/env python3
"""Compare complete public Dir output and current-directory behavior with original."""
import argparse,hashlib,json,runpy,struct,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TREE={'/DirOutputProbe/ONE.TXT':b'one\n'}
NAMES=['dir-default.bin','dir-full.bin','dir-empty.bin','dir-mask.bin','dir-returns.bin','dir-restore.bin']+[f'dir-{n}-meta.bin' for n in ('default','full','empty','mask')]
def listing(meta,full=False):
 if not meta.endswith(b'\0'):raise ValueError('Unterminated directory metadata')
 rows=[]
 for line in meta[:-1].splitlines():
  parts=line.split(b'\t');assert len(parts)==11
  name,path=parts[:2];size,cluster,attr=[int(x,16) for x in parts[2:5]];year,mon,day,hour,minute,second=map(int,parts[5:]);rows.append((name,path,size,cluster,attr,year,mon,day,hour,minute,second))
 if not rows:return b'No matching entries\n\0'
 sw=max(65535,*(r[2] for r in rows)).bit_length();sw=(sw+3)//4
 cw=max(65535,*(r[3] for r in rows)).bit_length();cw=(cw+3)//4
 directory=rows[0][1].rsplit(b'/',1)[0]
 text=b'$MA,T="Directory",LM="PopUpCd;Dir;\n"$ of '+directory+b'\n'
 text+=(f'__DATE__ __TIME__ {"SIZE":>{sw}} {"BLK":>{cw}}\n' if full else f'DATE_ TIME_ {"SIZE":>{sw}}\n').encode()
 for name,path,size,cluster,attr,year,mon,day,hour,minute,second in rows:
  if full:text+=f'{mon:02d}/{day:02d}/{year%100:02d} {hour:02d}:{minute:02d}:{second:02d} {size:0{sw}X} {cluster:0{cw}X} '.encode()
  else:text+=f'{mon:02d}/{day:02d} {hour:02d}:{minute:02d} {size:0{sw}X} '.encode()
  if attr&16:text+=b'$MA,T="'+name+b'",LM="Cd('+bytes([92,34])+path+bytes([92,34])+b');Dir;\n"$\n'
  else:text+=b'$LK,"'+name+b'",A="FI:'+path+b'"$\n'
 return text+b'\0'
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-dir-output/Contract.HC';inputs=[fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['test-i386-autocomplete-interaction.py','test-i386-timeclock-reference.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py']]+[ROOT/'Kernel/FontStd.HC']
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
 if a.disk:
  if not a.reference:ap.error('Native requires passing original')
  r=json.loads((a.reference/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'] and r['input_sha256'][str(fixture)]==sha(fixture)
  inputs += [a.disk.resolve(),a.reference/'result.json']+[a.reference/n for n in NAMES]
 out.mkdir();pins={str(p):sha(p) for p in inputs};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,scope='Public Dir default cwd, short/full/file-mask/empty-mask output on a seeded read-only directory, complete stdout strings/chars and counts against an original-calibrated metadata model, empty output also exact across systems; drive path/dates/clusters bind to the live filesystem metadata, restored cwd/put-document/timezone; not complete file UI/resource or C1-C5 qualification')
 try:
  code=fixture.read_bytes()+b'\ntry{DOProbe;}catch{DOLog("\\nFAIL Dir output\\n");Fs->catch_except=TRUE;}\n'
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/DirOutput.HC':code,**TREE});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay);(overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+code);
   for name,data in TREE.items():
    p=overlay/name.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
   image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
  class BoundedGuest(Guest):
   def call(self,name,**args):
    if name=='pmemsave' and args['size']>16384:raise ValueError('Oversized directory export')
    return super().call(name,**args)
  g=BoundedGuest(image,out/'guest',bool(a.disk))
  if a.disk:g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/DirOutput.HC"')
  g.wait('DIR OUTPUT DONE\n')
  for n in NAMES:(out/n).write_bytes((g.out/n).read_bytes())
  values=struct.unpack('<4q',(out/'dir-returns.bin').read_bytes());report['counts']=values
  if (out/'dir-restore.bin').read_bytes()!=struct.pack('<3q',1,1,1):raise ValueError('Directory caller/fixture restoration failed')
  counts=tuple(len((out/f'dir-{n}-meta.bin').read_bytes().rstrip(b'\0').splitlines()) for n in ('default','full','empty','mask'))
  if values!=counts or values[2:]!=(0,1):raise ValueError('Directory result counts differ')
  for name in ('default','full','empty','mask'):
   actual=(out/f'dir-{name}.bin').read_bytes();want=listing((out/f'dir-{name}-meta.bin').read_bytes(),name=='full')
   (out/f'dir-{name}-expected.bin').write_bytes(want)
   if actual!=want:raise ValueError('Complete original model differs: '+name)
  if a.disk:
   if (out/'dir-returns.bin').read_bytes()!=(a.reference/'dir-returns.bin').read_bytes():raise ValueError('Original directory counts differ')
   if (out/'dir-empty.bin').read_bytes()!=(a.reference/'dir-empty.bin').read_bytes():raise ValueError('Original empty byte comparison differs')
   g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
