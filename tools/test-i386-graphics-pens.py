#!/usr/bin/env python3
"""Verify all original pen tables survive the task that first requests them."""
import argparse,hashlib,json,runpy,subprocess,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def expected():
 lo=[[0]*64 for _ in range(64)];hi=[[0]*64 for _ in range(64)];rows=[]
 for i in range(64):
  stride=(i+7)&~7;k=i+1
  for y in range(1,k):
   for x in range(1,k):
    if (y*2-k)**2+(x*2-k)**2<k*k:
     row=i-y;value=x-1-(i>>1);lo[i][row]=min(lo[i][row],value);hi[i][row]=max(hi[i][row],value)
  for kind in range(4):
   data=bytearray(stride*i)
   for y in range(i):
    for x in range(i):
     inside=((y+1)*2-k)**2+((x+1)*2-k)**2<k*k
     if inside and (kind<2 or ((x^y)&1)==(kind-2)):data[y*stride+x]=16 if kind==1 else 255
   rows.append(struct.pack('<7q',i,kind,i,stride,i,1,1)+data)
 return bytes(v&255 for row in lo for v in row)+bytes(v&255 for row in hi for v in row)+b''.join(rows)

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original')
 fixture=ROOT/'tests/guest/i386-graphics-pens/Contract.HC';inputs=[fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['test-i386-autocomplete-interaction.py','test-i386-timeclock-reference.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py']]+[ROOT/'Kernel/FontStd.HC']
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
 names=['graphics-pens.bin']
 if a.disk:
  r=json.loads((a.reference/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'] and r['input_sha256'][str(fixture)]==sha(fixture)
  inputs += [a.disk.resolve(),a.reference/'result.json']+[a.reference/n for n in names]
 out.mkdir();pins={str(p):sha(p) for p in inputs};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,scope='Child first uses public GrFillCircle, is killed, then every byte of all256 cached pens and8192 circle bounds plus dimensions/live non-child ownership is checked against an independent integer model and original; not failed-init/all-resource/C1-C5 qualification.')
 try:
  code=fixture.read_bytes()+b'\nGPProbe;\n'
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/GraphicsPens.HC':code});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay);(overlay/'Probe').mkdir();(overlay/'Probe/GraphicsPens.HC').write_bytes(code);(overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\nU0 DMHostLog(U8*s){while(*s)OutU8(0xE9,*s++); }\ntry{ExeFile("T:/Probe/GraphicsPens.HC");}catch{DMHostLog("FAIL pointer probe\\n");Fs->catch_except=TRUE;}\n');image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n');g.command('#include "/Kernel/I386/PublicUser.HH"');g.command('#include "C:/Probe/GraphicsPens.HC"')
  g.wait('GRAPHICS PENS DONE\n')
  marker='PEN CACHE BEFORE '+('0' if a.disk else '1')+'\n'
  if marker not in g.collect():raise ValueError('Unexpected preexisting pen cache state')
  report['initially_cached']=not bool(a.disk)
  for name,size in zip(names,(391680,)):
   data=(g.out/name).read_bytes();assert len(data)==size;(out/name).write_bytes(data)
   if data!=expected():raise ValueError('Pen tables differ from independent model')
   if a.disk and data!=(a.reference/name).read_bytes():raise ValueError('Pen output differs: '+name)
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:
   assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report.update(result='pass',cases=256,pixels=369152,bound_bytes=8192)
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
